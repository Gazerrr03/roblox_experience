local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local TeleportService = game:GetService('TeleportService')
local Workspace = game:GetService('Workspace')

local Packages = ReplicatedStorage:WaitForChild('Packages')
local Shared = require(Packages:WaitForChild('Shared'))

local SessionConfig = Shared.Config.SessionConfig
local Remotes = Shared.Network.Remotes.ensure()
local CampMazeSessionContract = Shared.Session.CampMazeSessionContract

local RunWorldBuilder = require(script.Parent.RunWorldBuilder)

local RunSessionService = {}
RunSessionService.__index = RunSessionService

local DEFAULT_WORKSPACE_SHELL_NAMES = { 'Baseplate', 'SpawnLocation' }
local CAMP_SESSION_LOCK_WAIT_SECONDS = 0.05
local MAZE_ENTRY_REQUEST_COOLDOWN_SECONDS = 0.35
local MAZE_ENTRY_DISTANCE_BUFFER = 2

local function bindCharacterTeleport(self, player)
    player.CharacterAdded:Connect(function(character)
        task.wait()
        if not self.World or not character.Parent then
            return
        end

        local targetCFrame = self.PendingSpawnByUserId[player.UserId] and self.World.ReturnCFrame
            or self.World.SpawnCFrame
        self.PendingSpawnByUserId[player.UserId] = nil
        character:PivotTo(targetCFrame)
    end)
end

local function clearDefaultWorkspaceShell()
    for _, instanceName in ipairs(DEFAULT_WORKSPACE_SHELL_NAMES) do
        local instance = Workspace:FindFirstChild(instanceName)
        if instance then
            instance:Destroy()
        end
    end
end

local function cloneArray(input)
    local result = {}

    for index, entry in ipairs(input or {}) do
        result[index] = table.clone(entry)
    end

    return result
end

local function runWithCampSessionLock(self, callback)
    while self.CampSessionLock do
        task.wait(CAMP_SESSION_LOCK_WAIT_SECONDS)
    end

    self.CampSessionLock = true
    local results = table.pack(pcall(callback))
    self.CampSessionLock = false

    if not results[1] then
        error(results[2], 0)
    end

    return table.unpack(results, 2, results.n)
end

function RunSessionService.new()
    local self = setmetatable({}, RunSessionService)

    self.Remotes = Remotes
    self.SessionData = {
        Seed = SessionConfig.DefaultSeed,
        Quota = SessionConfig.DefaultQuota,
        RunDurationSeconds = SessionConfig.DefaultRunDurationSeconds,
        InventoryCapacity = SessionConfig.InventoryCapacity,
    }
    self.CampSession = CampMazeSessionContract.newCampSession({})
    self.Status = 'Select Single Player to enter the camp.'
    self.IsLaunched = false
    self.ShouldAutoLaunch = false
    self.GateOpen = false
    self.World = nil
    self.SnapshotThread = nil
    self.PendingSpawnByUserId = {}
    self.CampSessionLock = false
    self.LastMazeEntryRequestAtByUserId = {}

    return self
end

function RunSessionService:_readTeleportData(player)
    local joinData = player:GetJoinData()
    return joinData and joinData.TeleportData
end

function RunSessionService:_syncCampSession()
    self.CampSession = CampMazeSessionContract.normalizeCampSession(self.CampSession)
    self.CampSession.GateOpen = self.GateOpen
end

function RunSessionService:_applyIncomingCampSession(teleportData)
    if type(teleportData) ~= 'table' then
        return nil
    end

    local incomingSession = teleportData.CampSession
    if type(incomingSession) ~= 'table' then
        return nil
    end

    self.CampSession = CampMazeSessionContract.normalizeCampSession(incomingSession)
    self.GateOpen = self.CampSession.GateOpen
    self.ShouldAutoLaunch = true

    return teleportData
end

function RunSessionService:_loadSessionDataFromJoin()
    local players = Players:GetPlayers()
    if #players == 0 then
        return
    end

    local teleportData = self:_readTeleportData(players[1])
    local incoming = teleportData and teleportData.SessionConfig

    if type(incoming) == 'table' then
        if type(incoming.Seed) == 'number' then
            self.SessionData.Seed = incoming.Seed
        end
        if type(incoming.Quota) == 'number' then
            self.SessionData.Quota = incoming.Quota
        end
        if type(incoming.RunDurationSeconds) == 'number' then
            self.SessionData.RunDurationSeconds = incoming.RunDurationSeconds
        end
        if type(incoming.InventoryCapacity) == 'number' then
            self.SessionData.InventoryCapacity = incoming.InventoryCapacity
        end
    end

    teleportData = self:_applyIncomingCampSession(teleportData)
    if not teleportData then
        return
    end

    local returnSummary = CampMazeSessionContract.findReturnSummary(teleportData, players[1].UserId)
    if returnSummary then
        self.PendingSpawnByUserId[players[1].UserId] = true
        self.Status = string.format(
            '%s returned from the maze with %d value (%s).',
            players[1].DisplayName,
            returnSummary.Value or 0,
            returnSummary.ReturnReason or 'unknown'
        )
    else
        self.Status = 'Camp is ready. Gather inside, then head outside when the group is ready.'
    end
end

function RunSessionService:_teleportCharactersToSpawn()
    if not self.World then
        return
    end

    for _, player in ipairs(Players:GetPlayers()) do
        local character = player.Character
        if character and character.Parent then
            local targetCFrame = self.PendingSpawnByUserId[player.UserId]
                    and self.World.ReturnCFrame
                or self.World.SpawnCFrame
            self.PendingSpawnByUserId[player.UserId] = nil
            character:PivotTo(targetCFrame)
        end
    end
end

function RunSessionService:_rebuildWorld()
    clearDefaultWorkspaceShell()
    self.World = RunWorldBuilder.build()
    if self.GateOpen then
        self.World.OpenGate()
    end
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
        self:_requestMazeEntry(player, false)
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

    if self.CampSession.MazeStatus == CampMazeSessionContract.MazeStatus.Completed then
        return 'The maze run is complete. Review the returned crew summaries in camp.'
    end

    if self.CampSession.MazeStatus == CampMazeSessionContract.MazeStatus.Active then
        if area == 'Wilderness' then
            return 'A maze session is active. Use the gate outside to join the shared expedition.'
        end

        return 'Head outside and use the maze gate to join the active shared expedition.'
    end

    if area == 'Wilderness' then
        return 'Inspect the maze gate outside to open the first maze session.'
    end

    return 'Step outside to the wilderness clearing and inspect the maze gate.'
end

function RunSessionService:_setStatus(status)
    self.Status = status
    self:_broadcastSnapshot()
end

function RunSessionService:_broadcastSnapshot()
    local roster = self:_buildRoster()
    local activeMazeRoster = cloneArray(self.CampSession.PlayersInMaze)
    local returnedSummaries = cloneArray(self.CampSession.ReturnedPlayerSummaries)

    for _, player in ipairs(Players:GetPlayers()) do
        self.Remotes.RunSnapshot:FireClient(player, {
            IsLaunched = self.IsLaunched,
            Status = self.Status,
            Area = self:_getPlayerArea(player),
            GateOpen = self.GateOpen,
            Objective = self:_getObjectiveFor(player),
            Roster = roster,
            SessionId = self.CampSession.SessionId,
            MazeStatus = self.CampSession.MazeStatus,
            PlayersInMaze = activeMazeRoster,
            ReturnedPlayerSummaries = returnedSummaries,
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
        self:_syncCampSession()
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

function RunSessionService:_enterMaze(player)
    runWithCampSessionLock(self, function()
        if SessionConfig.PlaceIds.Maze == 0 then
            self:_setStatus(
                'Set SessionConfig.PlaceIds.Maze or SessionPlaceIdMaze before using the maze gate.'
            )
            return
        end

        if self.CampSession.MazeStatus == CampMazeSessionContract.MazeStatus.Completed then
            self:_setStatus('The maze session is already complete for this camp.')
            return
        end

        -- Teleports yield, so keep the camp session mutation serialized per server.
        local previousSession = CampMazeSessionContract.normalizeCampSession(self.CampSession)
        local mazeAccessCode = previousSession.MazeAccessCode
            or TeleportService:ReserveServer(SessionConfig.PlaceIds.Maze)

        previousSession.MazeAccessCode = mazeAccessCode
        previousSession.GateOpen = self.GateOpen

        local nextSession = CampMazeSessionContract.markPlayerEntered(previousSession, {
            UserId = player.UserId,
            Name = player.DisplayName,
        })
        nextSession.MazeAccessCode = mazeAccessCode
        nextSession.GateOpen = self.GateOpen

        local teleportData = CampMazeSessionContract.buildCampToMazeTeleportData({
            SessionConfig = self.SessionData,
            CampSession = nextSession,
            EnteringPlayer = {
                UserId = player.UserId,
                Name = player.DisplayName,
            },
            EntryReason = 'maze_gate',
        })

        local success, message = pcall(function()
            TeleportService:TeleportToPrivateServer(
                SessionConfig.PlaceIds.Maze,
                mazeAccessCode,
                { player },
                nil,
                teleportData
            )
        end)

        if not success then
            self.CampSession = previousSession
            self:_setStatus(string.format('Maze gate failed: %s', tostring(message)))
            return
        end

        self.CampSession = nextSession
        self:_setStatus(string.format('%s is entering the shared maze run.', player.DisplayName))
    end)
end

function RunSessionService:_isPlayerNearMazePrompt(player)
    if not self.World or not self.World.MazePrompt then
        return false
    end

    local promptPart = self.World.MazePrompt.Parent
    if not promptPart or not promptPart:IsA('BasePart') then
        return false
    end

    local character = player.Character
    local rootPart = character and character:FindFirstChild('HumanoidRootPart')
    if not rootPart or not rootPart:IsA('BasePart') then
        return false
    end

    local maxDistance = self.World.MazePrompt.MaxActivationDistance + MAZE_ENTRY_DISTANCE_BUFFER
    return (rootPart.Position - promptPart.Position).Magnitude <= maxDistance
end

function RunSessionService:_requestMazeEntry(player, requireDistanceCheck)
    if not self.IsLaunched or not self.World then
        return
    end

    if not self.GateOpen then
        self:_setStatus(
            string.format(
                '%s checked the maze gate, but the camp gate is still closed.',
                player.DisplayName
            )
        )
        return
    end

    if requireDistanceCheck and not self:_isPlayerNearMazePrompt(player) then
        return
    end

    self:_enterMaze(player)
end

function RunSessionService:_canProcessMazeEntryRequest(player)
    local now = os.clock()
    local previous = self.LastMazeEntryRequestAtByUserId[player.UserId]
    if previous and now - previous < MAZE_ENTRY_REQUEST_COOLDOWN_SECONDS then
        return false
    end

    self.LastMazeEntryRequestAtByUserId[player.UserId] = now
    return true
end

function RunSessionService:_launchRun(_player)
    if self.IsLaunched then
        return
    end

    self.IsLaunched = true
    Players.CharacterAutoLoads = true
    self.GateOpen = self.CampSession.GateOpen == true
    self:_syncCampSession()

    self:_rebuildWorld()

    for _, player in ipairs(Players:GetPlayers()) do
        player:LoadCharacter()
    end

    self:_startSnapshotLoop()
    if self.Status == 'Select Single Player to enter the camp.' then
        self:_setStatus(
            'Camp is ready. Gather inside, then open the gate when you want to head out.'
        )
    else
        self:_broadcastSnapshot()
    end
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

function RunSessionService:_handlePlayerTeleportData(player)
    local teleportData = self:_readTeleportData(player)
    if not teleportData then
        return
    end

    local incomingSession = teleportData.CampSession
    if type(incomingSession) == 'table' then
        self.CampSession = CampMazeSessionContract.normalizeCampSession(incomingSession)
        self.GateOpen = self.CampSession.GateOpen
        self.PendingSpawnByUserId[player.UserId] = self.World and self.World.ReturnCFrame or true

        local summary = CampMazeSessionContract.findReturnSummary(teleportData, player.UserId)
        if summary then
            if teleportData.MazeReturn and teleportData.MazeReturn.MazeCompleted == true then
                self.Status = string.format(
                    '%s returned from the completed maze run with %d value.',
                    player.DisplayName,
                    summary.Value or 0
                )
            else
                self.Status = string.format(
                    '%s returned from the maze with %d value (%s).',
                    player.DisplayName,
                    summary.Value or 0,
                    summary.ReturnReason or 'unknown'
                )
            end
        else
            self.Status = string.format('%s joined the camp session.', player.DisplayName)
        end
    end
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
        self:_handlePlayerTeleportData(player)

        if self.IsLaunched then
            player:LoadCharacter()
        end

        self:_broadcastSnapshot()
    end)

    Players.PlayerRemoving:Connect(function(player)
        self.LastMazeEntryRequestAtByUserId[player.UserId] = nil
        self:_broadcastSnapshot()
    end)

    self.Remotes.RunAction.OnServerEvent:Connect(function(player, payload)
        if type(payload) ~= 'table' then
            return
        end

        if payload.Type == 'RequestLaunchRun' then
            self:_launchRun(player)
        elseif payload.Type == 'RequestEnterMaze' then
            if self:_canProcessMazeEntryRequest(player) then
                self:_requestMazeEntry(player, true)
            end
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

    if self.ShouldAutoLaunch then
        self:_launchRun(nil)
    end
end

return RunSessionService
