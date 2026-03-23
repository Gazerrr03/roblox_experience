local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService('RunService')
local Workspace = game:GetService('Workspace')

local Packages = ReplicatedStorage:WaitForChild('Packages')
local Shared = require(Packages:WaitForChild('Shared'))

local SessionConfig = Shared.Config.SessionConfig
local Remotes = Shared.Network.Remotes.ensureScope(Shared.Network.Remotes.Scope.Run)
local CampMazeSessionContract = Shared.Session.CampMazeSessionContract
local MazeEntryAvailability = Shared.Session.MazeEntryAvailability
local ControlStateService = Shared.Runtime.ControlStateService
local FormalLocomotion = Shared.Runtime.FormalLocomotion
local PlayerStateService = Shared.Runtime.PlayerStateService

local LocalDebugMazeWorldBuilder = require(script.Parent.LocalDebugMazeWorldBuilder)
local RunMazePortal = require(script.Parent.RunMazePortal)
local RunWorldBuilder = require(script.Parent.RunWorldBuilder)

local RunSessionService = {}
RunSessionService.__index = RunSessionService

local DEFAULT_WORKSPACE_SHELL_NAMES = { 'Baseplate', 'SpawnLocation' }
local CAMP_SESSION_LOCK_WAIT_SECONDS = 0.05
local MAZE_ENTRY_REQUEST_COOLDOWN_SECONDS = 0.35
local MAZE_ENTRY_DISTANCE_BUFFER = 2
local LOCAL_DEBUG_ROOM_DETECTION_RADIUS = 56
local LOCAL_DEBUG_MAZE_RETURN_REASON = 'local_debug_return'
local SNAPSHOT_INTERVAL_SECONDS = 0.25
local RUN_MAZE_GATE_RETURN_REASONS = table.freeze({
    early_return = true,
    extracted = true,
})

local function resolvePendingSpawnCFrame(self, pendingSpawnValue)
    if typeof(pendingSpawnValue) == 'CFrame' then
        return pendingSpawnValue
    end

    if self.World and self.World.ReturnCFrame then
        return self.World.ReturnCFrame
    end

    return RunWorldBuilder.ReturnCFrame
end

local function bindCharacterTeleport(self, player)
    player.CharacterAdded:Connect(function(character)
        task.wait()
        if not character.Parent then
            return
        end

        if self.PendingLocalMazeSpawnByUserId[player.UserId] and self.LocalDebugMazeWorld then
            self.PendingLocalMazeSpawnByUserId[player.UserId] = nil
            character:PivotTo(self.LocalDebugMazeWorld.SpawnCFrame)
            self:_applyMovementMode(player)
            return
        end

        if not self.World then
            return
        end

        local pendingSpawnValue = self.PendingSpawnByUserId[player.UserId]
        local targetCFrame = pendingSpawnValue
                and resolvePendingSpawnCFrame(self, pendingSpawnValue)
            or self.World.SpawnCFrame
        self.PendingSpawnByUserId[player.UserId] = nil
        character:PivotTo(targetCFrame)
        self:_applyMovementMode(player)
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
    self.Status = 'Select Enter Camp to enter the camp.'
    self.IsLaunched = false
    self.ShouldAutoLaunch = false
    self.GateOpen = false
    self.World = nil
    self.SnapshotThread = nil
    self.PendingSpawnByUserId = {}
    self.PendingLocalMazeSpawnByUserId = {}
    self.CampSessionLock = false
    self.LastMazeEntryRequestAtByUserId = {}
    self.MazeEntryMode = MazeEntryAvailability.Mode.Blocked
    self.MazeEntryReason =
        'Set SessionConfig.PlaceIds.Maze or SessionPlaceIdMaze before using the maze gate.'
    self.MazeEntryReasonCode = MazeEntryAvailability.ReasonCode.MazePlaceIdMissing
    self.LocalDebugMazeWorld = nil
    self.ControlStateService = ControlStateService.new()
    self.PlayerStateService = PlayerStateService.new()

    return self
end

function RunSessionService:_addPlayerState(player)
    self.ControlStateService:addPlayer(player)
    self.PlayerStateService:addPlayer(player)
end

function RunSessionService:_removePlayerState(player)
    self.ControlStateService:removePlayer(player)
    self.PlayerStateService:removePlayer(player)
end

function RunSessionService:_getMovementSummaryFor(player)
    local playerState = self.PlayerStateService:getSummary(player)
    local controlState = self.ControlStateService:getSummary(player)
    return FormalLocomotion.summarize(playerState, controlState)
end

function RunSessionService:_applyMovementMode(player)
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass('Humanoid')
    if not humanoid then
        return
    end

    FormalLocomotion.applyToHumanoid(humanoid, self:_getMovementSummaryFor(player))
end

function RunSessionService:_syncPlayerMovement(player)
    local playerState = self.PlayerStateService:getSummary(player)
    local ok, controlState = self.ControlStateService:syncPlayerState(player, playerState)
    if ok and controlState then
        self.PlayerStateService:setSprinting(
            player,
            controlState.Mode == FormalLocomotion.Mode.Sprint
        )
    end

    self:_applyMovementMode(player)
end

function RunSessionService:_readTeleportData(player)
    local joinData = player:GetJoinData()
    return joinData and joinData.TeleportData
end

function RunSessionService:_applySessionConfig(incoming)
    if type(incoming) ~= 'table' then
        return
    end

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

function RunSessionService:_syncCampSession()
    self.CampSession = CampMazeSessionContract.normalizeCampSession(self.CampSession)
    self.CampSession.GateOpen = self.GateOpen
end

function RunSessionService:_applyIncomingCampSession(teleportData)
    if type(teleportData) ~= 'table' then
        return nil, false
    end

    local incomingSession = teleportData.CampSession
    if type(incomingSession) ~= 'table' then
        return nil, false
    end

    local nextSession, accepted =
        CampMazeSessionContract.reconcileIncomingCampSession(self.CampSession, incomingSession)
    if not accepted then
        return nil, false
    end

    self.CampSession = nextSession
    self.GateOpen = self.CampSession.GateOpen
    self.ShouldAutoLaunch = true

    return teleportData, true
end

function RunSessionService:_loadSessionDataFromJoin()
    local players = Players:GetPlayers()
    if #players == 0 then
        return
    end

    local acceptedTeleportData = nil
    for _, player in ipairs(players) do
        local teleportData = self:_readTeleportData(player)
        local _, accepted = self:_applyIncomingCampSession(teleportData)
        if accepted then
            self:_applySessionConfig(teleportData.SessionConfig)
            acceptedTeleportData = teleportData
            break
        end
    end

    if not acceptedTeleportData then
        return
    end

    local returnedPlayers = {}
    for _, player in ipairs(players) do
        local teleportData = self:_readTeleportData(player) or acceptedTeleportData
        local returnSummary = CampMazeSessionContract.findReturnSummary(teleportData, player.UserId)
        if returnSummary then
            self.PendingSpawnByUserId[player.UserId] = true
            table.insert(returnedPlayers, {
                Player = player,
                Summary = returnSummary,
            })
        end
    end

    if #returnedPlayers == 1 then
        local returnedPlayer = returnedPlayers[1]
        self.Status = string.format(
            '%s returned from the maze with %d value (%s).',
            returnedPlayer.Player.DisplayName,
            returnedPlayer.Summary.Value or 0,
            returnedPlayer.Summary.ReturnReason or 'unknown'
        )
    elseif #returnedPlayers > 1 then
        self.Status = 'The crew returned from the maze. Review the camp summaries together.'
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
            local pendingSpawnValue = self.PendingSpawnByUserId[player.UserId]
            local targetCFrame = pendingSpawnValue
                    and resolvePendingSpawnCFrame(self, pendingSpawnValue)
                or self.World.SpawnCFrame
            self.PendingSpawnByUserId[player.UserId] = nil
            character:PivotTo(targetCFrame)
            self:_applyMovementMode(player)
        end
    end
end

function RunSessionService:_getReturnSpawnCFrameForSummary(summary)
    if self.World and RUN_MAZE_GATE_RETURN_REASONS[summary.ReturnReason] then
        return self.World.MazeReturnCFrame
    end

    if RUN_MAZE_GATE_RETURN_REASONS[summary.ReturnReason] then
        return RunWorldBuilder.MazeReturnCFrame
    end

    if self.World then
        return self.World.ReturnCFrame
    end

    return RunWorldBuilder.ReturnCFrame
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
        if self:_canProcessMazeEntryRequest(player) then
            self:_requestMazeEntry(player, false)
        end
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

    if self.LocalDebugMazeWorld then
        local room, distance = self.LocalDebugMazeWorld.FindRoomByPosition(rootPart.Position)
        if room and distance <= LOCAL_DEBUG_ROOM_DETECTION_RADIUS then
            return 'Local Maze Debug'
        end

        for _, entry in ipairs(self.CampSession.PlayersInMaze or {}) do
            if entry.UserId == player.UserId then
                return 'Local Maze Debug'
            end
        end
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

    if area == 'Local Maze Debug' then
        return 'Explore local debug maze rooms, then use Return To Camp (Local Debug).'
    end

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

function RunSessionService:_resolveMazeEntryAvailability()
    local availability = MazeEntryAvailability.evaluate({
        PlaceIds = SessionConfig.PlaceIds,
        PlaceId = game.PlaceId,
        GameId = game.GameId,
        IsStudio = RunService:IsStudio(),
        DebugLocalMazeHandoff = SessionConfig.DebugLocalMazeHandoff,
    })

    self.MazeEntryMode = availability.Mode
    self.MazeEntryReason = availability.Reason
    self.MazeEntryReasonCode = availability.ReasonCode

    return availability
end

function RunSessionService:_broadcastSnapshot()
    local roster = self:_buildRoster()
    local activeMazeRoster = cloneArray(self.CampSession.PlayersInMaze)
    local returnedSummaries = cloneArray(self.CampSession.ReturnedPlayerSummaries)
    local mazeEntryAvailability = self:_resolveMazeEntryAvailability()

    for _, player in ipairs(Players:GetPlayers()) do
        self.Remotes.RunState:FireClient(player, {
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
            MazeEntryMode = mazeEntryAvailability.Mode,
            MazeEntryReason = mazeEntryAvailability.Reason,
            MazeEntryReasonCode = mazeEntryAvailability.ReasonCode,
            Movement = self:_getMovementSummaryFor(player),
            ControlState = self.ControlStateService:getSummary(player),
            PlayerState = self.PlayerStateService:getSummary(player),
        })

        self.Remotes.RunPrivateState:FireClient(player, nil)
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

function RunSessionService:_bindLocalDebugMazeInteractions()
    if not self.LocalDebugMazeWorld then
        return
    end

    self.LocalDebugMazeWorld.ReturnPrompt.Triggered:Connect(function(player)
        local previousSession = CampMazeSessionContract.normalizeCampSession(self.CampSession)
        local summary = CampMazeSessionContract.buildReturnSummary({
            UserId = player.UserId,
            Name = player.DisplayName,
            ReturnReason = LOCAL_DEBUG_MAZE_RETURN_REASON,
            Value = 0,
            ItemCount = 0,
            Weight = 0,
            WasExtracted = false,
            WasSettled = false,
        })

        self.CampSession = CampMazeSessionContract.applyReturn(previousSession, summary, false)
        self.CampSession.GateOpen = self.GateOpen

        local character = player.Character
        if character and character.Parent and self.World then
            character:PivotTo(self.World.ReturnCFrame)
        else
            self.PendingSpawnByUserId[player.UserId] = true
            player:LoadCharacter()
        end

        self:_setStatus(
            string.format(
                '%s returned from local maze debug mode back to camp.',
                player.DisplayName
            )
        )
    end)
end

function RunSessionService:_ensureLocalDebugMazeWorld()
    if self.LocalDebugMazeWorld then
        return
    end

    self.LocalDebugMazeWorld =
        LocalDebugMazeWorldBuilder.build(self.SessionData.Seed, SessionConfig.ProcGen)
    self:_bindLocalDebugMazeInteractions()
end

function RunSessionService:_enterLocalDebugMaze(player)
    self:_ensureLocalDebugMazeWorld()

    local previousSession = CampMazeSessionContract.normalizeCampSession(self.CampSession)
    local nextSession = CampMazeSessionContract.markPlayerEntered(previousSession, {
        UserId = player.UserId,
        Name = player.DisplayName,
    })
    nextSession.GateOpen = self.GateOpen
    self.CampSession = nextSession

    local character = player.Character
    if character and character.Parent then
        character:PivotTo(self.LocalDebugMazeWorld.SpawnCFrame)
        self.PendingLocalMazeSpawnByUserId[player.UserId] = nil
    else
        self.PendingLocalMazeSpawnByUserId[player.UserId] = true
        player:LoadCharacter()
    end

    self.MazeEntryMode = MazeEntryAvailability.Mode.LocalDebugFallback
    self.MazeEntryReasonCode = MazeEntryAvailability.ReasonCode.LocalDebugFallbackEnabled
    self.MazeEntryReason =
        'Studio local debug fallback is active. You were moved to an in-place maze sandbox.'
    self:_setStatus(
        string.format(
            '%s entered local maze debug mode (no cross-place teleport).',
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

        local result = RunMazePortal.enter({
            Player = player,
            CampSession = self.CampSession,
            GateOpen = self.GateOpen,
            SessionConfig = self.SessionData,
            EnteringPlayer = {
                UserId = player.UserId,
                Name = player.DisplayName,
            },
            EntryReason = 'maze_gate',
        })
        if not result.Ok then
            self.CampSession = result.CurrentSession or self.CampSession
            self.MazeEntryMode = MazeEntryAvailability.Mode.Blocked
            self.MazeEntryReasonCode = result.ReasonCode or result.FailureCode
            self.MazeEntryReason = result.Reason
            self:_setStatus(
                string.format('%s could not enter the maze: %s', player.DisplayName, result.Reason)
            )
            return
        end

        self.MazeEntryMode = MazeEntryAvailability.Mode.Teleport
        self.MazeEntryReasonCode = result.ReasonCode
        self.MazeEntryReason = result.Reason
        self.CampSession = result.NextSession
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

    local availability = self:_resolveMazeEntryAvailability()
    if availability.Mode == MazeEntryAvailability.Mode.Teleport then
        self:_enterMaze(player)
        return
    end

    if availability.Mode == MazeEntryAvailability.Mode.LocalDebugFallback then
        self:_enterLocalDebugMaze(player)
        return
    end

    self:_setStatus(
        string.format(
            '%s could not enter the maze: %s (code=%s, gameId=%d, placeId=%d, mazePlaceId=%d)',
            player.DisplayName,
            availability.Reason,
            availability.ReasonCode or 'Unknown',
            game.GameId,
            game.PlaceId,
            SessionConfig.PlaceIds.Maze
        )
    )
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
    if self.Status == 'Select Enter Camp to enter the camp.' then
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
        local previousTick = os.clock()

        while true do
            task.wait(SNAPSHOT_INTERVAL_SECONDS)

            if self.IsLaunched then
                local currentTick = os.clock()
                self.PlayerStateService:step(currentTick - previousTick)
                previousTick = currentTick

                for _, player in ipairs(Players:GetPlayers()) do
                    self:_syncPlayerMovement(player)
                end

                self:_broadcastSnapshot()
            else
                previousTick = os.clock()
            end
        end
    end)
end

function RunSessionService:_setPlayerSprinting(player, isSprinting)
    if not self.IsLaunched then
        return
    end

    local playerState = self.PlayerStateService:getSummary(player)
    local success, result
    if isSprinting then
        success, result = self.ControlStateService:requestSprintStart(player, playerState)
    else
        success, result = self.ControlStateService:requestSprintStop(player)
    end

    if not success then
        if result == 'StaminaDepleted' then
            self:_setStatus(string.format('%s is too exhausted to sprint.', player.DisplayName))
        elseif result == 'Dead' then
            self:_setStatus(string.format('%s cannot sprint while dead.', player.DisplayName))
        end
        self:_syncPlayerMovement(player)
        return
    end

    self:_syncPlayerMovement(player)
end

function RunSessionService:_handlePlayerTeleportData(player)
    local teleportData = self:_readTeleportData(player)
    if not teleportData then
        return
    end

    local _, accepted = self:_applyIncomingCampSession(teleportData)
    if not accepted then
        return
    end

    self:_applySessionConfig(teleportData.SessionConfig)

    local summary = CampMazeSessionContract.findReturnSummary(teleportData, player.UserId)
    if summary then
        self.PendingSpawnByUserId[player.UserId] = self:_getReturnSpawnCFrameForSummary(summary)
        if RUN_MAZE_GATE_RETURN_REASONS[summary.ReturnReason] then
            self.Status = string.format(
                '%s returned to the maze gate with %d value (%s).',
                player.DisplayName,
                summary.Value or 0,
                summary.ReturnReason or 'unknown'
            )
        elseif teleportData.MazeReturn and teleportData.MazeReturn.MazeCompleted == true then
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
        return
    end

    self.CampSession = CampMazeSessionContract.prunePlayer(self.CampSession, player.UserId, {
        PreserveMazeEntry = CampMazeSessionContract.isPlayerInMaze(self.CampSession, player.UserId),
    })
    self.GateOpen = self.CampSession.GateOpen
    self.Status = string.format('%s joined the camp session.', player.DisplayName)
end

function RunSessionService:start()
    self:_loadSessionDataFromJoin()
    Players.CharacterAutoLoads = false

    for _, player in ipairs(Players:GetPlayers()) do
        bindCharacterTeleport(self, player)
        self:_addPlayerState(player)

        if player.Character then
            player.Character:Destroy()
        end
    end

    Players.PlayerAdded:Connect(function(player)
        bindCharacterTeleport(self, player)
        self:_addPlayerState(player)
        self:_handlePlayerTeleportData(player)

        if self.IsLaunched then
            player:LoadCharacter()
        end

        self:_broadcastSnapshot()
    end)

    Players.PlayerRemoving:Connect(function(player)
        self.LastMazeEntryRequestAtByUserId[player.UserId] = nil
        self.PendingSpawnByUserId[player.UserId] = nil
        self.PendingLocalMazeSpawnByUserId[player.UserId] = nil
        self.CampSession = CampMazeSessionContract.prunePlayer(self.CampSession, player.UserId, {
            PreserveMazeEntry = CampMazeSessionContract.isPlayerInMaze(
                self.CampSession,
                player.UserId
            ),
        })
        self.GateOpen = self.CampSession.GateOpen
        self:_removePlayerState(player)
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
        elseif payload.Type == 'RequestSprintStart' then
            self:_setPlayerSprinting(player, true)
        elseif payload.Type == 'RequestSprintStop' then
            self:_setPlayerSprinting(player, false)
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
