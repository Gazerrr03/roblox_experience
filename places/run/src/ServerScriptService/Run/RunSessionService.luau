local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Workspace = game:GetService('Workspace')

local Packages = ReplicatedStorage:WaitForChild('Packages')
local Shared = require(Packages:WaitForChild('Shared'))

local SessionConfig = Shared.Config.SessionConfig
local Remotes = Shared.Network.Remotes.ensure()

local RunWorldBuilder = require(script.Parent.RunWorldBuilder)

local RunSessionService = {}
RunSessionService.__index = RunSessionService

local function bindCharacterTeleport(self, player)
    player.CharacterAdded:Connect(function(character)
        task.wait()
        if self.World and character.Parent then
            character:PivotTo(self.World.SpawnCFrame)
        end
    end)
end

local function clearDefaultWorkspaceShell()
    for _, instanceName in ipairs({ 'Baseplate', 'SpawnLocation' }) do
        local instance = Workspace:FindFirstChild(instanceName)
        if instance then
            instance:Destroy()
        end
    end
end

function RunSessionService.new()
    local self = setmetatable({}, RunSessionService)

    self.Remotes = Remotes
    self.SessionData = {
        Seed = SessionConfig.DefaultSeed,
    }
    self.Status = 'Select Single Player to enter the camp.'
    self.IsLaunched = false
    self.GateOpen = false
    self.World = nil
    self.SnapshotThread = nil

    return self
end

function RunSessionService:_loadSessionDataFromJoin()
    local players = Players:GetPlayers()
    if #players == 0 then
        return
    end

    local joinData = players[1]:GetJoinData()
    local teleportData = joinData and joinData.TeleportData
    local incoming = teleportData and teleportData.SessionConfig

    if type(incoming) == 'table' and type(incoming.Seed) == 'number' then
        self.SessionData.Seed = incoming.Seed
    end
end

function RunSessionService:_teleportCharactersToSpawn()
    if not self.World then
        return
    end

    for _, player in ipairs(Players:GetPlayers()) do
        local character = player.Character
        if character and character.Parent then
            character:PivotTo(self.World.SpawnCFrame)
        end
    end
end

function RunSessionService:_rebuildWorld()
    clearDefaultWorkspaceShell()
    self.World = RunWorldBuilder.build()
    self:_bindWorldInteractions()
    self:_teleportCharactersToSpawn()
end

function RunSessionService:_bindWorldInteractions()
    if not self.World then
        return
    end

    self.World.ShopPrompt.Triggered:Connect(function(player)
        self:_setStatus(
            string.format(
                '%s checked the shop terminal. Purchases coming soon.',
                player.DisplayName
            )
        )
    end)

    self.World.LoadoutPrompt.Triggered:Connect(function(player)
        self:_setStatus(
            string.format(
                '%s checked the loadout bench. Equipment setup is coming soon.',
                player.DisplayName
            )
        )
    end)

    self.World.GatePrompt.Triggered:Connect(function(player)
        self:_openGate(player)
    end)

    self.World.MazePrompt.Triggered:Connect(function(player)
        self:_setStatus(
            string.format(
                '%s reached the maze gate. The dedicated maze run is not wired yet.',
                player.DisplayName
            )
        )
    end)
end

function RunSessionService:_getPlayerArea(player)
    if not self.IsLaunched or not self.World then
        return 'Title Screen'
    end

    local character = player.Character
    local rootPart = character and character:FindFirstChild('HumanoidRootPart')
    if not rootPart then
        return self.GateOpen and 'Camp Threshold' or 'Camp House'
    end

    if rootPart.Position.Z >= self.World.OutdoorThresholdZ then
        return 'Wilderness'
    end

    return 'Camp House'
end

function RunSessionService:_buildRoster()
    local roster = {}

    for _, player in ipairs(Players:GetPlayers()) do
        table.insert(roster, {
            Name = player.DisplayName,
            UserId = player.UserId,
        })
    end

    table.sort(roster, function(left, right)
        return left.Name < right.Name
    end)

    return roster
end

function RunSessionService:_getObjectiveFor(player)
    local area = self:_getPlayerArea(player)

    if not self.GateOpen then
        return 'Inspect the camp terminals and open the gate when the group is ready.'
    end

    if area == 'Wilderness' then
        return 'Explore the clearing and inspect the maze gate outside.'
    end

    return 'Step outside to the wilderness clearing and inspect the maze gate.'
end

function RunSessionService:_setStatus(status)
    self.Status = status
    self:_broadcastSnapshot()
end

function RunSessionService:_broadcastSnapshot()
    local roster = self:_buildRoster()

    for _, player in ipairs(Players:GetPlayers()) do
        self.Remotes.RunSnapshot:FireClient(player, {
            IsLaunched = self.IsLaunched,
            Status = self.Status,
            Area = self:_getPlayerArea(player),
            GateOpen = self.GateOpen,
            Objective = self:_getObjectiveFor(player),
            Roster = roster,
        })

        self.Remotes.PrivateState:FireClient(player, nil)
    end
end

function RunSessionService:_openGate(player)
    if not self.World then
        return
    end

    if not self.GateOpen then
        self.GateOpen = true
        self.World.OpenGate()
        self:_setStatus(
            string.format(
                '%s opened the camp gate. The wilderness trail is now accessible.',
                player.DisplayName
            )
        )
        return
    end

    self:_setStatus(
        string.format(
            '%s checked the camp gate. The wilderness trail is already open.',
            player.DisplayName
        )
    )
end

function RunSessionService:_launchRun(_player)
    if self.IsLaunched then
        return
    end

    self.IsLaunched = true
    self.GateOpen = false
    Players.CharacterAutoLoads = true

    self:_rebuildWorld()

    for _, player in ipairs(Players:GetPlayers()) do
        player:LoadCharacter()
    end

    self:_startSnapshotLoop()
    self:_setStatus('Camp is ready. Gather inside, then open the gate when you want to head out.')
end

function RunSessionService:_startSnapshotLoop()
    if self.SnapshotThread then
        return
    end

    self.SnapshotThread = task.spawn(function()
        while true do
            task.wait(1)

            if self.IsLaunched then
                self:_broadcastSnapshot()
            end
        end
    end)
end

function RunSessionService:start()
    self:_loadSessionDataFromJoin()
    Players.CharacterAutoLoads = false

    for _, player in ipairs(Players:GetPlayers()) do
        bindCharacterTeleport(self, player)

        if player.Character then
            player.Character:Destroy()
        end
    end

    Players.PlayerAdded:Connect(function(player)
        bindCharacterTeleport(self, player)

        if self.IsLaunched then
            player:LoadCharacter()
        end

        self:_broadcastSnapshot()
    end)

    Players.PlayerRemoving:Connect(function()
        self:_broadcastSnapshot()
    end)

    self.Remotes.RunAction.OnServerEvent:Connect(function(player, payload)
        if type(payload) ~= 'table' then
            return
        end

        if payload.Type == 'RequestLaunchRun' then
            self:_launchRun(player)
        elseif payload.Type == 'RequestStartExpedition' then
            self:_setStatus(
                string.format(
                    '%s checked the old deploy action. Use the camp gate to head outside instead.',
                    player.DisplayName
                )
            )
        end
    end)

    self:_broadcastSnapshot()
end

return RunSessionService
