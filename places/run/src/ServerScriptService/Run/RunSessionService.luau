local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService('RunService')
local ServerStorage = game:GetService('ServerStorage')
local Workspace = game:GetService('Workspace')

local Packages = ReplicatedStorage:WaitForChild('Packages')
local Shared = require(Packages:WaitForChild('Shared'))
local Gameplay = require(Packages:WaitForChild('Gameplay'))

local SessionConfig = Shared.Config.SessionConfig
local Remotes = Shared.Network.Remotes.ensureScope(Shared.Network.Remotes.Scope.Run)
local CampMazeSessionContract = Shared.Session.CampMazeSessionContract
local MazeEntryAvailability = Shared.Session.MazeEntryAvailability
local SessionSeedPolicy = Shared.Session.SessionSeedPolicy
local ControlStateService = Shared.Runtime.ControlStateService
local FormalLocomotion = Shared.Runtime.FormalLocomotion
local InventoryService = Shared.Runtime.InventoryService
local PlayerStateService = Shared.Runtime.PlayerStateService
local TeleportInventoryHydrator = Shared.Runtime.TeleportInventoryHydrator

local LocalDebugMazeWorldBuilder = require(script.Parent.LocalDebugMazeWorldBuilder)
local MonsterBriefGateway = require(script.Parent.MonsterBriefGateway)
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
local UGC_GENERATION_TOKEN_ITEM_ID = 'ugc-gen-token'
local UGC_GENERATION_DEFAULT_SEED_MAX = 2147483646
local UGC_LOCAL_GATEWAY_CONFIG_MODULE_NAME = 'MonsterBriefGatewayLocalConfig'
local RUN_MAZE_GATE_RETURN_REASONS = table.freeze({
    early_return = true,
    extracted = true,
})
local UGC_STATUS = table.freeze({
    Idle = 'Idle',
    Generating = 'Generating',
    Ready = 'Ready',
    Rejected = 'Rejected',
})

local ITEM_DEFINITION_BY_ID = {}
for _, itemDef in ipairs(Gameplay.Config.Items) do
    ITEM_DEFINITION_BY_ID[itemDef.Id] = itemDef
end

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

local function buildPlayerContext(player)
    return {
        UserId = player.UserId,
        Name = player.DisplayName,
    }
end

local function trimText(value)
    if type(value) ~= 'string' then
        return ''
    end

    return string.match(value, '^%s*(.-)%s*$') or ''
end

local function buildUgcReadyPayload(generationResult, ownerUserId)
    local recipe = generationResult.Recipe
    local runtimeProfile = generationResult.RuntimeProfile
    local diagnostics = generationResult.Diagnostics

    return {
        OwnerUserId = ownerUserId,
        MonsterId = recipe.Id,
        MonsterName = recipe.Name,
        Seed = generationResult.Seed,
        RecipeHash = generationResult.RecipeHash,
        RuntimeProfile = runtimeProfile,
        Diagnostics = {
            SkippedBehaviorIds = table.clone(diagnostics.SkippedBehaviorIds),
            SkippedEffectIds = table.clone(diagnostics.SkippedEffectIds),
            ClampedFields = table.clone(diagnostics.ClampedFields),
        },
    }
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
    self.HasAuthoritativeSessionSeed = false
    self.SessionSeedRandom = nil
    self.LastMazeEntryRequestAtByUserId = {}
    self.MazeEntryMode = MazeEntryAvailability.Mode.Blocked
    self.MazeEntryReason =
        'Set SessionConfig.PlaceIds.Maze or SessionPlaceIdMaze before using the maze gate.'
    self.MazeEntryReasonCode = MazeEntryAvailability.ReasonCode.MazePlaceIdMissing
    self.LocalDebugMazeWorld = nil
    self.InventoryService = InventoryService.new(self.SessionData.InventoryCapacity)
    self.ControlStateService = ControlStateService.new()
    self.PlayerStateService = PlayerStateService.new()
    self.MonsterBriefGateway = runtimeOptions.MonsterBriefGateway or MonsterBriefGateway.new()
    self.PendingUgcMonsterByUserId = {}
    self.PendingUgcConsumeByUserId = {}
    self.UgcGenerationStateByUserId = {}
    self.IssuedStarterUgcTokenByUserId = {}
    self.GenerateRandomSource = runtimeOptions.GenerateRandomSource or Random.new()

    return self
end

function RunSessionService:_addPlayerState(player)
    self.InventoryService:addPlayer(player)
    self.ControlStateService:addPlayer(player)
    self.PlayerStateService:addPlayer(player)
    self:_setUgcGenerationState(player, UGC_STATUS.Idle, '')
end

function RunSessionService:_removePlayerState(player)
    self.InventoryService:removePlayer(player)
    self.ControlStateService:removePlayer(player)
    self.PlayerStateService:removePlayer(player)
end

function RunSessionService:_setUgcGenerationState(player, status, message)
    self.UgcGenerationStateByUserId[player.UserId] = {
        Status = status,
        Message = message or '',
    }
end

function RunSessionService:_applyLocalGatewayConfigIfPresent()
    local configModule = script.Parent:FindFirstChild(UGC_LOCAL_GATEWAY_CONFIG_MODULE_NAME)
    if configModule == nil or not configModule:IsA('ModuleScript') then
        return
    end

    local ok, config = pcall(require, configModule)
    if not ok or type(config) ~= 'table' then
        warn(
            string.format(
                '[RunSessionService] Failed to load %s: %s',
                UGC_LOCAL_GATEWAY_CONFIG_MODULE_NAME,
                tostring(config)
            )
        )
        return
    end

    local providerName = string.lower(trimText(config.Provider))
    local providerConfigs = config.Providers
    local selectedProviderConfig = if type(providerConfigs) == 'table'
            and providerName ~= ''
        then providerConfigs[providerName]
        else nil

    local function resolveValue(primaryValue, fallbackValue)
        local text = trimText(primaryValue)
        if text ~= '' then
            return text
        end

        local fallbackText = trimText(fallbackValue)
        if fallbackText ~= '' then
            return fallbackText
        end

        return nil
    end

    local function setServerAttribute(attributeName, value)
        if type(value) == 'string' and value ~= '' then
            ServerStorage:SetAttribute(attributeName, value)
        end
    end

    setServerAttribute('MonsterBriefGatewayUrl', config.Endpoint)
    setServerAttribute('MonsterBriefGatewayApiKey', config.ApiKey)

    local provider =
        resolveValue(config.Provider, selectedProviderConfig and selectedProviderConfig.Provider)
    local providerApiKey =
        resolveValue(config.ApiKey, selectedProviderConfig and selectedProviderConfig.ApiKey)
    local providerBaseUrl =
        resolveValue(config.BaseUrl, selectedProviderConfig and selectedProviderConfig.BaseUrl)
    local providerModel =
        resolveValue(config.Model, selectedProviderConfig and selectedProviderConfig.Model)

    setServerAttribute('MonsterBriefLlmProvider', provider)
    setServerAttribute('MonsterBriefLlmApiKey', providerApiKey)
    setServerAttribute('MonsterBriefLlmBaseUrl', providerBaseUrl)
    setServerAttribute('MonsterBriefLlmModel', providerModel)
    setServerAttribute('MonsterBriefGatewayProtocol', config.EndpointProtocol)
    setServerAttribute('MonsterBriefGatewayModel', config.EndpointModel)
end

function RunSessionService:_getUgcGenerationState(player)
    local state = self.UgcGenerationStateByUserId[player.UserId]
    if type(state) ~= 'table' then
        return {
            Status = UGC_STATUS.Idle,
            Message = '',
        }
    end

    return state
end

function RunSessionService:_grantStarterUgcTokenIfNeeded(player, teleportData)
    if self.IssuedStarterUgcTokenByUserId[player.UserId] then
        return
    end

    if CampMazeSessionContract.findPlayerInventory(teleportData, player.UserId) ~= nil then
        self.IssuedStarterUgcTokenByUserId[player.UserId] = true
        return
    end

    local itemDef = ITEM_DEFINITION_BY_ID[UGC_GENERATION_TOKEN_ITEM_ID]
    if itemDef == nil then
        self.IssuedStarterUgcTokenByUserId[player.UserId] = true
        warn(
            string.format(
                '[RunSessionService] Missing starter token item definition for id %s.',
                UGC_GENERATION_TOKEN_ITEM_ID
            )
        )
        return
    end

    local success, reason = self.InventoryService:pickup(player, itemDef)
    if success then
        self.IssuedStarterUgcTokenByUserId[player.UserId] = true
    else
        warn(
            string.format(
                '[RunSessionService] Failed to grant starter UGC token to %s (%s).',
                player.DisplayName,
                tostring(reason)
            )
        )
    end
end

function RunSessionService:_hasUgcGenerationToken(player)
    return self.InventoryService:countByItemId(player, UGC_GENERATION_TOKEN_ITEM_ID) > 0
end

function RunSessionService:_consumeUgcGenerationToken(player)
    return self.InventoryService:consumeByItemId(player, UGC_GENERATION_TOKEN_ITEM_ID)
end

function RunSessionService:_buildAssetValidator()
    return function(assetId, assetKind)
        if assetKind == 'ModelAssetId' then
            return assetId == 4446576906, 'OnlyOfficialModelAssetAllowedInV1'
        end

        if assetKind == 'ChaseLoopSoundAssetId' then
            return assetId == 9118823108, 'OnlyOfficialSoundAssetAllowedInV1'
        end

        return false, 'UnsupportedAssetKind'
    end
end

function RunSessionService:_requestGenerateUgcMonster(player, prompt)
    if not self.IsLaunched then
        return
    end

    if type(prompt) ~= 'string' or string.match(prompt, '^%s*$') then
        self:_setUgcGenerationState(player, UGC_STATUS.Rejected, '请输入怪物需求描述。')
        self:_broadcastSnapshot()
        return
    end

    if self.PendingUgcConsumeByUserId[player.UserId] then
        return
    end

    if self.PendingUgcMonsterByUserId[player.UserId] ~= nil then
        self:_setUgcGenerationState(
            player,
            UGC_STATUS.Rejected,
            '你已有待刷新的 UGC 怪物，进入 Maze 后会自动生成。'
        )
        self:_broadcastSnapshot()
        return
    end

    if not self:_hasUgcGenerationToken(player) then
        self:_setUgcGenerationState(
            player,
            UGC_STATUS.Rejected,
            'UGC 生成道具不足。该道具只能在 Maze 内拾取。'
        )
        self:_broadcastSnapshot()
        return
    end

    self.PendingUgcConsumeByUserId[player.UserId] = true
    self:_setUgcGenerationState(player, UGC_STATUS.Generating, '正在生成怪物方案...')
    self:_broadcastSnapshot()

    local gatewayOk, gatewayResult =
        self.MonsterBriefGateway:generateBrief(prompt, buildPlayerContext(player))

    if not gatewayOk then
        warn(
            string.format(
                '[RunSessionService] UGC generation gateway failed for userId=%d code=%s message=%s',
                player.UserId,
                tostring(gatewayResult and gatewayResult.ErrorCode),
                tostring(gatewayResult and gatewayResult.Message)
            )
        )
        self.PendingUgcConsumeByUserId[player.UserId] = nil
        self:_setUgcGenerationState(
            player,
            UGC_STATUS.Rejected,
            gatewayResult and gatewayResult.Message or 'LLM 服务调用失败。'
        )
        self:_broadcastSnapshot()
        return
    end

    if gatewayResult.Status == 'NeedMoreInfo' then
        self.PendingUgcConsumeByUserId[player.UserId] = nil
        self:_setUgcGenerationState(
            player,
            UGC_STATUS.Rejected,
            gatewayResult.Question or '请补充更多信息后重试。'
        )
        self:_broadcastSnapshot()
        return
    end

    local generatedSeed = self.GenerateRandomSource:NextInteger(1, UGC_GENERATION_DEFAULT_SEED_MAX)
    local generatedOk, generationResult =
        Gameplay.Monsters.MonsterUgcPipeline.generateForSandbox(gatewayResult.Brief, {
            Seed = generatedSeed,
            PlayerUserId = player.UserId,
            AssetValidator = self:_buildAssetValidator(),
        })

    if not generatedOk then
        self.PendingUgcConsumeByUserId[player.UserId] = nil
        self:_setUgcGenerationState(
            player,
            UGC_STATUS.Rejected,
            generationResult and generationResult.Reason or '怪物方案生成失败。'
        )
        self:_broadcastSnapshot()
        return
    end

    local consumed, consumeReason = self:_consumeUgcGenerationToken(player)
    if not consumed then
        self.PendingUgcConsumeByUserId[player.UserId] = nil
        self:_setUgcGenerationState(
            player,
            UGC_STATUS.Rejected,
            string.format('生成道具扣除失败：%s', tostring(consumeReason))
        )
        self:_broadcastSnapshot()
        return
    end

    self.PendingUgcMonsterByUserId[player.UserId] =
        buildUgcReadyPayload(generationResult, player.UserId)
    self.PendingUgcConsumeByUserId[player.UserId] = nil
    self:_setUgcGenerationState(
        player,
        UGC_STATUS.Ready,
        'UGC 怪物已排队，进入 Maze 后会自动刷出。'
    )
    self:_setStatus(
        string.format('%s queued a UGC monster for the next maze entry.', player.DisplayName)
    )
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

function RunSessionService:_hydratePlayerInventory(player, teleportData)
    return TeleportInventoryHydrator.hydratePlayerInventory(
        self.InventoryService,
        player,
        teleportData,
        CampMazeSessionContract.findPlayerInventory
    )
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

    self:_applyReturnedPlayersFromTeleportData(players, acceptedTeleportData)
end

function RunSessionService:_getReturnStatusText(playerDisplayName, summary, teleportData)
    if RUN_MAZE_GATE_RETURN_REASONS[summary.ReturnReason] then
        return string.format(
            '%s returned to the maze gate with %d value (%s).',
            playerDisplayName,
            summary.Value or 0,
            summary.ReturnReason or 'unknown'
        )
    end

    if teleportData.MazeReturn and teleportData.MazeReturn.MazeCompleted == true then
        return string.format(
            '%s returned from the completed maze run with %d value.',
            playerDisplayName,
            summary.Value or 0
        )
    end

    return string.format(
        '%s returned from the maze with %d value (%s).',
        playerDisplayName,
        summary.Value or 0,
        summary.ReturnReason or 'unknown'
    )
end

function RunSessionService:_applyReturnedPlayersFromTeleportData(players, acceptedTeleportData)
    local returnedPlayers = {}
    for _, player in ipairs(players) do
        local teleportData = self:_readTeleportData(player) or acceptedTeleportData
        local returnSummary = CampMazeSessionContract.findReturnSummary(teleportData, player.UserId)
        if returnSummary then
            self.PendingSpawnByUserId[player.UserId] =
                self:_getReturnSpawnCFrameForSummary(returnSummary)
            table.insert(returnedPlayers, {
                Player = player,
                Summary = returnSummary,
                TeleportData = teleportData,
            })
        end
    end

    if #returnedPlayers == 1 then
        local returnedPlayer = returnedPlayers[1]
        self.Status = self:_getReturnStatusText(
            returnedPlayer.Player.DisplayName,
            returnedPlayer.Summary,
            returnedPlayer.TeleportData
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
    if RUN_MAZE_GATE_RETURN_REASONS[summary.ReturnReason] then
        return self.World and self.World.MazeReturnCFrame or RunWorldBuilder.MazeReturnCFrame
    end

    return self.World and self.World.ReturnCFrame or RunWorldBuilder.ReturnCFrame
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

    if self.World.UgcLabPrompt then
        self.World.UgcLabPrompt.Triggered:Connect(function(player)
            self:_openUgcLabPanel(player)
        end)
    end

    self.World.GatePrompt.Triggered:Connect(function(player)
        self:_openGate(player)
    end)

    self.World.MazePrompt.Triggered:Connect(function(player)
        if self:_canProcessMazeEntryRequest(player) then
            self:_requestMazeEntry(player, false)
        end
    end)

    -- 初始化叙事交互服务
    if self.World.StelePrompt and self.World.MirrorPrompt and self.World.StatuePrompt then
        NarrativeInteractionService.initialize(
            self.World.StelePrompt,
            self.World.MirrorPrompt,
            self.World.StatuePrompt
        )
    end
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
        local ugcState = self:_getUgcGenerationState(player)
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
            Inventory = self.InventoryService:getSummary(player),
            Movement = self:_getMovementSummaryFor(player),
            ControlState = self.ControlStateService:getSummary(player),
            PlayerState = self.PlayerStateService:getSummary(player),
            UgcGenerationStatus = ugcState.Status,
            UgcMessage = ugcState.Message,
            UgcHasPendingSpawn = self.PendingUgcMonsterByUserId[player.UserId] ~= nil,
        })

        self.Remotes.RunPrivateState:FireClient(player, nil)
    end
end

function RunSessionService:_openUgcLabPanel(player)
    if not self.IsLaunched then
        return
    end

    self.Remotes.RunPrivateState:FireClient(player, {
        Type = 'OpenUgcLabPanel',
    })
end

function RunSessionService:_canManageInventory(player)
    if not self.IsLaunched then
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

    self:_setStatus(string.format('%s equipped %s in camp.', player.DisplayName, result.Name))
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
            PlayerInventory = self.InventoryService:getSummary(player),
            EnteringPlayer = {
                UserId = player.UserId,
                Name = player.DisplayName,
            },
            EntryReason = 'maze_gate',
            PendingUgcMonsterPayload = self.PendingUgcMonsterByUserId[player.UserId],
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
        self.PendingUgcMonsterByUserId[player.UserId] = nil
        self:_setUgcGenerationState(player, UGC_STATUS.Idle, '')
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
        self:_grantStarterUgcTokenIfNeeded(player, nil)
        return
    end

    local _, accepted = self:_applyIncomingCampSession(teleportData)
    if not accepted then
        return
    end

    self:_applySessionConfig(teleportData.SessionConfig)
    self:_hydratePlayerInventory(player, teleportData)
    self:_grantStarterUgcTokenIfNeeded(player, teleportData)

    local summary = CampMazeSessionContract.findReturnSummary(teleportData, player.UserId)
    if summary then
        self.PendingSpawnByUserId[player.UserId] = self:_getReturnSpawnCFrameForSummary(summary)
        self.Status = self:_getReturnStatusText(player.DisplayName, summary, teleportData)
        return
    end

    self.CampSession = CampMazeSessionContract.prunePlayer(self.CampSession, player.UserId, {
        PreserveMazeEntry = CampMazeSessionContract.isPlayerInMaze(self.CampSession, player.UserId),
    })
    self.GateOpen = self.CampSession.GateOpen
    self.Status = string.format('%s joined the camp session.', player.DisplayName)
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

function RunSessionService:start()
    self:_applyLocalGatewayConfigIfPresent()
    self:_loadSessionDataFromJoin()
    self:_ensureAuthoritativeSessionSeed()
    Players.CharacterAutoLoads = false

    for _, player in ipairs(Players:GetPlayers()) do
        bindCharacterTeleport(self, player)
        self:_addPlayerState(player)
        local teleportData = self:_readTeleportData(player)
        self:_hydratePlayerInventory(player, teleportData)
        self:_grantStarterUgcTokenIfNeeded(player, teleportData)

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
        self.PendingUgcMonsterByUserId[player.UserId] = nil
        self.PendingUgcConsumeByUserId[player.UserId] = nil
        self.UgcGenerationStateByUserId[player.UserId] = nil
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
        elseif payload.Type == 'RequestEquipItem' then
            self:_equipItem(player, payload.ItemInstanceId)
        elseif payload.Type == 'RequestUnequipItem' then
            self:_unequipItem(player)
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
        elseif payload.Type == 'RequestGenerateUgcMonster' then
            self:_requestGenerateUgcMonster(player, payload.Prompt)
        elseif payload.Type == 'RequestClearPendingUgcMonster' then
            self.PendingUgcMonsterByUserId[player.UserId] = nil
            self:_setUgcGenerationState(player, UGC_STATUS.Idle, '')
            self:_broadcastSnapshot()
        end
    end)

    self:_broadcastSnapshot()

    if self.ShouldAutoLaunch then
        self:_launchRun(nil)
    end
end

return RunSessionService
