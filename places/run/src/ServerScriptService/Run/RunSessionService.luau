local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Packages = ReplicatedStorage:WaitForChild('Packages')
local Shared = require(Packages:WaitForChild('Shared'))
local Gameplay = require(Packages:WaitForChild('Gameplay'))

local SessionConfig = Shared.Config.SessionConfig
local RunState = Shared.Enums.RunState
local Remotes = Shared.Network.Remotes.ensure()

local Items = Gameplay.Config.Items
local Monsters = Gameplay.Config.Monsters
local Roles = Gameplay.Config.Roles
local MazeBuilder = Gameplay.ProcGen.MazeBuilder
local SessionStateMachine = Gameplay.Session.SessionStateMachine

local InventoryService = require(script.Parent.InventoryService)
local RoleService = require(script.Parent.RoleService)
local MonsterService = require(script.Parent.MonsterService)
local RunWorldBuilder = require(script.Parent.RunWorldBuilder)

local RunSessionService = {}
RunSessionService.__index = RunSessionService

function RunSessionService.new()
    local self = setmetatable({}, RunSessionService)

    self.Remotes = Remotes
    self.StateMachine = SessionStateMachine.new(RunState.Lobby)
    self.InventoryService = InventoryService.new(SessionConfig.InventoryCapacity)
    self.RoleService = RoleService.new(Roles)
    self.MonsterService = MonsterService.new(Monsters[1], function()
        return self.StateMachine.Current == RunState.Expedition
            or self.StateMachine.Current == RunState.Extraction
    end)
    self.SessionData = {
        Seed = SessionConfig.DefaultSeed,
        Quota = SessionConfig.DefaultQuota,
        RunDurationSeconds = SessionConfig.DefaultRunDurationSeconds,
        InventoryCapacity = SessionConfig.InventoryCapacity,
    }
    self.Status = 'Select Single Player to enter the run.'
    self.TimeRemaining = self.SessionData.RunDurationSeconds
    self.TeamDepositedValue = 0
    self.IsLaunched = false
    self.World = nil
    self.TickThread = nil

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

    if type(incoming) == 'table' then
        self.SessionData.Seed = incoming.Seed or self.SessionData.Seed
        self.SessionData.Quota = incoming.Quota or self.SessionData.Quota
        self.SessionData.RunDurationSeconds = incoming.RunDurationSeconds
            or self.SessionData.RunDurationSeconds
        self.SessionData.InventoryCapacity = incoming.InventoryCapacity
            or self.SessionData.InventoryCapacity
        self.InventoryService.Capacity = self.SessionData.InventoryCapacity
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
    local layout = MazeBuilder.build(self.SessionData.Seed, SessionConfig.ProcGen)
    self.World = RunWorldBuilder.build(layout, Items, SessionConfig.ProcGen)
    self.MonsterService:spawn(self.World.PatrolPoints)
    self:_bindWorldInteractions()
    self:_teleportCharactersToSpawn()
end

function RunSessionService:_bindWorldInteractions()
    if not self.World then
        return
    end

    self.World.CampPrompt.Triggered:Connect(function(player)
        self:_beginExpedition(player)
    end)

    self.World.ExtractionPrompt.Triggered:Connect(function(player)
        self:_depositLoot(player)
    end)

    for _, itemEntry in ipairs(self.World.ItemEntries) do
        itemEntry.Prompt.Triggered:Connect(function(player)
            self:_pickupItem(player, itemEntry)
        end)
    end
end

function RunSessionService:_setStatus(status)
    self.Status = status
    self:_broadcastSnapshot()
end

function RunSessionService:_broadcastSnapshot()
    for _, player in ipairs(Players:GetPlayers()) do
        self.Remotes.RunSnapshot:FireClient(player, {
            IsLaunched = self.IsLaunched,
            State = self.StateMachine.Current,
            Status = self.Status,
            Seed = self.SessionData.Seed,
            Quota = self.SessionData.Quota,
            TeamDepositedValue = self.TeamDepositedValue,
            TimeRemaining = math.max(0, math.ceil(self.TimeRemaining)),
            Inventory = self.InventoryService:getSummary(player),
            Roster = self.RoleService:getVisibleRoster(player),
        })

        self.Remotes.PrivateState:FireClient(player, self.RoleService:getPrivateState(player))
    end
end

function RunSessionService:_assignRoles()
    self.RoleService:assign(Players:GetPlayers())
end

function RunSessionService:_launchRun(_player)
    if self.IsLaunched then
        return
    end

    self.IsLaunched = true

    if self.StateMachine.Current == RunState.Lobby then
        self.StateMachine:transition(RunState.Camp)
    end

    self.TeamDepositedValue = 0
    self.TimeRemaining = self.SessionData.RunDurationSeconds
    self.InventoryService:reset()
    self:_assignRoles()
    self:_rebuildWorld()
    self:_startTickLoop()
    self:_setStatus('Camp is live. Deploy when you are ready.')
end

function RunSessionService:_resetRunLoop()
    if self.StateMachine.Current ~= RunState.Camp then
        self.StateMachine:transition(RunState.Camp)
    end

    self.TeamDepositedValue = 0
    self.TimeRemaining = self.SessionData.RunDurationSeconds
    self.InventoryService:reset()
    self.SessionData.Seed += 1
    self:_assignRoles()
    self:_rebuildWorld()
    self:_setStatus('Camp is live. Deploy when the crew is ready.')
end

function RunSessionService:_settle(reason)
    if self.StateMachine.Current == RunState.Expedition then
        self.StateMachine:transition(RunState.Extraction)
    end

    if self.StateMachine:canTransition(RunState.Settlement) then
        self.StateMachine:transition(RunState.Settlement)
    end

    self:_setStatus(string.format('Settlement: %s', reason))

    task.delay(SessionConfig.SettlementDurationSeconds, function()
        if self.StateMachine.Current == RunState.Settlement then
            self:_resetRunLoop()
        end
    end)
end

function RunSessionService:_beginExpedition(player)
    if self.StateMachine.Current ~= RunState.Camp then
        return
    end

    self.StateMachine:transition(RunState.Expedition)
    self.TimeRemaining = self.SessionData.RunDurationSeconds
    self:_setStatus(string.format('%s deployed the crew.', player.DisplayName))
end

function RunSessionService:_pickupItem(player, itemEntry)
    if
        self.StateMachine.Current ~= RunState.Expedition
        and self.StateMachine.Current ~= RunState.Extraction
    then
        return
    end

    local success, payload = self.InventoryService:pickup(player, itemEntry.ItemDef)
    if not success then
        self:_setStatus(string.format('%s is at capacity.', player.DisplayName))
        return
    end

    if itemEntry.Part and itemEntry.Part.Parent then
        itemEntry.Part:Destroy()
    end

    self:_setStatus(string.format('%s picked up %s.', player.DisplayName, payload.Name))
end

function RunSessionService:_depositLoot(player)
    if
        self.StateMachine.Current ~= RunState.Expedition
        and self.StateMachine.Current ~= RunState.Extraction
    then
        return
    end

    if self.StateMachine.Current == RunState.Expedition then
        self.StateMachine:transition(RunState.Extraction)
    end

    local depositedValue = self.InventoryService:deposit(player)
    if depositedValue <= 0 then
        self:_setStatus(string.format('%s has no loot to deposit.', player.DisplayName))
        return
    end

    self.TeamDepositedValue += depositedValue
    self:_setStatus(
        string.format('%s deposited %d scrap value.', player.DisplayName, depositedValue)
    )

    if self.TeamDepositedValue >= self.SessionData.Quota then
        self:_settle('Quota secured')
    end
end

function RunSessionService:_startTickLoop()
    if self.TickThread then
        return
    end

    self.TickThread = task.spawn(function()
        while true do
            task.wait(1)

            if
                self.StateMachine.Current == RunState.Expedition
                or self.StateMachine.Current == RunState.Extraction
            then
                self.TimeRemaining -= 1
                if self.TimeRemaining <= 0 then
                    self.TimeRemaining = 0
                    self:_settle('Timer expired')
                else
                    self:_broadcastSnapshot()
                end
            end
        end
    end)
end

function RunSessionService:start()
    self:_loadSessionDataFromJoin()

    for _, player in ipairs(Players:GetPlayers()) do
        self.InventoryService:addPlayer(player)
        player.CharacterAdded:Connect(function(character)
            task.wait()
            if self.World and character.Parent then
                character:PivotTo(self.World.SpawnCFrame)
            end
        end)
    end

    Players.PlayerAdded:Connect(function(player)
        self.InventoryService:addPlayer(player)
        player.CharacterAdded:Connect(function(character)
            task.wait()
            if self.World and character.Parent then
                character:PivotTo(self.World.SpawnCFrame)
            end
        end)

        if self.IsLaunched then
            self:_assignRoles()
        end

        self:_broadcastSnapshot()
    end)

    Players.PlayerRemoving:Connect(function(player)
        self.InventoryService:removePlayer(player)
        self:_broadcastSnapshot()
    end)

    self.Remotes.RunAction.OnServerEvent:Connect(function(player, payload)
        if type(payload) ~= 'table' then
            return
        end

        if payload.Type == 'RequestLaunchRun' then
            self:_launchRun(player)
        elseif payload.Type == 'RequestStartExpedition' then
            self:_beginExpedition(player)
        end
    end)

    self:_broadcastSnapshot()
end

return RunSessionService
