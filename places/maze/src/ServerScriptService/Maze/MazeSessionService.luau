local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService('RunService')
local Workspace = game:GetService('Workspace')

local DEFAULT_WORKSPACE_SHELL_NAMES = { 'Baseplate', 'SpawnLocation' }
local CAMP_SESSION_LOCK_WAIT_SECONDS = 0.05
local SNAPSHOT_INTERVAL_SECONDS = 0.25
local UGC_MONSTER_GLOBAL_CAP = 5
local TELEPORT_DATA_WAIT_SECONDS = 3
local TELEPORT_DATA_WAIT_STEP_SECONDS = 0.05
local MAZE_DIAG_PREFIX = '[MazeDiag]'
local CORPSE_COLOR = Color3.fromRGB(92, 92, 92)
local CORPSE_MATERIAL = Enum.Material.Slate
local CORPSE_SIZE = Vector3.new(4, 1.2, 2)
local CORPSE_VERTICAL_OFFSET = -2.4
local WORLD_BUILD_SOURCE = table.freeze({
    DirectBootDefault = 'DirectBootDefault',
    JoinDataMergedBeforeBuild = 'JoinDataMergedBeforeBuild',
    JoinDataMergedAfterBuild = 'JoinDataMergedAfterBuild',
})

local Packages = ReplicatedStorage:WaitForChild('Packages')
local Shared = require(Packages:WaitForChild('Shared'))
local Gameplay = require(Packages:WaitForChild('Gameplay'))
local SharedPackage = Packages:WaitForChild('Shared')

local SessionConfig = Shared.Config.SessionConfig
local CampMazeSessionContract = Shared.Session.CampMazeSessionContract
local SessionSeedPolicy = Shared.Session.SessionSeedPolicy
local Remotes = Shared.Network.Remotes.ensureScope(Shared.Network.Remotes.Scope.Maze)
local InventoryService =
    require(SharedPackage:WaitForChild('Runtime'):WaitForChild('InventoryService'))
local MonsterService = require(SharedPackage:WaitForChild('Runtime'):WaitForChild('MonsterService'))
local ControlStateService = Shared.Runtime.ControlStateService
local FormalLocomotion = Shared.Runtime.FormalLocomotion
local PlayerStateService = Shared.Runtime.PlayerStateService
local PlayerService = Shared.Runtime.PlayerService
local TeleportInventoryHydrator = Shared.Runtime.TeleportInventoryHydrator

local MazeBootstrapStatus = require(script.Parent.MazeBootstrapStatus)
local MazeToRunTransition = require(script.Parent.MazeToRunTransition)
local MazeWorldBuilder = require(script.Parent.MazeWorldBuilder)

local DEBUG_DAMAGE_BY_ACTION = {
    RequestDebugLightDamage = Gameplay.PlayerState.DamageKind.Light,
    RequestDebugHeavyDamage = Gameplay.PlayerState.DamageKind.Heavy,
}
local DAMAGE_KIND_BY_PIPS = table.freeze({
    [1] = Gameplay.PlayerState.DamageKind.Light,
    [2] = Gameplay.PlayerState.DamageKind.Heavy,
})

local MazeMonsterSpawnPolicy = Gameplay.Monsters.MazeMonsterSpawnPolicy

local MazeSessionService = {}
MazeSessionService.__index = MazeSessionService
MazeSessionService.BootstrapPhaseAttribute = MazeBootstrapStatus.PhaseAttribute
MazeSessionService.BootstrapErrorAttribute = MazeBootstrapStatus.ErrorAttribute
MazeSessionService.BootstrapFailedAttribute = MazeBootstrapStatus.FailedAttribute

local function formatDiagnosticValue(value)
    if value == nil then
        return 'nil'
    end

    return tostring(value)
end

local function damageKindFromPips(damagePips)
    return DAMAGE_KIND_BY_PIPS[damagePips]
end

local function buildDiagnosticFieldString(fields)
    local keys = {}
    for key in pairs(fields) do
        table.insert(keys, key)
    end
    table.sort(keys)

    local segments = {}
    for _, key in ipairs(keys) do
        table.insert(segments, string.format('%s=%s', key, formatDiagnosticValue(fields[key])))
    end

    return table.concat(segments, ' | ')
end

local function getWorldBuildSourceForBuild(hasAcceptedTeleportDataBeforeBuild)
    if hasAcceptedTeleportDataBeforeBuild then
        return WORLD_BUILD_SOURCE.JoinDataMergedBeforeBuild
    end

    return WORLD_BUILD_SOURCE.DirectBootDefault
end

local function mergeSummaries(existingSummaries, nextSummaries)
    local summariesByUserId = {}

    for _, summary in ipairs(existingSummaries or {}) do
        summariesByUserId[summary.UserId] = table.clone(summary)
    end

    for _, summary in ipairs(nextSummaries or {}) do
        summariesByUserId[summary.UserId] = table.clone(summary)
    end

    local merged = {}
    for _, summary in pairs(summariesByUserId) do
        table.insert(merged, summary)
    end

    table.sort(merged, function(left, right)
        return left.UserId < right.UserId
    end)

    return merged
end

local function clearDefaultWorkspaceShell()
    for _, instanceName in ipairs(DEFAULT_WORKSPACE_SHELL_NAMES) do
        local instance = Workspace:FindFirstChild(instanceName)
        if instance then
            instance:Destroy()
        end
    end
end

local function bindCharacterTeleport(self, player)
    player.CharacterAdded:Connect(function(character)
        task.wait()
        if not self.World or not character.Parent then
            return
        end

        local targetCFrame = self.World.SpawnCFrame
        if not self.RunTracker:isPlayerActive(player.UserId) then
            targetCFrame = self.World.ReturnHoldCFrame
        end

        character:PivotTo(targetCFrame)
        self:_applyMovementMode(player)
    end)
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

local function buildMazeMonsterRuntimeProfile(monsterAuthorProfile)
    local compiledOk, runtimeProfileOrReason =
        Gameplay.Monsters.compileMonsterForMaze(monsterAuthorProfile)
    if not compiledOk then
        error(
            string.format(
                'Failed to compile maze monster %s: %s',
                tostring(monsterAuthorProfile and monsterAuthorProfile.Id),
                tostring(runtimeProfileOrReason)
            ),
            0
        )
    end

    return runtimeProfileOrReason
end

local function cloneUgcPendingPayload(payload)
    if type(payload) ~= 'table' then
        return nil
    end

    return {
        OwnerUserId = payload.OwnerUserId,
        MonsterId = payload.MonsterId,
        MonsterName = payload.MonsterName,
        Seed = payload.Seed,
        RecipeHash = payload.RecipeHash,
        RuntimeProfile = table.clone(payload.RuntimeProfile or {}),
        Diagnostics = table.clone(payload.Diagnostics or {}),
    }
end

function MazeSessionService:_emitDiagnostic(event, fields)
    self.DiagnosticSequence += 1
    local prefix = string.format(
        '%s #%03d t=%.3f event=%s',
        MAZE_DIAG_PREFIX,
        self.DiagnosticSequence,
        os.clock(),
        event
    )
    local fieldString = buildDiagnosticFieldString(fields or {})
    if fieldString == '' then
        print(prefix)
        return
    end

    print(string.format('%s | %s', prefix, fieldString))
end

function MazeSessionService:_getWorldBuildMetadataFields()
    local metadata = self.WorldBuildMetadata or {}
    return {
        WorldBuildIsDirectBoot = metadata.IsDirectBoot,
        WorldBuildMazeAccessCode = metadata.MazeAccessCode,
        WorldBuildSeed = metadata.Seed,
        WorldBuildSessionId = metadata.SessionId,
        WorldBuildSource = metadata.Source,
    }
end

function MazeSessionService:_applyWorldBuildMetadataToRoot()
    if not (self.World and self.World.Root and self.WorldBuildMetadata) then
        return
    end

    self.World.Root:SetAttribute('WorldBuildSeed', self.WorldBuildMetadata.Seed)
    self.World.Root:SetAttribute('WorldBuildSessionId', self.WorldBuildMetadata.SessionId or 'nil')
    self.World.Root:SetAttribute(
        'WorldBuildMazeAccessCode',
        self.WorldBuildMetadata.MazeAccessCode or 'nil'
    )
    self.World.Root:SetAttribute('WorldBuildIsDirectBoot', self.WorldBuildMetadata.IsDirectBoot)
    self.World.Root:SetAttribute('WorldBuildSource', self.WorldBuildMetadata.Source)
end

function MazeSessionService:_recordWorldBuildMetadata()
    self.WorldBuildMetadata = {
        IsDirectBoot = self.IsDirectBoot == true,
        MazeAccessCode = self.CampSession and self.CampSession.MazeAccessCode or nil,
        Seed = self.SessionData.Seed,
        SessionId = self.CampSession and self.CampSession.SessionId or nil,
        Source = getWorldBuildSourceForBuild(self.HasAcceptedTeleportDataBeforeBuild == true),
    }
    self:_applyWorldBuildMetadataToRoot()
end

function MazeSessionService:_markAcceptedTeleportData(teleportData)
    self.HasAcceptedTeleportData = true
    self.LastAcceptedTeleportData = teleportData

    if self.WorldBuildMetadata then
        if self.WorldBuildMetadata.Source == WORLD_BUILD_SOURCE.DirectBootDefault then
            self.WorldBuildMetadata.Source = WORLD_BUILD_SOURCE.JoinDataMergedAfterBuild
            self:_applyWorldBuildMetadataToRoot()
            self:_emitDiagnostic('WorldBuildSourcePromoted', self:_getWorldBuildMetadataFields())
        end
        return false
    end

    self.HasAcceptedTeleportDataBeforeBuild = true
    return true
end

function MazeSessionService:_queuePendingUgcMonsterPayload(payload)
    local clonedPayload = cloneUgcPendingPayload(payload)
    if clonedPayload == nil then
        return
    end

    table.insert(self.PendingUgcMonsterPayloads, clonedPayload)
end

function MazeSessionService:_destroyUgcMonsters()
    for _, entry in ipairs(self.UgcMonsterServices) do
        if entry.Service and entry.Service.destroy then
            entry.Service:destroy()
        end
    end
    table.clear(self.UgcMonsterServices)
end

function MazeSessionService:_buildMonsterRuntimeOptions(randomSeed)
    return {
        RandomSeed = randomSeed,
        OnAttackHit = function(player, damagePips)
            local damageKind = damageKindFromPips(damagePips)
            if damageKind == nil then
                return
            end

            self:_applyPlayerDamage(player, damageKind)
        end,
    }
end

function MazeSessionService:_spawnQueuedUgcMonsters()
    if #self.PendingUgcMonsterPayloads == 0 then
        return
    end

    local patrolPoints = self.World and self.World.PatrolPoints or {}
    if #patrolPoints == 0 then
        table.clear(self.PendingUgcMonsterPayloads)
        self:_setStatus('UGC 怪物刷怪失败：迷宫缺少巡逻点。')
        return
    end

    local queuedPayloads = table.clone(self.PendingUgcMonsterPayloads)
    table.clear(self.PendingUgcMonsterPayloads)

    for _, payload in ipairs(queuedPayloads) do
        if #self.UgcMonsterServices >= UGC_MONSTER_GLOBAL_CAP then
            self:_setStatus('UGC 怪物刷怪已达本局上限（5只）。')
            break
        end

        local runtimeProfile = payload.RuntimeProfile
        local runtimeValid, runtimeReason =
            Gameplay.Monsters.MonsterRuntimeProfile.validate(runtimeProfile)
        if not runtimeValid then
            self:_setStatus(
                string.format(
                    'UGC 怪物运行配置无效（owner=%s, reason=%s）。',
                    tostring(payload.OwnerUserId),
                    tostring(runtimeReason)
                )
            )
            continue
        end

        local randomSeed = if type(payload.Seed) == 'number'
            then math.floor(payload.Seed)
            else self.SessionData.Seed
        if randomSeed <= 0 then
            randomSeed = self.SessionData.Seed
        end
        local random = Random.new(randomSeed)

        local initialPatrolIndex, spawnRoomId =
            MazeMonsterSpawnPolicy.selectRandomEligiblePatrolIndex(
                self.World.RoomIds,
                self.World.RoomAffordances,
                self.World.RoomById,
                self.World.CampRoomId,
                random
            )
        if initialPatrolIndex == nil then
            self:_setStatus('UGC 怪物刷怪失败：没有可用的安全房间。')
            continue
        end

        local ugcMonsterService = self.MonsterServiceFactory(runtimeProfile, function()
            return self.RunTracker:getState() == 'Expedition'
        end, function(player)
            return self.RunTracker:isPlayerActive(player.UserId)
        end, function(fromPosition, toPosition)
            if not self.World or not self.World.CanTraverseBetweenPositions then
                return true
            end

            return self.World.CanTraverseBetweenPositions(fromPosition, toPosition)
        end, self:_buildMonsterRuntimeOptions(randomSeed))
        ugcMonsterService:spawn(patrolPoints, initialPatrolIndex)

        table.insert(self.UgcMonsterServices, {
            OwnerUserId = payload.OwnerUserId,
            SpawnRoomId = spawnRoomId,
            Service = ugcMonsterService,
            RuntimeProfileId = runtimeProfile.Id,
        })
    end
end

function MazeSessionService.new(options)
    local runtimeOptions = options or {}
    local self = setmetatable({}, MazeSessionService)

    self.SessionData = {
        Seed = SessionConfig.DefaultSeed,
        Quota = SessionConfig.DefaultQuota,
        RunDurationSeconds = SessionConfig.DefaultRunDurationSeconds,
        InventoryCapacity = SessionConfig.InventoryCapacity,
    }
    self.Remotes = Remotes
    self.CampSession = CampMazeSessionContract.newCampSession({
        MazeAccessCode = 'local-debug-maze',
        MazeStatus = CampMazeSessionContract.MazeStatus.Active,
    })
    self.Status = 'Direct boot: maze session is live. Explore, loot, and find an extraction point.'
    self.World = nil
    self.WorldInteractions = nil
    self.IsDirectBoot = true
    self.IsLaunched = false
    self.SnapshotThread = nil
    self.CampSessionLock = false
    self.DiagnosticSequence = 0
    self.HasAcceptedTeleportData = false
    self.HasAcceptedTeleportDataBeforeBuild = false
    self.HasAuthoritativeSessionSeed = false
    self.SessionSeedRandom = nil
    self.LastAcceptedTeleportData = nil
    self.WorldBuildMetadata = nil
    self.RunTracker = Gameplay.Session.MazeRunTracker.new()
    self.InventoryService = InventoryService.new(self.SessionData.InventoryCapacity)
    self.ControlStateService = ControlStateService.new()
    self.PlayerService = PlayerService.new()
    self.PlayerStateService = PlayerStateService.new()
    self.MazeToRunTransition = runtimeOptions.MazeToRunTransition or MazeToRunTransition.new()
    self.MonsterServiceFactory = runtimeOptions.MonsterServiceFactory
        or function(
            monsterRuntimeProfile,
            isExpeditionActiveCallback,
            canTargetPlayerCallback,
            canTraverseCallback,
            monsterRuntimeOptions
        )
            return MonsterService.new(
                monsterRuntimeProfile,
                isExpeditionActiveCallback,
                canTargetPlayerCallback,
                canTraverseCallback,
                monsterRuntimeOptions
            )
        end
    self.MonsterService = self.MonsterServiceFactory(
        buildMazeMonsterRuntimeProfile(Gameplay.Config.Monsters[1]),
        function()
            return self.RunTracker:getState() == 'Expedition'
        end,
        function(player)
            return self.RunTracker:isPlayerActive(player.UserId)
        end,
        function(fromPosition, toPosition)
            if not self.World or not self.World.CanTraverseBetweenPositions then
                return true
            end

            return self.World.CanTraverseBetweenPositions(fromPosition, toPosition)
        end,
        self:_buildMonsterRuntimeOptions(self.SessionData.Seed)
    )
    self.UgcMonsterServices = {}
    self.PendingUgcMonsterPayloads = {}
    self.CorpsesByUserId = {}
    self.BootPhase = 'New'
    self.SurfacePalette = Shared.Runtime.MazeLightingProfile.SurfacePalette

    self:_emitDiagnostic('InitDefaultState', {
        InitialIsDirectBoot = self.IsDirectBoot,
        InitialMazeAccessCode = self.CampSession.MazeAccessCode,
        InitialSeed = self.SessionData.Seed,
        InitialSessionId = self.CampSession.SessionId,
    })

    return self
end

function MazeSessionService:_setBootPhase(phase)
    self.BootPhase = phase
    MazeBootstrapStatus.set(phase, nil)
    print(string.format('[MazeBoot] phase=%s', phase))
end

function MazeSessionService:_setBootFailure(err)
    MazeBootstrapStatus.set(self.BootPhase, tostring(err))
    warn(
        string.format(
            '[MazeBoot] failure at phase=%s error=%s',
            tostring(self.BootPhase),
            tostring(err)
        )
    )
end

function MazeSessionService:setSurfacePalette(surfacePalette)
    if type(surfacePalette) ~= 'table' then
        return
    end

    self.SurfacePalette = surfacePalette
end
function MazeSessionService:_readTeleportData(player)
    local joinData = player:GetJoinData()
    return joinData and joinData.TeleportData
end

function MazeSessionService:_mergeTeleportData(teleportData, resetInventoryService)
    local result = {
        Accepted = false,
        AcceptedBeforeBuild = false,
        HadCampSession = false,
        HadTeleportData = type(teleportData) == 'table',
        Merged = false,
        HadPendingUgcMonster = false,
        PreviousIsDirectBoot = self.IsDirectBoot,
        PreviousMazeAccessCode = self.CampSession and self.CampSession.MazeAccessCode or nil,
        PreviousSeed = self.SessionData.Seed,
        PreviousSessionId = self.CampSession and self.CampSession.SessionId or nil,
        ResetInventoryService = resetInventoryService == true,
    }

    local function finalizeResult()
        result.ResultIsDirectBoot = self.IsDirectBoot
        result.ResultMazeAccessCode = self.CampSession and self.CampSession.MazeAccessCode or nil
        result.ResultSeed = self.SessionData.Seed
        result.ResultSessionId = self.CampSession and self.CampSession.SessionId or nil
        return result
    end

    if type(teleportData) ~= 'table' then
        return finalizeResult()
    end

    local incomingSession = teleportData.CampSession
    result.HadCampSession = type(incomingSession) == 'table'
    if type(incomingSession) ~= 'table' then
        return finalizeResult()
    end

    local nextSession, accepted =
        CampMazeSessionContract.reconcileIncomingCampSession(self.CampSession, incomingSession)
    result.Accepted = accepted == true
    if not accepted then
        return finalizeResult()
    end

    local incoming = teleportData.SessionConfig
    if type(incoming) == 'table' then
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
    end

    self.CampSession = nextSession
    self.IsDirectBoot = false
    self.Status = 'Maze session is live. Explore, loot, and find an extraction point.'
    result.AcceptedBeforeBuild = self:_markAcceptedTeleportData(teleportData)
    result.Merged = true
    local pendingUgcMonsterPayload =
        CampMazeSessionContract.findPendingUgcMonsterPayload(teleportData)
    if pendingUgcMonsterPayload ~= nil then
        result.HadPendingUgcMonster = true
        self:_queuePendingUgcMonsterPayload(pendingUgcMonsterPayload)
    end

    if resetInventoryService == true then
        self.InventoryService = InventoryService.new(self.SessionData.InventoryCapacity)
    end

    return finalizeResult()
end

function MazeSessionService:_awaitInitialTeleportData()
    local deadline = os.clock() + TELEPORT_DATA_WAIT_SECONDS
    while os.clock() < deadline do
        if self.HasAcceptedTeleportData == true then
            return true
        end
        task.wait(TELEPORT_DATA_WAIT_STEP_SECONDS)
    end

    return self.HasAcceptedTeleportData == true
end

function MazeSessionService:_ensureAuthoritativeSessionSeed()
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

function MazeSessionService:_syncMonsterDeterminismSeed()
    if self.MonsterService and self.MonsterService.setDeterministicSeed then
        self.MonsterService:setDeterministicSeed(self.SessionData.Seed)
    end
end

function MazeSessionService:_loadSessionDataFromJoin()
    local players = Players:GetPlayers()
    local sawTeleportData = false
    local sawCampSession = false
    local acceptedPlayer = nil
    local mergedResult = nil

    if #players == 0 then
        self:_emitDiagnostic('LoadSessionDataFromJoin', {
            Merged = false,
            PlayersFound = 0,
            SawCampSession = false,
            SawTeleportData = false,
        })
        return
    end

    for _, player in ipairs(players) do
        local teleportData = self:_readTeleportData(player)
        if type(teleportData) == 'table' then
            sawTeleportData = true
            if type(teleportData.CampSession) == 'table' then
                sawCampSession = true
            end
        end

        local mergeResult = self:_mergeTeleportData(teleportData, true)
        if mergeResult.Merged then
            acceptedPlayer = player
            mergedResult = mergeResult
            break
        end
    end

    self:_emitDiagnostic('LoadSessionDataFromJoin', {
        Accepted = mergedResult and mergedResult.Accepted or false,
        HasAcceptedTeleportDataBeforeBuild = self.HasAcceptedTeleportDataBeforeBuild,
        Merged = mergedResult ~= nil,
        PlayersFound = #players,
        ResultMazeAccessCode = self.CampSession.MazeAccessCode,
        ResultSeed = self.SessionData.Seed,
        ResultSessionId = self.CampSession.SessionId,
        SawCampSession = sawCampSession,
        SawTeleportData = sawTeleportData,
        SelectedPlayer = acceptedPlayer and acceptedPlayer.DisplayName or nil,
    })
end

function MazeSessionService:_handlePlayerTeleportData(player)
    local mergeResult = self:_mergeTeleportData(self:_readTeleportData(player), false)

    if
        self.IsLaunched
        and mergeResult.Merged
        and mergeResult.PreviousSeed ~= mergeResult.ResultSeed
        and self.WorldBuildMetadata
        and self.WorldBuildMetadata.Source == WORLD_BUILD_SOURCE.JoinDataMergedAfterBuild
        and #Players:GetPlayers() <= 1
    then
        self:_emitDiagnostic('LateJoinSeedRebuild', {
            PreviousSeed = mergeResult.PreviousSeed,
            ResultSeed = mergeResult.ResultSeed,
        })
        self:_rebuildWorld()
    end

    self:_emitDiagnostic('PlayerAddedTeleportData', {
        Accepted = mergeResult.Accepted,
        AcceptedBeforeBuild = mergeResult.AcceptedBeforeBuild,
        HadCampSession = mergeResult.HadCampSession,
        HadPendingUgcMonster = mergeResult.HadPendingUgcMonster,
        HadTeleportData = mergeResult.HadTeleportData,
        Merged = mergeResult.Merged,
        Player = player.DisplayName,
        PreviousIsDirectBoot = mergeResult.PreviousIsDirectBoot,
        PreviousSeed = mergeResult.PreviousSeed,
        PreviousSessionId = mergeResult.PreviousSessionId,
        ResultIsDirectBoot = mergeResult.ResultIsDirectBoot,
        ResultMazeAccessCode = mergeResult.ResultMazeAccessCode,
        ResultSeed = mergeResult.ResultSeed,
        ResultSessionId = mergeResult.ResultSessionId,
        WorldBuildSource = self.WorldBuildMetadata and self.WorldBuildMetadata.Source or nil,
    })

    if self.IsLaunched then
        self:_spawnQueuedUgcMonsters()
    end
end

function MazeSessionService:_hydratePlayerInventory(player, teleportData)
    return TeleportInventoryHydrator.hydratePlayerInventory(
        self.InventoryService,
        player,
        teleportData,
        CampMazeSessionContract.findPlayerInventory
    )
end

function MazeSessionService:_addPlayerState(player)
    local added = self.RunTracker:addPlayer({
        UserId = player.UserId,
        Name = player.DisplayName,
    })

    if not added then
        return
    end

    self.InventoryService:addPlayer(player)
    self.CampSession = CampMazeSessionContract.markPlayerEntered(self.CampSession, {
        UserId = player.UserId,
        Name = player.DisplayName,
    })
    self.ControlStateService:addPlayer(player)
    self.PlayerService:addPlayer(player)
    self.PlayerStateService:addPlayer(player)
end

function MazeSessionService:_removePlayerState(player)
    self.RunTracker:removePlayer(player.UserId)
    self.InventoryService:removePlayer(player)
    self.CampSession = CampMazeSessionContract.prunePlayer(self.CampSession, player.UserId, {
        PreserveReturnSummary = true,
    })
    self.ControlStateService:removePlayer(player)
    self.PlayerService:removePlayer(player)
    self.PlayerStateService:removePlayer(player)
end

function MazeSessionService:_getMovementSummaryFor(player)
    local playerState = self.PlayerService:getSummary(player)
    local controlState = self.ControlStateService:getSummary(player)
    return FormalLocomotion.summarize(playerState, controlState)
end

function MazeSessionService:_applyMovementMode(player)
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass('Humanoid')
    if not humanoid then
        return
    end

    FormalLocomotion.applyToHumanoid(humanoid, self:_getMovementSummaryFor(player))
end

function MazeSessionService:_syncPlayerMovement(player)
    local playerState = self.PlayerService:getSummary(player)
    local ok, controlState = self.ControlStateService:syncPlayerState(player, playerState)
    if ok and controlState then
        self.PlayerService:setSprinting(player, controlState.Mode == FormalLocomotion.Mode.Sprint)
    end

    self:_applyMovementMode(player)
end

function MazeSessionService:_clearPlayerMovement(player)
    self.ControlStateService:requestSprintStop(player)
    self.PlayerService:setSprinting(player, false)
    self:_applyMovementMode(player)
end

function MazeSessionService:_getMazeStatus()
    if self.RunTracker.IsCompleted then
        return CampMazeSessionContract.MazeStatus.Completed
    end

    return CampMazeSessionContract.MazeStatus.Active
end

function MazeSessionService:_buildRoster()
    local roster = {}

    for _, player in ipairs(Players:GetPlayers()) do
        table.insert(roster, {
            Name = player.DisplayName,
            UserId = player.UserId,
            InMaze = self.RunTracker:isPlayerActive(player.UserId),
        })
    end

    table.sort(roster, function(left, right)
        return left.Name < right.Name
    end)

    return roster
end

function MazeSessionService:_getPlayerArea(player)
    if not self.IsLaunched or not self.World then
        return 'Maze Staging'
    end

    local character = player.Character
    local rootPart = character and character:FindFirstChild('HumanoidRootPart')
    if not rootPart then
        return 'Maze Staging'
    end

    local room = self.World:findRoomByPosition(rootPart.Position)
    if not room then
        return 'Maze Staging'
    end

    return string.format('%s Room', room.Kind)
end

function MazeSessionService:_getObjectiveFor()
    if self.RunTracker.IsCompleted then
        return 'The maze run is complete. Review the returned summaries back in camp.'
    end

    return 'Collect loot, avoid the monster, and use a return marker to head back to the run maze gate.'
end

function MazeSessionService:_broadcastSnapshot()
    if not self.IsLaunched then
        return
    end

    local roster = self:_buildRoster()
    local returnedSummaries = mergeSummaries(
        self.CampSession.ReturnedPlayerSummaries,
        self.RunTracker:getReturnedSummaries()
    )
    local mazeStatus = self:_getMazeStatus()
    local worldBuildFields = self:_getWorldBuildMetadataFields()

    for _, player in ipairs(Players:GetPlayers()) do
        self.Remotes.MazeState:FireClient(player, {
            IsLaunched = true,
            Status = self.Status,
            Area = self:_getPlayerArea(player),
            Objective = self:_getObjectiveFor(),
            State = self.RunTracker:getState(),
            Inventory = self.InventoryService:getSummary(player),
            Movement = self:_getMovementSummaryFor(player),
            ControlState = self.ControlStateService:getSummary(player),
            PlayerState = self.PlayerService:getSummary(player).PlayerState,
            Roster = roster,
            SessionId = self.CampSession.SessionId,
            MazeAccessCode = self.CampSession.MazeAccessCode,
            MazeStatus = mazeStatus,
            ReturnedPlayerSummaries = returnedSummaries,
            IsDirectBoot = self.IsDirectBoot,
            WorldBuildSeed = worldBuildFields.WorldBuildSeed,
            WorldBuildSessionId = worldBuildFields.WorldBuildSessionId,
            WorldBuildMazeAccessCode = worldBuildFields.WorldBuildMazeAccessCode,
            WorldBuildIsDirectBoot = worldBuildFields.WorldBuildIsDirectBoot,
            WorldBuildSource = worldBuildFields.WorldBuildSource,
        })

        self.Remotes.MazePrivateState:FireClient(player, nil)
    end
end

function MazeSessionService:_setStatus(status)
    self.Status = status
    print(string.format('[Maze] %s', status))
    self:_broadcastSnapshot()
end

function MazeSessionService:_rebuildWorld()
    self:_setBootPhase('RebuildWorld')
    local shouldRespawnMonster = self.IsLaunched and self.RunTracker:getState() == 'Expedition'
    if shouldRespawnMonster then
        self.MonsterService:destroy()
    end

    clearDefaultWorkspaceShell()

    if self.WorldInteractions then
        self.WorldInteractions:disconnectAll()
        self.WorldInteractions = nil
    end

    self.World = MazeWorldBuilder.build()
    self:_recordWorldBuildMetadata()
    self:_setBootPhase('BindWorldInteractions')
    self.WorldInteractions = self.World:bindInteractions({
        OnReturnHold = function(player)
            self:_returnPlayerToRunEntrance(player, 'early_return')
        end,
        OnExtraction = function(player, extractionNodeId)
            self:_returnPlayerToRunEntrance(player, 'extracted', extractionNodeId)
        end,
        OnLoot = function(player, roomId)
            self:_pickupLoot(player, roomId)
        end,
        OnDoor = function(player, doorwayId)
            self:_toggleDoor(player, doorwayId)
        end,
    })

    if shouldRespawnMonster then
        local patrolPoints, initialPatrolIndex = self.World:getPatrolPoints()
        self.MonsterService:spawn(patrolPoints, initialPatrolIndex)
    end
end

function MazeSessionService:_toggleDoor(player, doorwayId)
    if not self.World then
        return
    end

    local toggled = self.World:toggleDoor(doorwayId)
    if not toggled then
        return
    end

    local doorway = self.World:getDoor(doorwayId)
    if doorway then
        local stateText = doorway.IsOpen and 'opened' or 'closed'
        self:_setStatus(
            string.format('%s %s a concrete double door.', player.DisplayName, stateText)
        )
    end
end

function MazeSessionService:_buildSummaryFor(player, returnReason, wasSettled)
    local inventorySummary = self.InventoryService:getSummary(player)

    return CampMazeSessionContract.buildReturnSummary({
        UserId = player.UserId,
        Name = player.DisplayName,
        ReturnReason = returnReason,
        Value = inventorySummary.Value,
        ItemCount = inventorySummary.Count,
        Weight = inventorySummary.Weight,
        WasExtracted = returnReason == 'extracted' or returnReason == 'settled',
        WasSettled = wasSettled == true,
    })
end

function MazeSessionService:_buildPlayerInventories(players)
    local playerInventories = {}

    for _, player in ipairs(players) do
        table.insert(playerInventories, {
            UserId = player.UserId,
            Inventory = self.InventoryService:getSummary(player),
        })
    end

    table.sort(playerInventories, function(left, right)
        return left.UserId < right.UserId
    end)

    return playerInventories
end

function MazeSessionService:_canReturnToCamp()
    return SessionConfig.PlaceIds.Run ~= 0 and self.CampSession.CampAccessCode ~= 'local-debug-camp'
end

function MazeSessionService:_teleportToCamp(players, summaries, mazeCompleted)
    return runWithCampSessionLock(self, function()
        if not self:_canReturnToCamp() then
            self:_setStatus(
                'Camp return is unavailable in direct boot. Set SessionConfig.PlaceIds.Run and enter from camp.'
            )
            return false
        end

        -- Teleports yield, so keep the camp-side handoff serialized per maze server.
        local mergedSummaries = mergeSummaries(self.RunTracker:getReturnedSummaries(), summaries)
        local result = self.MazeToRunTransition:returnPlayers({
            Players = players,
            SessionConfig = self.SessionData,
            CampSession = self.CampSession,
            Summaries = mergedSummaries,
            MazeCompleted = mazeCompleted,
            PlayerInventories = self:_buildPlayerInventories(players),
        })
        if not result.Ok then
            self:_setStatus(string.format('Camp return failed: %s', tostring(result.Reason)))
            return false
        end

        self.CampSession = result.NextCampSession
        return true
    end)
end

function MazeSessionService:_beginFormalExpedition()
    self:_setBootPhase('BeginFormalExpedition')
    local started, reason = self.RunTracker:beginExpedition()
    if not started then
        if reason ~= 'InvalidState' then
            self:_setStatus(string.format('Maze session could not start: %s', tostring(reason)))
        end
        return
    end

    local patrolPoints, initialPatrolIndex = self.World:getPatrolPoints()
    self:_setBootPhase('SpawnMonster')
    self.MonsterService:spawn(patrolPoints, initialPatrolIndex)
    self:_spawnQueuedUgcMonsters()
    self:_setStatus('Maze session is live. Explore, loot, and find an extraction point.')
end

function MazeSessionService:_canManageInventory(player)
    if not self.RunTracker:isPlayerActive(player.UserId) then
        self:_setStatus(
            string.format(
                '%s already returned and cannot change inventory state.',
                player.DisplayName
            )
        )
        return false
    end

    return true
end

function MazeSessionService:_setPlayerSprinting(player, isSprinting)
    if not self.RunTracker:isPlayerActive(player.UserId) then
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

function MazeSessionService:_equipItem(player, itemInstanceId)
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

    self:_setStatus(string.format('%s equipped %s.', player.DisplayName, result.Name))
end

function MazeSessionService:_unequipItem(player)
    if not self:_canManageInventory(player) then
        return
    end

    local success, result = self.InventoryService:unequip(player)
    if not success then
        self:_setStatus(
            string.format(
                '%s could not unequip the held item (%s).',
                player.DisplayName,
                tostring(result)
            )
        )
        return
    end

    self:_setStatus(
        string.format('%s stowed %s back into the backpack.', player.DisplayName, result.Name)
    )
end

-- === 新增：处理道具使用的逻辑（这是本次手术最核心的部位） ===
function MazeSessionService:_handleUseTool(player)
    if not self:_canManageInventory(player) then
        return
    end

    local playerState = self.PlayerService:getSummary(player).PlayerState
    if playerState.IsDead == true then
        self:_setStatus(string.format('%s cannot use tools while dead.', player.DisplayName))
        return
    end

    -- 1. 检查手里有没有拿东西
    local inventorySummary = self.InventoryService:getSummary(player)
    local heldItem = inventorySummary and inventorySummary.HeldItem

    if not heldItem then
        self:_setStatus(
            string.format('%s tried to use a tool, but hands are empty.', player.DisplayName)
        )
        return
    end

    -- 2. 检查这东西有没有“状态/耐久”（ConsumePerUse 允许为 0 表示不消耗型工具）
    if type(heldItem.CurrentState) ~= 'number' or type(heldItem.ConsumePerUse) ~= 'number' then
        self:_setStatus(
            string.format(
                '%s cannot actively "use" %s (it is not a tool).',
                player.DisplayName,
                heldItem.Name
            )
        )
        return
    end

    -- 3. 检查有没有没电/报废（仅当每次使用会扣耐久时）
    if heldItem.ConsumePerUse > 0 and heldItem.CurrentState < heldItem.ConsumePerUse then
        self:_setStatus(
            string.format(
                '%s tried to use %s, but it has no %s left.',
                player.DisplayName,
                heldItem.Name,
                heldItem.StateModel or 'power'
            )
        )
        return
    end

    -- 4. 真正“使用”它：扣除耐久并同步到实际背包状态
    local consumeSuccess, consumeResult, cooldownRemaining =
        self.InventoryService:consumeHeldItemState(player, os.clock())
    if not consumeSuccess then
        if consumeResult == 'Cooldown' then
            self:_setStatus(
                string.format(
                    '%s cannot use %s yet (cooldown %.1fs remaining).',
                    player.DisplayName,
                    heldItem.Name,
                    math.max(cooldownRemaining or 0, 0)
                )
            )
        else
            self:_setStatus(
                string.format(
                    '%s could not use %s (%s).',
                    player.DisplayName,
                    heldItem.Name,
                    tostring(consumeResult)
                )
            )
        end
        return
    end

    local updatedHeldItem = consumeResult

    local actionWord = 'used'
    local effectText = 'It worked!'

    if updatedHeldItem.ToolCategory == 'Flashlight' then
        actionWord = 'flashed'
        effectText = 'The area is illuminated.'
    elseif updatedHeldItem.ToolCategory == 'Crowbar' then
        actionWord = 'swung'
        effectText = 'A satisfying swoosh cuts the air!'

        local damagePips = 1
        if type(updatedHeldItem.MeleeDamage) == 'number' and updatedHeldItem.MeleeDamage >= 1 then
            damagePips = math.floor(updatedHeldItem.MeleeDamage)
        end

        local meleeOk, meleeResult = self.MonsterService:tryApplyPlayerMeleeHit(player, {
            DamagePips = damagePips,
            SwingArcDegrees = updatedHeldItem.SwingArcDegrees,
            SwingRange = updatedHeldItem.SwingRange,
        })
        if meleeOk then
            if meleeResult and meleeResult.Killed then
                effectText = 'The crowbar connects — the threat goes down!'
            elseif meleeResult and type(meleeResult.RemainingHitPoints) == 'number' then
                effectText = string.format(
                    'The crowbar connects! Foe stamina: ~%d.',
                    meleeResult.RemainingHitPoints
                )
            end
        end
    elseif updatedHeldItem.ToolCategory == 'Potion' then
        actionWord = 'drank'
        local healPips = 1
        local healOk, healResult = self.PlayerService:healHealthPips(player, healPips)
        if healOk then
            effectText = string.format('The brew steadies you — health pips: %d.', healResult)
        else
            effectText = string.format('The brew has no effect (%s).', tostring(healResult))
        end
    end

    self:_setStatus(
        string.format(
            '%s %s the %s. %s (%s remaining: %d)',
            player.DisplayName,
            actionWord,
            updatedHeldItem.Name,
            effectText,
            updatedHeldItem.StateModel or 'state',
            updatedHeldItem.CurrentState
        )
    )
end
-- =======================================================

function MazeSessionService:_spawnCorpseForPlayer(player)
    if self.CorpsesByUserId[player.UserId] or not self.World or not self.World.Root then
        return
    end

    local character = player.Character
    local rootPart = character and character:FindFirstChild('HumanoidRootPart')
    local corpsePosition = rootPart and rootPart.Position or self.World.ReturnHoldCFrame.Position

    local corpse = Instance.new('Part')
    corpse.Name = string.format('Corpse_%d', player.UserId)
    corpse.Anchored = true
    corpse.Size = CORPSE_SIZE
    corpse.CFrame = CFrame.new(corpsePosition + Vector3.new(0, CORPSE_VERTICAL_OFFSET, 0))
    corpse.Color = CORPSE_COLOR
    corpse.Material = CORPSE_MATERIAL
    corpse.Parent = self.World.Root

    self.CorpsesByUserId[player.UserId] = corpse
end

function MazeSessionService:_completeExpeditionIfNoActivePlayers()
    if self.RunTracker:getActiveCount() ~= 0 then
        return false
    end

    local completed, reason = self.RunTracker:completeExpedition()
    if not completed then
        return nil, reason
    end

    self.MonsterService:destroy()
    self:_destroyUgcMonsters()
    table.clear(self.PendingUgcMonsterPayloads)
    return true
end

function MazeSessionService:_handlePlayerDeath(player, damageKind)
    self:_spawnCorpseForPlayer(player)
    self:_syncPlayerMovement(player)

    local summary = self:_buildSummaryFor(player, 'death', false)
    local recorded = self.RunTracker:recordReturn(summary)
    if not recorded then
        return
    end

    local mazeCompleted, completionReason = self:_completeExpeditionIfNoActivePlayers()
    if mazeCompleted == nil then
        self:_setStatus(string.format('Maze completion failed: %s', tostring(completionReason)))
        return
    end

    if self:_teleportToCamp({ player }, { summary }, mazeCompleted) then
        self:_setStatus(
            string.format(
                '%s took %s damage and was returned to camp.',
                player.DisplayName,
                string.lower(damageKind)
            )
        )
        return
    end

    local character = player.Character
    if character and character.Parent and self.World then
        character:PivotTo(self.World.ReturnHoldCFrame)
    end

    self:_setStatus(
        string.format(
            '%s took %s damage and died, leaving a corpse behind.',
            player.DisplayName,
            string.lower(damageKind)
        )
    )
end

function MazeSessionService:_applyPlayerDamage(player, damageKind)
    if not self.RunTracker:isPlayerActive(player.UserId) then
        return
    end

    local success, result = self.PlayerService:applyDamage(player, damageKind)
    if not success then
        self:_setStatus(
            string.format('%s could not take damage (%s).', player.DisplayName, tostring(result))
        )
        return
    end

    local summary = self.PlayerService:getSummary(player)
    if not summary then
        self:_setStatus(string.format('%s summary unavailable after damage.', player.DisplayName))
        return
    end

    if summary.Health.IsDead then
        self:_handlePlayerDeath(player, damageKind)
        return
    end

    self:_syncPlayerMovement(player)

    self:_setStatus(
        string.format(
            '%s took %s damage and now has %d/%d health pips.',
            player.DisplayName,
            string.lower(damageKind),
            summary.Health.CurrentHealthPips,
            summary.Health.MaxHealthPips
        )
    )
end

function MazeSessionService:_pickupLoot(player, roomId)
    if self.RunTracker:getState() ~= 'Expedition' then
        self:_setStatus('Loot can only be collected during the expedition phase.')
        return
    end

    if not self.RunTracker:isPlayerActive(player.UserId) then
        self:_setStatus(
            string.format(
                '%s has already returned and cannot collect more loot.',
                player.DisplayName
            )
        )
        return
    end

    local lootEntry = self.World:getLootNode(roomId)
    if not lootEntry or lootEntry.Collected then
        return
    end

    local success, reason = self.InventoryService:pickup(player, lootEntry.ItemDef)
    if not success then
        self:_setStatus(
            string.format(
                '%s could not carry %s (%s).',
                player.DisplayName,
                lootEntry.ItemDef.Name,
                tostring(reason)
            )
        )
        return
    end

    lootEntry:markCollected()

    local inventorySummary = self.InventoryService:getSummary(player)
    self:_setStatus(
        string.format(
            '%s collected %s. Inventory value now %d.',
            player.DisplayName,
            lootEntry.ItemDef.Name,
            inventorySummary.Value
        )
    )
end

function MazeSessionService:_returnPlayerToRunEntrance(player, returnReason, _interactionId)
    if self.RunTracker:getState() ~= 'Expedition' then
        self:_setStatus('Return markers are only available during the expedition phase.')
        return
    end

    if not self.RunTracker:isPlayerActive(player.UserId) then
        self:_setStatus(
            string.format('%s already returned to the run maze gate.', player.DisplayName)
        )
        return
    end

    local summary = self:_buildSummaryFor(player, returnReason, false)
    local recorded, reason = self.RunTracker:recordReturn(summary)
    if not recorded then
        if reason == 'MissingActivePlayer' then
            self:_setStatus(
                string.format('%s already returned to the run maze gate.', player.DisplayName)
            )
        end
        return
    end

    local mazeCompleted, completionReason = self:_completeExpeditionIfNoActivePlayers()
    if mazeCompleted == nil then
        self:_setStatus(string.format('Maze completion failed: %s', tostring(completionReason)))
        return
    end

    self:_clearPlayerMovement(player)

    if self:_teleportToCamp({ player }, { summary }, mazeCompleted) then
        self:_setStatus(
            string.format(
                '%s returned to the run maze gate with %d value (%s).',
                player.DisplayName,
                summary.Value,
                summary.ReturnReason
            )
        )
        return
    end

    local character = player.Character
    if character and character.Parent then
        character:PivotTo(self.World.ReturnHoldCFrame)
    end

    self:_setStatus(
        string.format(
            '%s reached a return marker with %d value, but the handoff back to run failed.',
            player.DisplayName,
            summary.Value
        )
    )
end

function MazeSessionService:_launchMaze()
    if self.IsLaunched then
        return
    end

    self:_setBootPhase('LaunchMaze')
    self:_emitDiagnostic('LaunchMazePreBuild', {
        HasAcceptedTeleportData = self.HasAcceptedTeleportData,
        HasAcceptedTeleportDataBeforeBuild = self.HasAcceptedTeleportDataBeforeBuild,
        IsDirectBoot = self.IsDirectBoot,
        MazeAccessCode = self.CampSession.MazeAccessCode,
        Seed = self.SessionData.Seed,
        SessionId = self.CampSession.SessionId,
    })
    self.IsLaunched = true
    Players.CharacterAutoLoads = true

    self:_rebuildWorld()
    self:_emitDiagnostic('LaunchMazePostBuild', self:_getWorldBuildMetadataFields())

    self:_setBootPhase('LoadCharacters')
    for _, player in ipairs(Players:GetPlayers()) do
        player:LoadCharacter()
    end

    self:_beginFormalExpedition()
    self:_setBootPhase('StartSnapshotLoop')
    self:_startSnapshotLoop()
    self:_setBootPhase('FirstSnapshot')
    self:_broadcastSnapshot()
    self:_setBootPhase('Launched')
end

function MazeSessionService:_getPlayerUpdateContext(player)
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass('Humanoid')
    local rootPart = humanoid and humanoid.RootPart
    local currentPosition = rootPart and rootPart.Position or Vector3.zero

    return {
        CurrentPosition = currentPosition,
        InputState = {},
    }
end

function MazeSessionService:_startSnapshotLoop()
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
                end

                self:_broadcastSnapshot()
            else
                previousTick = os.clock()
            end
        end
    end)
end

function MazeSessionService:start()
    self:_setBootPhase('Start')
    self:_loadSessionDataFromJoin()
    self:_setBootPhase('ConfigureCharacterLoading')
    Players.CharacterAutoLoads = false

    self:_setBootPhase('BindExistingPlayers')
    for _, player in ipairs(Players:GetPlayers()) do
        bindCharacterTeleport(self, player)
        self:_addPlayerState(player)
        self:_hydratePlayerInventory(player, self:_readTeleportData(player))

        if player.Character then
            player.Character:Destroy()
        end
    end

    self:_setBootPhase('BindPlayerSignals')
    Players.PlayerAdded:Connect(function(player)
        self:_handlePlayerTeleportData(player)
        bindCharacterTeleport(self, player)
        self:_addPlayerState(player)
        self:_hydratePlayerInventory(player, self:_readTeleportData(player))

        if self.IsLaunched then
            player:LoadCharacter()
            self:_setStatus(string.format('%s joined the shared maze session.', player.DisplayName))
            return
        end

        self:_broadcastSnapshot()
    end)

    Players.PlayerRemoving:Connect(function(player)
        self:_removePlayerState(player)
        self:_broadcastSnapshot()
    end)

    self:_setBootPhase('BindMazeActionRemote')
    self.Remotes.MazeAction.OnServerEvent:Connect(function(player, payload)
        if type(payload) ~= 'table' then
            return
        end

        if payload.Type == 'RequestEquipItem' then
            self:_equipItem(player, payload.ItemInstanceId)
        elseif payload.Type == 'RequestUnequipItem' then
            self:_unequipItem(player)
        elseif payload.Type == 'RequestSprintStart' then
            self:_setPlayerSprinting(player, true)
        elseif payload.Type == 'RequestSprintStop' then
            self:_setPlayerSprinting(player, false)

        -- === 新增：监听客户端喊出的那声“我要用道具！” ===
        elseif payload.Type == 'RequestUseTool' then
            self:_handleUseTool(player)
        -- =================================================
        elseif RunService:IsStudio() and DEBUG_DAMAGE_BY_ACTION[payload.Type] then
            self:_applyPlayerDamage(player, DEBUG_DAMAGE_BY_ACTION[payload.Type])
        end
    end)

    self:_setBootPhase('BeforeLaunchMaze')
    task.defer(function()
        local ok, err = pcall(function()
            self:_setBootPhase('AwaitInitialTeleportData')
            local mergedBeforeBuild = self:_awaitInitialTeleportData()
            self:_setBootPhase('EnsureAuthoritativeSeed')
            self:_ensureAuthoritativeSessionSeed()
            self:_syncMonsterDeterminismSeed()
            self:_emitDiagnostic('InitialSeedResolution', {
                HasAcceptedTeleportData = self.HasAcceptedTeleportData,
                HasAuthoritativeSessionSeed = self.HasAuthoritativeSessionSeed,
                MergedBeforeBuild = mergedBeforeBuild,
                Seed = self.SessionData.Seed,
            })
            self:_setBootPhase('DeferredLaunchMaze')
            self:_launchMaze()
        end)

        if not ok then
            self:_setBootFailure(err)
        end
    end)
end

return MazeSessionService
