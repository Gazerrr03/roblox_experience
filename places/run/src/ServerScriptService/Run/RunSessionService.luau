local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService('RunService')
local Workspace = game:GetService('Workspace')

local Packages = ReplicatedStorage:WaitForChild('Packages')
local Shared = require(Packages:WaitForChild('Shared'))
local Gameplay = require(Packages:WaitForChild('Gameplay'))

local SessionConfig = Shared.Config.SessionConfig
local Remotes = Shared.Network.Remotes.ensure()
local CampMazeSessionContract = Shared.Session.CampMazeSessionContract
local MazeEntryAvailability = Shared.Session.MazeEntryAvailability
local SessionSeedPolicy = Shared.Session.SessionSeedPolicy
local ControlStateService = Shared.Runtime.ControlStateService
local FormalLocomotion = Shared.Runtime.FormalLocomotion
local InventoryService = Shared.Runtime.InventoryService
local MonsterService = Shared.Runtime.MonsterService
local PlayerService = Shared.Runtime.PlayerService
local PlayerStateService = Shared.Runtime.PlayerStateService
local TODService = Shared.Runtime.TODService
local TeleportInventoryHydrator = Shared.Runtime.TeleportInventoryHydrator
local RoundSignalBus = Shared.Runtime.RoundSignalBus

local RunSpawnPoint = require(script.Parent.RunSpawnPoint)
local RunWorldScanner = require(script.Parent.RunWorldScanner)
local RunMonsterSpawnPolicy = require(script.Parent.RunMonsterSpawnPolicy)
local RunSnapshotBuilder = require(script.Parent.RunSnapshotBuilder)
local RunStaticWorldContract = require(script.Parent.RunStaticWorldContract)
local RunToMazeTransition = require(script.Parent.RunToMazeTransition)
local RunWorldBuilder = require(script.Parent.RunWorldBuilder)
local RunInventoryBridge = require(script.Parent.RunInventoryBridge)

local RunSessionService = {}
RunSessionService.__index = RunSessionService

local DEFAULT_WORKSPACE_SHELL_NAMES = { 'Baseplate', 'SpawnLocation' }
local CAMP_SESSION_LOCK_WAIT_SECONDS = 0.05
local MAZE_ENTRY_REQUEST_COOLDOWN_SECONDS = 0.35
local MAZE_ENTRY_DISTANCE_BUFFER = 2
local TERMINAL_INTERACTION_DISTANCE_BUFFER = 2
local SNAPSHOT_INTERVAL_SECONDS = 0.25
local LEGACY_TOOL_CATEGORY = table.freeze({
    Flashlight = 'Flashlight',
    Rope = 'Rope',
    Crowbar = 'Crowbar',
})
local RUN_MAZE_GATE_RETURN_REASONS = table.freeze({
    early_return = true,
    extracted = true,
})
local INITIAL_TEMPLE_STATUS =
    'Leave the ship, spot the tower, and decide when to push into the maze.'
local OCEAN_SPLASH_MESSAGE = 'Sea spray crashes over you.'
local OCEAN_SLOWDOWN_DELAY_SECONDS = 1
local OCEAN_SLOWDOWN_WALK_SPEED = 12
local OCEAN_DAMAGE_INTERVAL_SECONDS = 5
local ROUND_RESET_DELAY_SECONDS = SessionConfig.SettlementDurationSeconds
local ROUND_SETTLEMENT_REASON = table.freeze({
    Book = 'ship_settlement',
    Timeout = 'timeout',
    AllDead = 'all_dead',
})
local DAMAGE_KIND_BY_PIPS = table.freeze({
    [1] = Gameplay.PlayerState.DamageKind.Light,
    [2] = Gameplay.PlayerState.DamageKind.Heavy,
})
local SHOP_ITEMS = {
    {
        Id = 'temple_lantern',
        Name = 'Temple Lantern',
        Price = 18,
        Weight = 2,
        Value = 12,
        Light = {
            Brightness = 2,
            Range = 12,
            Color = Color3.fromRGB(255, 214, 153),
        },
    },
    {
        Id = 'sand_relic',
        Name = 'Sand Relic',
        Price = 24,
        Weight = 3,
        Value = 18,
        Color = Color3.fromRGB(224, 202, 152),
    },
    {
        Id = 'scribe_compass',
        Name = 'Scribe Compass',
        Price = 14,
        Weight = 1,
        Value = 9,
    },
}
local SHOP_ITEM_BY_ID = {}

for _, item in ipairs(SHOP_ITEMS) do
    SHOP_ITEM_BY_ID[item.Id] = item
end

table.freeze(SHOP_ITEMS)
table.freeze(SHOP_ITEM_BY_ID)

local function resolvePendingSpawnCFrame(self, pendingSpawnValue)
    if typeof(pendingSpawnValue) == 'CFrame' then
        return pendingSpawnValue
    end

    if type(pendingSpawnValue) == 'string' and self.World then
        return self.World:getSpawnCFrame(pendingSpawnValue)
    end

    error(string.format('Unknown run pending spawn target %q.', tostring(pendingSpawnValue)), 0)
end

local function bindCharacterTeleport(self, player)
    player.CharacterAdded:Connect(function(character)
        task.defer(function()
            local rootPart = character:FindFirstChild('HumanoidRootPart')
                or character:WaitForChild('HumanoidRootPart', 5)
            if rootPart == nil then
                return
            end

            if not character.Parent then
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
            rootPart.AssemblyLinearVelocity = Vector3.zero
            rootPart.AssemblyAngularVelocity = Vector3.zero
            self:_applyMovementMode(player)
        end)
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

function RunSessionService.new(options)
    local runtimeOptions = options or {}
    local self = setmetatable({}, RunSessionService)

    self.Remotes = Remotes
    self.BuildFingerprint = RunStaticWorldContract.BuildFingerprint
    self.SessionData = {
        Seed = SessionConfig.DefaultSeed,
        Quota = SessionConfig.DefaultQuota,
        RunDurationSeconds = SessionConfig.DefaultRunDurationSeconds,
        InventoryCapacity = SessionConfig.InventoryCapacity,
        Mission = {
            RoundCount = SessionConfig.Mission.RoundCount,
            TargetItemCount = SessionConfig.Mission.TargetItemCount,
        },
    }
    self.CampSession = CampMazeSessionContract.newCampSession({
        CurrentRound = 1,
        MaxRounds = SessionConfig.Mission.RoundCount,
        TargetItemCount = SessionConfig.Mission.TargetItemCount,
        SignalScope = string.format(
            'run:%s',
            if type(game.JobId) == 'string' and game.JobId ~= ''
                then game.JobId
                else tostring(os.time())
        ),
    })
    self.Status = INITIAL_TEMPLE_STATUS
    self.IsLaunched = false
    self.ShouldAutoLaunch = false
    self.GateOpen = false
    self.World = nil
    self.WorldInteractions = nil
    self.SnapshotThread = nil
    self.PendingSpawnByUserId = {}
    self.CampSessionLock = false
    self.HasAuthoritativeSessionSeed = false
    self.SessionSeedRandom = nil
    self.LastMazeEntryRequestAtByUserId = {}
    self.LastOceanSplashAtByUserId = {}
    self.OceanStateByUserId = {}
    self.OceanTimersByUserId = {}
    self.OceanOriginalSpeedsByUserId = {}
    self.MazeEntryMode = MazeEntryAvailability.Mode.Blocked
    self.MazeEntryReason =
        'Set SessionConfig.PlaceIds.Maze or SessionPlaceIdMaze before using the maze gate.'
    self.MazeEntryReasonCode = MazeEntryAvailability.ReasonCode.MazePlaceIdMissing
    self.CollectedRunClueMarkerIds = {}
    self.InventoryService = InventoryService.new(self.SessionData.InventoryCapacity)
    self.ControlStateService = ControlStateService.new()
    self.PlayerService = PlayerService.new()
    self.PlayerStateService = PlayerStateService.new()
    self.RunToMazeTransition = runtimeOptions.RunToMazeTransition or RunToMazeTransition.new()
    self.WorldBuilder = runtimeOptions.RunWorldBuilder or RunWorldBuilder
    self.TODService = runtimeOptions.TODService
        or TODService.new({
            Config = SessionConfig.TOD,
            Remote = self.Remotes.TODState,
        })
    self.RunTracker = Gameplay.Session.MazeRunTracker.new()
    self.MonsterService = nil -- deferred: initialized in _rebuildWorld after self.World is built
    self.RoundSignalBus = runtimeOptions.RoundSignalBus or RoundSignalBus.new()
    self.RoundSignalConnection = nil
    self.RoundClosureInProgress = false
    self.RoundResetToken = 0
    self.MazePresence = {
        AliveCount = 0,
        ActiveCount = 0,
    }

    return self
end

function RunSessionService:_getServerTimeNow()
    local ok, result = pcall(function()
        return Workspace:GetServerTimeNow()
    end)
    if ok and type(result) == 'number' then
        return result
    end

    return os.time()
end

function RunSessionService:_ensureHost()
    local players = Players:GetPlayers()
    local currentHostUserId = self.CampSession.HostUserId

    for _, player in ipairs(players) do
        if player.UserId == currentHostUserId then
            return
        end
    end

    table.sort(players, function(left, right)
        return left.UserId < right.UserId
    end)

    local nextHost = players[1]
    self.CampSession =
        CampMazeSessionContract.assignHost(self.CampSession, nextHost and nextHost.UserId or nil)
end

function RunSessionService:_isRoundStarted()
    return self.CampSession.RoundStarted == true
end

function RunSessionService:_isRoundClosing()
    return self.RoundClosureInProgress == true or self.CampSession.SettlementReason ~= nil
end

function RunSessionService:_isPlayerDead(player)
    local summary = self.PlayerService:getSummary(player)
    return summary ~= nil and summary.Health ~= nil and summary.Health.IsDead == true
end

function RunSessionService:_isPlayerInCamp(player)
    return self:_getPlayerArea(player) ~= 'Wilderness'
end

function RunSessionService:_isPlayerTargetableInField(player)
    return self:_isRoundStarted()
        and self.CampSession.DangerActive == true
        and not CampMazeSessionContract.isPlayerInMaze(self.CampSession, player.UserId)
        and not self:_isPlayerDead(player)
        and not self:_isPlayerInCamp(player)
end

function RunSessionService:_getRoundTimeRemainingSeconds()
    local roundEndTime = self.CampSession.RoundEndTime
    if type(roundEndTime) ~= 'number' then
        return nil
    end

    return math.max(0, roundEndTime - self:_getServerTimeNow())
end

function RunSessionService:_evaluateMazeEntry(player)
    local availability = MazeEntryAvailability.evaluate({
        PlaceIds = SessionConfig.PlaceIds,
        PlaceId = game.PlaceId,
        GameId = game.GameId,
        IsStudio = RunService:IsStudio(),
    })

    if not self:_isRoundStarted() then
        availability.Mode = MazeEntryAvailability.Mode.Blocked
        availability.ReasonCode = 'RoundNotStarted'
        availability.Reason =
            'The round has not started yet. Wait for the host to open the ship door.'
    elseif self:_isRoundClosing() then
        availability.Mode = MazeEntryAvailability.Mode.Blocked
        availability.ReasonCode = 'RoundClosing'
        availability.Reason = 'This round is already closing.'
    elseif self:_isPlayerDead(player) then
        availability.Mode = MazeEntryAvailability.Mode.Blocked
        availability.ReasonCode = 'PlayerDead'
        availability.Reason = 'Dead players return next round and cannot enter the maze.'
    elseif CampMazeSessionContract.isPlayerInMaze(self.CampSession, player.UserId) then
        availability.Mode = MazeEntryAvailability.Mode.Blocked
        availability.ReasonCode = 'AlreadyInMaze'
        availability.Reason = 'This player is already inside the maze.'
    end

    self.MazeEntryMode = availability.Mode
    self.MazeEntryReason = availability.Reason
    self.MazeEntryReasonCode = availability.ReasonCode

    return availability
end

function RunSessionService:_getRunAliveCount()
    local count = 0

    for _, player in ipairs(Players:GetPlayers()) do
        if
            not CampMazeSessionContract.isPlayerInMaze(self.CampSession, player.UserId)
            and not self:_isPlayerDead(player)
        then
            count += 1
        end
    end

    return count
end

function RunSessionService:_handleRoundSignal(payload)
    if type(payload) ~= 'table' then
        return
    end

    if payload.Kind == RoundSignalBus.MessageKind.MazePresence then
        self.MazePresence = {
            AliveCount = type(payload.AliveCount) == 'number' and payload.AliveCount or 0,
            ActiveCount = type(payload.ActiveCount) == 'number' and payload.ActiveCount or 0,
        }
        self:_maybeEndRoundForAllDeaths()
    end
end

function RunSessionService:_subscribeToRoundSignals()
    if self.RoundSignalConnection and self.RoundSignalConnection.Disconnect then
        self.RoundSignalConnection:Disconnect()
        self.RoundSignalConnection = nil
    end

    local connection, ok = self.RoundSignalBus:subscribe(self.CampSession, function(payload)
        self:_handleRoundSignal(payload)
    end)
    if ok then
        self.RoundSignalConnection = connection
    end
end

function RunSessionService:_publishRoundClosure(reason, player, countInventories)
    self.RoundSignalBus:publish(self.CampSession, {
        Kind = RoundSignalBus.MessageKind.RoundClosure,
        Reason = reason,
        TriggeredByUserId = player and player.UserId or nil,
        TriggeredByName = player and player.DisplayName or nil,
        CountInventories = countInventories ~= false,
        IssuedAt = self:_getServerTimeNow(),
    })
end

function RunSessionService:_resetRoundPlayerState(player)
    self.ControlStateService:removePlayer(player)
    self.ControlStateService:addPlayer(player)
    self.PlayerStateService:removePlayer(player)
    self.PlayerStateService:addPlayer(player)
    self.PlayerService:removePlayer(player)
    self.PlayerService:addPlayer(player)
    self.LastOceanSplashAtByUserId[player.UserId] = nil
    self.OceanStateByUserId[player.UserId] = nil
    self.OceanTimersByUserId[player.UserId] = nil
    self.OceanOriginalSpeedsByUserId[player.UserId] = nil
    self.PendingSpawnByUserId[player.UserId] = RunSpawnPoint.Kind.Spawn
end

function RunSessionService:_refreshSessionOutcomeForCurrentState()
    if self.CampSession.SessionOutcome ~= nil then
        return
    end

    if self.CampSession.CurrentRound < self.CampSession.MaxRounds then
        return
    end

    if #self.CampSession.PlayersInMaze > 0 or (self.MazePresence.ActiveCount or 0) > 0 then
        return
    end

    local outcome = if self.CampSession.BankedItemCount >= self.CampSession.TargetItemCount
        then 'success'
        else 'failure'
    self.CampSession = CampMazeSessionContract.markSessionOutcome(self.CampSession, outcome)
end

function RunSessionService:_resetForNextRound()
    if
        self.CampSession.SessionOutcome == 'success'
        or self.CampSession.SessionOutcome == 'failure'
    then
        self.RoundClosureInProgress = false
        self.GateOpen = false
        self.Status = if self.CampSession.SessionOutcome == 'success'
            then 'Mission complete. The crew is back at the ship for the final debrief.'
            else 'Mission failed. The crew is back at the ship for the final debrief.'
        self:_broadcastSnapshot()
        return
    end

    self.RoundClosureInProgress = false
    self.GateOpen = false
    self.MazePresence = {
        AliveCount = 0,
        ActiveCount = 0,
    }
    self.CampSession = CampMazeSessionContract.resetForNextRound(self.CampSession)
    self:_ensureHost()

    if self.MonsterService and self.MonsterService.destroy then
        self.MonsterService:destroy()
        self.MonsterService = nil
    end

    self:_rebuildWorld()

    for _, player in ipairs(Players:GetPlayers()) do
        self:_resetRoundPlayerState(player)
        if self.IsLaunched then
            player:LoadCharacter()
        end
    end

    self.Status = string.format(
        'Round %d of %d ready. Regroup at the ship, review clues, then head for the tower again.',
        self.CampSession.CurrentRound,
        self.CampSession.MaxRounds
    )
    self:_broadcastSnapshot()
end

function RunSessionService:_completeRound(reason, player, countInventories)
    if not self:_isRoundStarted() or self.RoundClosureInProgress then
        return
    end

    self.RoundClosureInProgress = true
    self.GateOpen = false
    self.CampSession = CampMazeSessionContract.markSettlementTriggered(self.CampSession, {
        SettlementReason = reason,
        TriggeredByUserId = player and player.UserId or nil,
        TriggeredByName = player and player.DisplayName or nil,
        RoundOutcome = reason,
    })
    self.CampSession.GateOpen = false
    self.CampSession.RoundStarted = false
    self.CampSession.RoundEndTime = self:_getServerTimeNow()
    self:_refreshSessionOutcomeForCurrentState()
    self.CampSession = CampMazeSessionContract.normalizeCampSession(self.CampSession)

    if reason == ROUND_SETTLEMENT_REASON.Book then
        self.Status = string.format(
            '%s called the crew back to the ship. This round is ending.',
            player.DisplayName
        )
    elseif reason == ROUND_SETTLEMENT_REASON.AllDead then
        self.Status =
            'Everyone went down. The round is ending and the ship is pulling the crew back.'
    else
        self.Status = 'Time is up. The round is ending and the ship is recalling the crew.'
    end

    self:_publishRoundClosure(reason, player, countInventories)
    self:_broadcastSnapshot()

    self.RoundResetToken += 1
    local resetToken = self.RoundResetToken
    task.delay(ROUND_RESET_DELAY_SECONDS, function()
        if self.RoundResetToken ~= resetToken then
            return
        end

        self:_resetForNextRound()
    end)
end

function RunSessionService:_maybeEndRoundForAllDeaths()
    if not self:_isRoundStarted() or self.RoundClosureInProgress then
        return
    end

    if self:_getRunAliveCount() == 0 and (self.MazePresence.AliveCount or 0) == 0 then
        self:_completeRound(ROUND_SETTLEMENT_REASON.AllDead, nil, false)
    end
end

function RunSessionService:_addPlayerState(player)
    self.InventoryService:addPlayer(player)
    self.ControlStateService:addPlayer(player)
    self.PlayerStateService:addPlayer(player)
    self.PlayerService:addPlayer(player)
end

function RunSessionService:_removePlayerState(player)
    self.InventoryService:removePlayer(player)
    self.ControlStateService:removePlayer(player)
    self.PlayerStateService:removePlayer(player)
    self.PlayerService:removePlayer(player)
end

function RunSessionService:_handleOceanEntered(player)
    if self.CampSession.DangerActive ~= true then
        return
    end

    local now = os.clock()
    local lastSplashAt = self.LastOceanSplashAtByUserId[player.UserId]
    if
        lastSplashAt ~= nil
        and now - lastSplashAt < RunStaticWorldContract.OceanSplashCooldownSeconds
    then
        return
    end

    self.LastOceanSplashAtByUserId[player.UserId] = now
    self.Remotes.RunPrivateState:FireClient(player, {
        Type = 'OceanSplash',
        Message = OCEAN_SPLASH_MESSAGE,
    })
end

function RunSessionService:_applyOceanSlowdown(player)
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass('Humanoid')
    if not humanoid then
        return
    end

    local originalWalkSpeed = humanoid.WalkSpeed
    local originalSprintSpeed = humanoid.WalkSpeed -- sprint speed mirrors walk speed in this system

    self.OceanOriginalSpeedsByUserId[player.UserId] = {
        WalkSpeed = originalWalkSpeed,
        SprintSpeed = originalSprintSpeed,
    }
    humanoid.WalkSpeed = OCEAN_SLOWDOWN_WALK_SPEED
end

function RunSessionService:_removeOceanSlowdown(player)
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass('Humanoid')
    if not humanoid then
        return
    end

    local original = self.OceanOriginalSpeedsByUserId[player.UserId]
    if original then
        humanoid.WalkSpeed = original.WalkSpeed
        self.OceanOriginalSpeedsByUserId[player.UserId] = nil
    end
end

function RunSessionService:_getOceanState(player)
    return self.OceanStateByUserId[player.UserId] or 'None'
end

function RunSessionService:_setOceanState(player, newState)
    local currentState = self:_getOceanState(player)
    if currentState == newState then
        return
    end

    self.OceanStateByUserId[player.UserId] = newState

    if newState == 'Touching' and currentState == 'None' then
        -- Schedule Immersed transition
        self.OceanTimersByUserId[player.UserId] = {
            TouchStartedAt = os.clock(),
            LastDamageAt = nil,
        }
        -- Apply slowdown after delay
        task.delay(OCEAN_SLOWDOWN_DELAY_SECONDS, function()
            if self:_getOceanState(player) == 'Touching' then
                self:_applyOceanSlowdown(player)
            end
        end)
    elseif newState == 'Immersed' then
        -- Player is fully immersed, start damage timer
        self.OceanTimersByUserId[player.UserId].ImmersedStartedAt = os.clock()
    elseif newState == 'None' then
        -- Player left the ocean
        self:_removeOceanSlowdown(player)
        self.OceanTimersByUserId[player.UserId] = nil
        self.Remotes.RunPrivateState:FireClient(player, {
            Type = 'OceanExit',
        })
    end
end

function RunSessionService:_checkOceanImmersion(player)
    if not self.World or not self.World.OceanTriggers then
        return false
    end

    local character = player.Character
    local rootPart = character and character:FindFirstChild('HumanoidRootPart')
    if not rootPart then
        return false
    end

    local position = rootPart.Position

    for _, trigger in ipairs(self.World.OceanTriggers) do
        local part = trigger.Part
        local size = part.Size
        local cf = part.CFrame

        -- Check if root part center is within the trigger part's bounding box
        local localPos = cf:PointToObjectSpace(position)
        local halfSize = size * 0.5

        if
            math.abs(localPos.X) <= halfSize.X
            and math.abs(localPos.Y) <= halfSize.Y
            and math.abs(localPos.Z) <= halfSize.Z
        then
            return true
        end
    end

    return false
end

function RunSessionService:_updateOceanPerPlayer(player, _dt)
    local state = self:_getOceanState(player)

    if self.CampSession.DangerActive ~= true then
        if state ~= 'None' then
            self:_setOceanState(player, 'None')
        end
        return
    end

    if state == 'None' then
        return
    end

    local isImmersed = self:_checkOceanImmersion(player)

    if state == 'Touching' and isImmersed then
        self:_setOceanState(player, 'Immersed')
        return
    elseif state == 'Touching' and not isImmersed then
        -- Still just touching, check if they left entirely
        -- If the player is no longer near any ocean trigger, they left
        if not self:_checkOceanNear(player) then
            self:_setOceanState(player, 'None')
        end
        return
    elseif state == 'Immersed' then
        -- Check if still immersed
        if not isImmersed then
            self:_setOceanState(player, 'None')
            return
        end

        -- Apply periodic damage
        local timers = self.OceanTimersByUserId[player.UserId]
        if not timers then
            return
        end

        -- Skip damage if player is already dead
        local playerObj = self.PlayerService:get(player)
        if playerObj and playerObj.Components.Health.IsDead then
            return
        end

        local now = os.clock()
        local lastDamage = timers.LastDamageAt or timers.ImmersedStartedAt

        if lastDamage and now - lastDamage >= OCEAN_DAMAGE_INTERVAL_SECONDS then
            -- Apply 1 pip damage
            if playerObj and playerObj.Components.Health then
                playerObj.Components.Health:applyDamage(playerObj.Blackboard, 'Light')
            end
            timers.LastDamageAt = now

            -- Notify client of damage tick
            local currentPips = 0
            if playerObj and playerObj.Components.Health then
                currentPips = playerObj.Components.Health.CurrentHealthPips
            end
            self.Remotes.RunPrivateState:FireClient(player, {
                Type = 'OceanDamage',
                CurrentPips = currentPips,
            })
        end
    end
end

function RunSessionService:_checkOceanNear(player)
    if not self.World or not self.World.OceanTriggers then
        return false
    end

    local character = player.Character
    local rootPart = character and character:FindFirstChild('HumanoidRootPart')
    if not rootPart then
        return false
    end

    local position = rootPart.Position

    for _, trigger in ipairs(self.World.OceanTriggers) do
        local part = trigger.Part
        local size = part.Size
        local cf = part.CFrame

        -- Expand bounding box slightly to detect "touching" (within half-stud buffer)
        local localPos = cf:PointToObjectSpace(position)
        local halfSize = size * 0.5 + Vector3.new(0.5, 0.5, 0.5)

        if
            math.abs(localPos.X) <= halfSize.X
            and math.abs(localPos.Y) <= halfSize.Y
            and math.abs(localPos.Z) <= halfSize.Z
        then
            return true
        end
    end

    return false
end

function RunSessionService:_getMovementSummaryFor(player)
    local playerState = self.PlayerService:getSummary(player)
    local controlState = self.ControlStateService:getSummary(player)
    return FormalLocomotion.summarize(playerState, controlState)
end

function RunSessionService:_applyMovementMode(player)
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass('Humanoid')
    if not humanoid then
        return
    end

    -- If player is in ocean, force ocean slowdown WalkSpeed to override movement system
    local oceanState = self:_getOceanState(player)
    if oceanState == 'Touching' or oceanState == 'Immersed' then
        humanoid.WalkSpeed = OCEAN_SLOWDOWN_WALK_SPEED
        return
    end

    FormalLocomotion.applyToHumanoid(humanoid, self:_getMovementSummaryFor(player))
end

function RunSessionService:_syncPlayerMovement(player)
    local playerState = self.PlayerService:getSummary(player)
    local ok, controlState = self.ControlStateService:syncPlayerState(player, playerState)
    if ok and controlState then
        self.PlayerService:setSprinting(player, controlState.Mode == FormalLocomotion.Mode.Sprint)
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
        self.HasAuthoritativeSessionSeed = true
    end
    if type(incoming.Quota) == 'number' then
        self.SessionData.Quota = incoming.Quota
    end
    if type(incoming.RunDurationSeconds) == 'number' then
        self.SessionData.RunDurationSeconds = incoming.RunDurationSeconds
    end
    if type(incoming.InventoryCapacity) == 'number' then
        self.SessionData.InventoryCapacity = incoming.InventoryCapacity
        self.InventoryService.Capacity = incoming.InventoryCapacity
    end

    local mission = incoming.Mission
    if type(mission) == 'table' then
        if type(mission.RoundCount) == 'number' then
            self.SessionData.Mission.RoundCount = mission.RoundCount
            self.CampSession.MaxRounds = mission.RoundCount
        end
        if type(mission.TargetItemCount) == 'number' then
            self.SessionData.Mission.TargetItemCount = mission.TargetItemCount
            self.CampSession.TargetItemCount = mission.TargetItemCount
            self.SessionData.Quota = mission.TargetItemCount
        end
    end

    self.CampSession = CampMazeSessionContract.normalizeCampSession(self.CampSession)
end

function RunSessionService:_hydratePlayerInventory(player, teleportData)
    return TeleportInventoryHydrator.hydratePlayerInventory(
        self.InventoryService,
        player,
        teleportData,
        CampMazeSessionContract.findPlayerInventory
    )
end

function RunSessionService:_syncCampSession()
    self.CampSession.GateOpen = self.GateOpen
    self.CampSession = CampMazeSessionContract.normalizeCampSession(self.CampSession)
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
    self:_ensureHost()
    self:_subscribeToRoundSignals()

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

    self:_applyReturnedPlayersFromTeleportData(players, acceptedTeleportData)
end

function RunSessionService:_getReturnStatusText(playerDisplayName, summary, teleportData)
    local lootCount = summary.LootItemCount or summary.MissionCount or summary.ItemCount or 0

    if RUN_MAZE_GATE_RETURN_REASONS[summary.ReturnReason] then
        return string.format(
            '%s made it back from the maze with %d loot item(s) and banked them at the ship.',
            playerDisplayName,
            lootCount
        )
    end

    if teleportData.MazeReturn and teleportData.MazeReturn.MazeCompleted == true then
        return string.format(
            '%s returned from the maze. The crew now has %d of %d required loot item(s).',
            playerDisplayName,
            self.CampSession.BankedItemCount,
            self.CampSession.TargetItemCount
        )
    end

    return string.format(
        '%s returned from the maze with %d loot item(s). Banked total: %d/%d.',
        playerDisplayName,
        lootCount,
        self.CampSession.BankedItemCount,
        self.CampSession.TargetItemCount
    )
end

function RunSessionService:_applyReturnedPlayersFromTeleportData(players, acceptedTeleportData)
    local returnedPlayers = {}
    for _, player in ipairs(players) do
        local teleportData = self:_readTeleportData(player) or acceptedTeleportData
        local returnSummary = CampMazeSessionContract.findReturnSummary(teleportData, player.UserId)
        if returnSummary then
            self.PendingSpawnByUserId[player.UserId] =
                self:_getReturnSpawnTargetForSummary(returnSummary)
            table.insert(returnedPlayers, {
                Player = player,
                Summary = returnSummary,
                TeleportData = teleportData,
            })
        end
    end

    self:_refreshSessionOutcomeForCurrentState()

    if #returnedPlayers == 1 then
        local returnedPlayer = returnedPlayers[1]
        self.Status = self:_getReturnStatusText(
            returnedPlayer.Player.DisplayName,
            returnedPlayer.Summary,
            returnedPlayer.TeleportData
        )
    elseif #returnedPlayers > 1 then
        self.Status = string.format(
            'The crew returned from the maze. Banked loot: %d/%d.',
            self.CampSession.BankedItemCount,
            self.CampSession.TargetItemCount
        )
    else
        self.Status =
            'The ship is ready. Explore the wilderness, read the signs, and choose when to push for the tower.'
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

function RunSessionService:_getReturnSpawnTargetForSummary(summary)
    if RUN_MAZE_GATE_RETURN_REASONS[summary.ReturnReason] then
        return RunSpawnPoint.Kind.MazeReturn
    end

    return RunSpawnPoint.Kind.Return
end

function RunSessionService:_discoverClue(player, clueMarker)
    if type(clueMarker) ~= 'table' then
        return
    end

    local markerId = clueMarker.SourceMarkerId or clueMarker.ClueId
    if self.CollectedRunClueMarkerIds[markerId] then
        self:_toast(player, 'That clue has already been recovered.', 'Info')
        return
    end

    local success, result = self.InventoryService:pickup(player, {
        Id = string.format('run-clue-%s', clueMarker.ClueId),
        Name = clueMarker.ItemName or clueMarker.ReadableTitle,
        Description = 'Recovered clue from the wilderness.',
        ItemCategory = 'Clue',
        MissionCount = 0,
        ReadableTitle = clueMarker.ReadableTitle,
        ReadableText = clueMarker.ReadableText,
        ClueId = clueMarker.ClueId,
        ThreatHintId = clueMarker.ThreatHintId,
        SourceMarkerId = markerId,
    })
    if not success then
        self:_toast(player, 'Your pack is full. Drop something before taking the clue.', 'Error')
        return
    end

    self.CollectedRunClueMarkerIds[markerId] = true
    if clueMarker.Part and clueMarker.Part.Parent then
        clueMarker.Part:Destroy()
    end

    self:_sendPrivate(player, {
        Type = 'ClueDiscovered',
        ClueId = result.ClueId,
        Title = result.ReadableTitle,
        Body = result.ReadableText,
        ThreatHintId = result.ThreatHintId,
    })
    self:_setStatus(string.format('%s recovered a wilderness clue.', player.DisplayName))
end

function RunSessionService:_rebuildWorld()
    clearDefaultWorkspaceShell()

    if self.WorldInteractions then
        self.WorldInteractions:disconnectAll()
        self.WorldInteractions = nil
    end

    self.World = self.WorldBuilder.build()
    if self.GateOpen then
        self.World:openGate()
    end

    for _, clueMarker in ipairs(self.World.ClueMarkers or {}) do
        local markerId = clueMarker.SourceMarkerId or clueMarker.ClueId
        if
            self.CollectedRunClueMarkerIds[markerId]
            and clueMarker.Part
            and clueMarker.Part.Parent
        then
            clueMarker.Part:Destroy()
        end
    end

    if not self.MonsterService then
        self.MonsterService = self:_createMonsterService()
    end

    self.WorldInteractions = self.World:bindInteractions({
        OnShop = function(player)
            if not self:_canManageInventory(player) then
                return
            end

            self:_openShop(player)
        end,
        OnObjective = function(player)
            self:_openObjectiveBoard(player)
        end,
        OnGate = function(player)
            self:_openGate(player)
        end,
        OnMazePortal = function(player)
            if self:_canProcessMazeEntryRequest(player) then
                self:_requestMazeEntry(player, false)
            end
        end,
        OnClueMarker = function(player, clueMarker)
            if self:_canManageInventory(player) then
                self:_discoverClue(player, clueMarker)
            end
        end,
        OnOceanEntered = function(player, state)
            self:_setOceanState(player, state or 'Touching')
            self:_handleOceanEntered(player)
        end,
    })

    self:_teleportCharactersToSpawn()
end

function RunSessionService:_getPlayerArea(player)
    if not self.IsLaunched or not self.World then
        return 'Title Screen'
    end

    local character = player.Character
    local rootPart = character and character:FindFirstChild('HumanoidRootPart')
    if not rootPart then
        return self.GateOpen and 'Temple Threshold' or 'Temple Hall'
    end

    return self.World:getAreaForPosition(rootPart.Position)
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

function RunSessionService:_getActiveMazeRoster()
    return cloneArray(self.CampSession.PlayersInMaze)
end

function RunSessionService:_getReturnedSummaries()
    return cloneArray(self.CampSession.ReturnedPlayerSummaries)
end

function RunSessionService:_getObjectiveFor(player)
    if self.CampSession.SessionOutcome == 'success' then
        return 'Mission complete. Stay at the ship, compare what everyone learned, and review the final haul.'
    end

    if self.CampSession.SessionOutcome == 'failure' then
        return 'Mission failed after five rounds. Review what went wrong and what clues were recovered.'
    end

    if self:_isRoundClosing() then
        return 'This round is closing. Survivors are regrouping at the ship before the next push.'
    end

    if not self:_isRoundStarted() then
        if self.CampSession.HostUserId == player.UserId then
            return string.format(
                'Open the ship door to begin round %d of %d. Players can still search the wilderness for clues before heading to the tower.',
                self.CampSession.CurrentRound,
                self.CampSession.MaxRounds
            )
        end

        return 'Stay at the ship, check any recovered clues, then head into the wilderness or toward the tower when the host starts the round.'
    end

    if self:_isPlayerDead(player) then
        return 'You are out for this round. You will respawn at the ship when the next round begins.'
    end

    if self:_isPlayerInCamp(player) then
        return 'The round is live. Step into the wilderness for clues or head straight for the tower to enter the maze.'
    end

    return 'Search the wilderness for warning signs, then enter the maze and bring loot back alive.'
end

function RunSessionService:_setStatus(status)
    self.Status = status
    self:_broadcastSnapshot()
end

function RunSessionService:_getMissionSnapshot()
    local roundTimeRemainingSeconds = self:_getRoundTimeRemainingSeconds()

    return {
        CurrentRound = self.CampSession.CurrentRound,
        MaxRounds = self.CampSession.MaxRounds,
        BankedItemCount = self.CampSession.BankedItemCount,
        TargetItemCount = self.CampSession.TargetItemCount,
        RoundOutcome = self.CampSession.RoundOutcome,
        SessionOutcome = self.CampSession.SessionOutcome,
        RoundStarted = self:_isRoundStarted(),
        RoundTimeRemainingSeconds = roundTimeRemainingSeconds,
        SettlementReason = self.CampSession.SettlementReason,
    }
end

function RunSessionService:_getBookSnapshot()
    local missionSnapshot = self:_getMissionSnapshot()
    local progress = 0
    if missionSnapshot.TargetItemCount > 0 then
        progress =
            math.clamp(missionSnapshot.BankedItemCount / missionSnapshot.TargetItemCount, 0, 1)
    end

    return {
        CurrentRound = missionSnapshot.CurrentRound,
        MaxRounds = missionSnapshot.MaxRounds,
        BankedItemCount = missionSnapshot.BankedItemCount,
        TargetItemCount = missionSnapshot.TargetItemCount,
        RoundOutcome = missionSnapshot.RoundOutcome,
        SessionOutcome = missionSnapshot.SessionOutcome,
        TeamPages = missionSnapshot.BankedItemCount,
        BookGoalAmount = missionSnapshot.TargetItemCount,
        BookGoalProgress = progress,
        BookGoalReached = missionSnapshot.BankedItemCount >= missionSnapshot.TargetItemCount,
        RoundStarted = missionSnapshot.RoundStarted,
        RoundTimeRemainingSeconds = missionSnapshot.RoundTimeRemainingSeconds,
        SettlementReason = missionSnapshot.SettlementReason,
    }
end

function RunSessionService:_sendPrivate(player, payload)
    self.Remotes.RunPrivateState:FireClient(player, payload)
end

function RunSessionService:_broadcastPrivate(payload)
    for _, player in ipairs(Players:GetPlayers()) do
        self:_sendPrivate(player, payload)
    end
end

function RunSessionService:_toast(player, message, tone)
    self:_sendPrivate(player, {
        Type = 'Toast',
        Message = message,
        Tone = tone or 'Info',
    })
end

function RunSessionService:_openShop(player)
    local missionSnapshot = self:_getMissionSnapshot()
    self:_sendPrivate(player, {
        Type = 'OpenShop',
        Items = {},
        TeamPages = missionSnapshot.BankedItemCount,
        BankedItemCount = missionSnapshot.BankedItemCount,
        TargetItemCount = missionSnapshot.TargetItemCount,
        Inventory = self.InventoryService:getSummary(player),
        RoundStarted = self:_isRoundStarted(),
    })
end

function RunSessionService:_openSell(player)
    self:_openObjectiveBoard(player)
end

function RunSessionService:_openObjectiveBoard(player)
    local snapshot = self:_getMissionSnapshot()
    local canSettle = self:_isRoundStarted()
        and not self:_isRoundClosing()
        and not self:_isPlayerDead(player)
        and self:_isPlayerInCamp(player)
    self:_sendPrivate(player, {
        Type = 'OpenObjectiveBoard',
        BoardType = 'MissionBoard',
        CurrentRound = snapshot.CurrentRound,
        MaxRounds = snapshot.MaxRounds,
        BankedItemCount = snapshot.BankedItemCount,
        TargetItemCount = snapshot.TargetItemCount,
        RoundOutcome = snapshot.RoundOutcome,
        SessionOutcome = snapshot.SessionOutcome,
        TeamPages = snapshot.BankedItemCount,
        BookGoalAmount = snapshot.TargetItemCount,
        BookGoalProgress = snapshot.TargetItemCount > 0
                and math.clamp(snapshot.BankedItemCount / snapshot.TargetItemCount, 0, 1)
            or 0,
        BookGoalReached = snapshot.BankedItemCount >= snapshot.TargetItemCount,
        RoundStarted = snapshot.RoundStarted,
        RoundTimeRemainingSeconds = snapshot.RoundTimeRemainingSeconds,
        SettlementReason = snapshot.SettlementReason,
        CanSettle = canSettle,
        Items = {},
        Inventory = self.InventoryService:getSummary(player),
    })
end

function RunSessionService:_handlePurchase(player, _itemId)
    if not self:_canManageInventory(player) then
        return
    end

    self:_sendPrivate(player, {
        Type = 'ShopResult',
        Success = false,
        Reason = 'StoreRetired',
    })
end

function RunSessionService:_handleSell(player, _itemInstanceId)
    if not self:_canManageInventory(player) then
        return
    end

    self:_sendPrivate(player, {
        Type = 'BookExchangeResult',
        Success = false,
        Reason = 'AutoBankOnly',
        TeamPages = self.CampSession.BankedItemCount,
        BankedItemCount = self.CampSession.BankedItemCount,
    })
end

function RunSessionService:_resolveMazeEntryAvailability()
    local availability = MazeEntryAvailability.evaluate({
        PlaceIds = SessionConfig.PlaceIds,
        PlaceId = game.PlaceId,
        GameId = game.GameId,
        IsStudio = RunService:IsStudio(),
    })

    if not self:_isRoundStarted() then
        availability.Mode = MazeEntryAvailability.Mode.Blocked
        availability.ReasonCode = 'RoundNotStarted'
        availability.Reason =
            'The round has not started yet. Wait for the host to open the ship door.'
    elseif self:_isRoundClosing() then
        availability.Mode = MazeEntryAvailability.Mode.Blocked
        availability.ReasonCode = 'RoundClosing'
        availability.Reason = 'This round is already closing.'
    end

    self.MazeEntryMode = availability.Mode
    self.MazeEntryReason = availability.Reason
    self.MazeEntryReasonCode = availability.ReasonCode

    return availability
end

function RunSessionService:_broadcastSnapshot()
    for _, player in ipairs(Players:GetPlayers()) do
        local mazeEntryAvailability = self:_evaluateMazeEntry(player)
        self.Remotes.RunState:FireClient(
            player,
            RunSnapshotBuilder.buildForPlayer(self, player, mazeEntryAvailability)
        )

        self.Remotes.RunPrivateState:FireClient(player, nil)
    end
end

function RunSessionService:_canManageInventory(player)
    if not self.IsLaunched then
        return false
    end

    if self:_isRoundClosing() then
        self:_setStatus('This round is already closing, so camp inventory changes are locked.')
        return false
    end

    if CampMazeSessionContract.isPlayerInMaze(self.CampSession, player.UserId) then
        self:_setStatus(
            string.format(
                '%s is already marked inside the maze and cannot change camp inventory.',
                player.DisplayName
            )
        )
        return false
    end

    if self:_isPlayerDead(player) then
        self:_setStatus(
            string.format(
                '%s is dead for this round and cannot use camp stations.',
                player.DisplayName
            )
        )
        return false
    end

    return true
end

function RunSessionService:_equipItem(player, itemInstanceId)
    if not self:_canManageInventory(player) then
        return
    end

    local success, result = self.InventoryService:equip(player, itemInstanceId)
    if not success then
        self:_setStatus(
            string.format(
                '%s could not equip that item (%s).',
                player.DisplayName,
                tostring(result)
            )
        )
        return
    end

    self:_setStatus(string.format('%s equipped %s in the temple.', player.DisplayName, result.Name))
end

function RunSessionService:_unequipItem(player)
    if not self:_canManageInventory(player) then
        return
    end

    local success, result = self.InventoryService:unequip(player)
    if not success then
        self:_setStatus(
            string.format(
                '%s could not stow the held item (%s).',
                player.DisplayName,
                tostring(result)
            )
        )
        return
    end

    self:_setStatus(
        string.format('%s stowed %s back into the backpack.', player.DisplayName, result.Name)
    )
    Shared.Runtime.HeldFlashlightHeadlight.syncHeldItem(player, nil)
end

function RunSessionService:_handleUseTool(player)
    Gameplay.HeldToolUseRequest.apply(player, {
        canManageInventory = function(p)
            return self:_canManageInventory(p)
        end,
        inventoryService = self.InventoryService,
        monsterService = self.MonsterService,
        playerService = self.PlayerService,
        setStatus = function(message)
            self:_setStatus(message)
        end,
        shouldConsumeCrowbarOnUse = function(_p)
            return self.CampSession.DangerActive == true
        end,
    })
end

function RunSessionService:_openGate(player)
    if not self.World then
        return
    end

    self:_ensureHost()

    if self.CampSession.SessionOutcome ~= nil then
        self:_setStatus(
            'This mission is already over. Review the final debrief at the ship instead of starting another round.'
        )
        return
    end

    if self:_isRoundClosing() then
        self:_setStatus(
            'The current round is already closing. Wait for the ship regroup before starting again.'
        )
        return
    end

    if not self:_isRoundStarted() then
        if self.CampSession.HostUserId ~= player.UserId then
            self:_setStatus(
                string.format(
                    '%s checked the ship door. Only the host can start the round.',
                    player.DisplayName
                )
            )
            return
        end

        local roundStartTime = self:_getServerTimeNow()
        local roundEndTime = roundStartTime + self.SessionData.RunDurationSeconds
        self.GateOpen = true
        self.CampSession = CampMazeSessionContract.markRoundStarted(self.CampSession, {
            HostUserId = player.UserId,
            RoundStartTime = roundStartTime,
            RoundEndTime = roundEndTime,
            DangerActive = true,
        })
        self:_syncCampSession()
        self.World:openGate()
        self.TODService:start()
        self:_beginExpedition()
        self.Status = string.format(
            '%s opened the ship door. Round %d of %d is live: search the wilderness, then head for the tower.',
            player.DisplayName,
            self.CampSession.CurrentRound,
            self.CampSession.MaxRounds
        )
        self:_broadcastSnapshot()
        return
    end

    self:_setStatus(
        string.format('%s checked the ship door. This round is already live.', player.DisplayName)
    )
end

function RunSessionService:_bindItemRemotes()
    local getInventoryRemote = self.Remotes.GetInventory
    local getItemDataRemote = self.Remotes.GetItemData
    local equipItemRemote = self.Remotes.EquipItem
    local useItemRemote = self.Remotes.UseItem

    -- Contract v2 keeps run startup on RunAction/RunState/RunPrivateState.
    -- Older harnesses may still author the legacy item remotes, so only bind
    -- them when they actually exist.
    if
        getInventoryRemote == nil
        and getItemDataRemote == nil
        and equipItemRemote == nil
        and useItemRemote == nil
    then
        return
    end

    if getInventoryRemote ~= nil then
        getInventoryRemote.OnServerInvoke = function(player: Player)
            return self:_inventorySummaryFor(player)
        end
    end

    if getItemDataRemote ~= nil then
        getItemDataRemote.OnServerInvoke = function(player: Player, legacyToolName: string)
            return self:_getLegacyHeldItemShim(player, legacyToolName)
        end
    end

    if equipItemRemote == nil or useItemRemote == nil then
        return
    end

    equipItemRemote.OnServerEvent:Connect(function(player: Player, itemInstanceId: any, equip: any)
        if type(itemInstanceId) ~= 'number' then
            return
        end

        if equip == true then
            self:_equipItem(player, itemInstanceId)
        else
            self:_unequipItem(player)
        end

        self:_broadcastSnapshot()
    end)

    useItemRemote.OnServerEvent:Connect(function(player: Player, legacyToolName: string)
        if type(legacyToolName) ~= 'string' then
            return
        end

        if not self:_canManageInventory(player) then
            return
        end

        local expectedCategory = LEGACY_TOOL_CATEGORY[legacyToolName]
        if not expectedCategory then
            return
        end

        local held = self.InventoryService:getSummary(player).HeldItem
        if not held or held.ToolCategory ~= expectedCategory then
            return
        end

        self.InventoryService:consumeHeldItemState(player, os.clock())
        self:_broadcastSnapshot()
    end)
end

function RunSessionService:_isPlayerNearTerminalPrompt(player, terminalOrPrompt, distanceBuffer)
    if not terminalOrPrompt then
        return false
    end

    if type(terminalOrPrompt.isPlayerNear) == 'function' then
        return terminalOrPrompt:isPlayerNear(
            player,
            distanceBuffer or TERMINAL_INTERACTION_DISTANCE_BUFFER
        )
    end

    local prompt = terminalOrPrompt
    local promptPart = prompt.Parent
    if not promptPart or not promptPart:IsA('BasePart') then
        return false
    end

    local character = player.Character
    local rootPart = character and character:FindFirstChild('HumanoidRootPart')
    if not rootPart or not rootPart:IsA('BasePart') then
        return false
    end

    local maxDistance = prompt.MaxActivationDistance
        + (distanceBuffer or TERMINAL_INTERACTION_DISTANCE_BUFFER)
    return (rootPart.Position - promptPart.Position).Magnitude <= maxDistance
end

function RunSessionService:_isPlayerNearMazePrompt(player)
    return self:_isPlayerNearTerminalPrompt(
        player,
        self.World and self.World.MazePortal,
        MAZE_ENTRY_DISTANCE_BUFFER
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
            self:_setStatus('The maze session is already complete for this mission.')
            return
        end

        local result = self.RunToMazeTransition:enter({
            Player = player,
            CampSession = self.CampSession,
            GateOpen = self.GateOpen,
            SessionConfig = self.SessionData,
            PlayerInventory = self.InventoryService:getSummary(player),
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

function RunSessionService:_requestMazeEntry(player, requireDistanceCheck)
    if not self.IsLaunched or not self.World then
        return
    end

    if requireDistanceCheck and not self:_isPlayerNearMazePrompt(player) then
        return
    end

    local availability = self:_evaluateMazeEntry(player)
    if availability.Mode == MazeEntryAvailability.Mode.Teleport then
        self:_enterMaze(player)
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

function RunSessionService:_compileMonsterForRun(authorProfile)
    local MonsterRuntimeProfile = Gameplay.Monsters.MonsterRuntimeProfile

    local tuning = authorProfile.Tuning
    local presentation = authorProfile.Executable.Presentation
    local behaviors = {}

    for _, intent in ipairs(authorProfile.Executable.BehaviorIntents or {}) do
        if intent.Enabled ~= false then
            behaviors[intent.Id] = true
        end
    end

    local runtimeProfile = {
        Id = authorProfile.Id,
        Name = authorProfile.Name,
        Presentation = table.freeze({
            ModelAssetId = presentation.ModelAssetId,
            RigType = presentation.RigType,
            AnimationMode = presentation.AnimationMode,
            ChaseLoopSoundAssetId = presentation.ChaseLoopSoundAssetId,
        }),
        AttackCooldownSeconds = tuning.AttackCooldownSeconds or 1,
        AttackDamagePips = tuning.AttackDamagePips or 1,
        AttackRange = tuning.AttackRange or 4,
        Speed = tuning.Speed,
        SightRange = tuning.SightRange,
        PatrolSpeedMultiplier = tuning.PatrolSpeedMultiplier,
        SpawnOffset = tuning.SpawnOffset or Vector3.new(0, 4, 0),
        CombatHitPoints = tuning.CombatHitPoints or 1,
        Behaviors = table.freeze(behaviors),
        Effects = table.freeze({}),
    }
    runtimeProfile.Components =
        Gameplay.Monsters.MonsterComponentConfig.fromRuntimeProfile(runtimeProfile)
    runtimeProfile = table.freeze(runtimeProfile)

    local valid, reason = MonsterRuntimeProfile.validate(runtimeProfile)
    if not valid then
        error(string.format('Run monster profile invalid: %s', tostring(reason)), 0)
    end

    return runtimeProfile
end

function RunSessionService:_createMonsterService()
    local monsterProfile = self:_compileMonsterForRun(Gameplay.Config.Monsters[1])
    local canTraverseFn = RunWorldScanner.buildCanTraverseFn(self.World)
    local randomSource = Random.new(self.SessionData.Seed > 0 and self.SessionData.Seed or 42)

    return MonsterService.new(
        monsterProfile,
        function()
            return self.CampSession.DangerActive == true
        end,
        function(player)
            return self:_isPlayerTargetableInField(player)
        end,
        canTraverseFn,
        {
            RandomSeed = self.SessionData.Seed,
            RandomSource = randomSource,
            OnAttackHit = function(player, damagePips, hitContext)
                self:_applyPlayerDamage(player, damagePips)
                if hitContext and hitContext.Effects then
                    for _, effect in ipairs(hitContext.Effects) do
                        self.PlayerStateService:applyEffect(
                            player,
                            effect.Id,
                            effect.DurationSeconds
                        )
                    end
                end
            end,
        }
    )
end

function RunSessionService:_applyPlayerDamage(player, damagePips)
    if not self:_isPlayerTargetableInField(player) then
        return
    end

    local damageKind = DAMAGE_KIND_BY_PIPS[damagePips]
    if damageKind == nil then
        return
    end

    local success, result = self.PlayerService:applyDamage(player, damageKind)
    if not success then
        warn(
            ('[RunSessionService] applyDamage failed for %s: %s'):format(
                player.DisplayName,
                tostring(result)
            )
        )
        return
    end

    local summary = self.PlayerService:getSummary(player)
    if summary and summary.Health and summary.Health.IsDead then
        self:_setStatus(
            string.format(
                '%s died in the run field and will respawn at the ship next round.',
                player.DisplayName
            )
        )
        self:_toast(player, 'You are out for this round.', 'Error')
        self:_maybeEndRoundForAllDeaths()
    end
end

function RunSessionService:_beginExpedition()
    if not self.MonsterService then
        return
    end

    local allPositions = RunWorldScanner.scanSpawnPoints()
    if #allPositions == 0 then
        warn('[RunSessionService] No SpawnPoint_* found in RunStaticWorld - skipping monster spawn')
        return
    end

    local shipPosition = nil
    local shipCollision = self.World and self.World.Collision and self.World.Collision.Ship
    if shipCollision and shipCollision:IsA('PVInstance') then
        shipPosition = shipCollision:GetPivot().Position
    end

    local shipModel = self.World and self.World.ShipModel
    if not shipPosition and shipModel and shipModel:IsA('PVInstance') then
        shipPosition = shipModel:GetPivot().Position
    end

    if not shipPosition then
        warn(
            '[RunSessionService] Ship position not found (no collision shell or model) - skipping monster spawn'
        )
        return
    end

    local eligible = RunMonsterSpawnPolicy.collectEligiblePatrolPoints(allPositions, shipPosition)
    if #eligible == 0 then
        warn(
            '[RunSessionService] No eligible patrol points after exclusion - skipping monster spawn'
        )
        return
    end

    local initialIndex = RunMonsterSpawnPolicy.selectInitialPatrolIndex(eligible)
    self.MonsterService:spawn(eligible, initialIndex)
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

    self:_ensureHost()
    self.GateOpen = self.CampSession.GateOpen == true
    self:_syncCampSession()
    self:_subscribeToRoundSignals()
    self:_rebuildWorld()

    self.IsLaunched = true
    Players.CharacterAutoLoads = true

    for _, player in ipairs(Players:GetPlayers()) do
        player:LoadCharacter()
    end

    self:_startSnapshotLoop()
    if self.CampSession.RoundStarted == true then
        self:_setStatus('The shared round is already live. Regroup or push deeper as needed.')
    else
        self:_setStatus('The ship is safe. The host can open the door when the crew is ready.')
    end
end

function RunSessionService:_getPlayerUpdateContext(player)
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass('Humanoid')
    local rootPart = humanoid and humanoid.RootPart
    local currentPosition = rootPart and rootPart.Position or Vector3.zero

    return {
        CurrentPosition = currentPosition,
        InputState = {},
    }
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
                local dt = currentTick - previousTick
                previousTick = currentTick

                for _, player in ipairs(Players:GetPlayers()) do
                    local context = self:_getPlayerUpdateContext(player)
                    self.PlayerService:update(player, dt, context)
                    self:_syncPlayerMovement(player)
                    self:_updateOceanPerPlayer(player, dt)
                end

                if
                    self:_isRoundStarted()
                    and not self.RoundClosureInProgress
                    and (self:_getRoundTimeRemainingSeconds() or 0) <= 0
                then
                    self:_completeRound(ROUND_SETTLEMENT_REASON.Timeout, nil, true)
                end

                self:_maybeEndRoundForAllDeaths()
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

    local playerState = self.PlayerService:getSummary(player)
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
    self:_hydratePlayerInventory(player, teleportData)

    local summary = CampMazeSessionContract.findReturnSummary(teleportData, player.UserId)
    if summary then
        self.PendingSpawnByUserId[player.UserId] = self:_getReturnSpawnTargetForSummary(summary)
        self.Status = self:_getReturnStatusText(player.DisplayName, summary, teleportData)
        return
    end

    self.CampSession = CampMazeSessionContract.prunePlayer(self.CampSession, player.UserId, {
        PreserveMazeEntry = CampMazeSessionContract.isPlayerInMaze(self.CampSession, player.UserId),
    })
    self.GateOpen = self.CampSession.GateOpen
    self.Status = string.format('%s joined the ship session.', player.DisplayName)
end

function RunSessionService:_ensureAuthoritativeSessionSeed()
    local seed, issuedNewSeed = SessionSeedPolicy.ensureAuthoritativeSeed({
        CurrentSeed = self.SessionData.Seed,
        DefaultSeed = SessionConfig.DefaultSeed,
        HasAuthoritativeSeed = self.HasAuthoritativeSessionSeed,
        RandomSource = self.SessionSeedRandom or Random.new(),
    })

    self.SessionData.Seed = seed
    if issuedNewSeed then
        self.HasAuthoritativeSessionSeed = true
    end
end

function RunSessionService:_emptyInventorySummary()
    return {
        Capacity = self.SessionData.InventoryCapacity,
        Weight = 0,
        Count = 0,
        BackpackCount = 0,
        HeldCount = 0,
        Value = 0,
        BackpackItems = {},
        HeldItem = nil,
    }
end

function RunSessionService:_inventorySummaryFor(player)
    if not self.IsLaunched then
        return self:_emptyInventorySummary()
    end

    return self.InventoryService:getSummary(player)
end

function RunSessionService:_getLegacyHeldItemShim(player, legacyToolName)
    if type(legacyToolName) ~= 'string' then
        return nil
    end

    local expectedCategory = LEGACY_TOOL_CATEGORY[legacyToolName]
    if not expectedCategory then
        return nil
    end

    local held = self:_inventorySummaryFor(player).HeldItem
    if not held or held.ToolCategory ~= expectedCategory then
        return nil
    end

    return {
        Name = held.Name,
        Type = 'Tool',
        Description = held.Description or '',
        IsEquipped = true,
        IsActive = false,
        IconAssetId = held.IconAssetId or '',
        Color = held.Color,
    }
end

function RunSessionService:start()
    warn(string.format('[run-session] build=%s', self.BuildFingerprint))
    self:_loadSessionDataFromJoin()
    self:_ensureHost()
    self:_ensureAuthoritativeSessionSeed()
    RunInventoryBridge.bind(self)
    self:_bindItemRemotes()
    Players.CharacterAutoLoads = false
    self:_subscribeToRoundSignals()

    for _, player in ipairs(Players:GetPlayers()) do
        bindCharacterTeleport(self, player)
        self:_addPlayerState(player)
        self:_hydratePlayerInventory(player, self:_readTeleportData(player))

        if player.Character then
            player.Character:Destroy()
        end
    end

    Players.PlayerAdded:Connect(function(player)
        bindCharacterTeleport(self, player)
        self:_addPlayerState(player)
        self:_handlePlayerTeleportData(player)
        self:_ensureHost()

        if self.IsLaunched then
            player:LoadCharacter()
        end

        self:_broadcastSnapshot()
        self.TODService:sendToPlayer(player)
    end)

    Players.PlayerRemoving:Connect(function(player)
        self.LastMazeEntryRequestAtByUserId[player.UserId] = nil
        self.LastOceanSplashAtByUserId[player.UserId] = nil
        self.OceanStateByUserId[player.UserId] = nil
        self.OceanTimersByUserId[player.UserId] = nil
        self.OceanOriginalSpeedsByUserId[player.UserId] = nil
        self.PendingSpawnByUserId[player.UserId] = nil
        self.CampSession = CampMazeSessionContract.prunePlayer(self.CampSession, player.UserId, {
            PreserveMazeEntry = CampMazeSessionContract.isPlayerInMaze(
                self.CampSession,
                player.UserId
            ),
        })
        self.GateOpen = self.CampSession.GateOpen
        self:_removePlayerState(player)
        self:_ensureHost()
        self:_broadcastSnapshot()
    end)

    self.Remotes.RunAction.OnServerEvent:Connect(function(player, payload)
        if type(payload) ~= 'table' then
            return
        end

        if payload.Type == 'RequestEnterMaze' then
            if self:_canProcessMazeEntryRequest(player) then
                self:_requestMazeEntry(player, true)
            end
        elseif payload.Type == 'RequestPurchaseItem' then
            self:_handlePurchase(player, payload.ItemId)
        elseif payload.Type == 'RequestSellItem' or payload.Type == 'RequestBookExchange' then
            self:_handleSell(player, payload.ItemInstanceId)
        elseif payload.Type == 'RequestEquipItem' then
            self:_equipItem(player, payload.ItemInstanceId)
        elseif payload.Type == 'RequestUnequipItem' then
            self:_unequipItem(player)
        elseif payload.Type == 'RequestUseTool' then
            self:_handleUseTool(player)
        elseif payload.Type == 'RequestSprintStart' then
            self:_setPlayerSprinting(player, true)
        elseif payload.Type == 'RequestSprintStop' then
            self:_setPlayerSprinting(player, false)
        elseif payload.Type == 'RequestStartExpedition' or payload.Type == 'RequestStartRound' then
            self:_openGate(player)
        elseif payload.Type == 'RequestTriggerSettlement' then
            if not self:_isRoundStarted() then
                self:_toast(player, 'The round has not started yet.', 'Error')
            elseif not self:_isPlayerInCamp(player) then
                self:_toast(player, 'Return to the ship before ending the round.', 'Error')
            elseif self:_isPlayerDead(player) then
                self:_toast(player, 'Dead players cannot trigger settlement.', 'Error')
            else
                self:_completeRound(ROUND_SETTLEMENT_REASON.Book, player, false)
            end
        end
    end)

    self.TODService:prime()
    self:_broadcastSnapshot()

    self:_launchRun(nil)
end

return RunSessionService
