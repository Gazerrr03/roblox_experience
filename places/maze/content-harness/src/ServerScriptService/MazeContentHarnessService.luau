local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService('RunService')
local Workspace = game:GetService('Workspace')

local DEFAULT_WORKSPACE_SHELL_NAMES = { 'Baseplate', 'SpawnLocation' }
local SNAPSHOT_INTERVAL_SECONDS = 0.25
local CORPSE_COLOR = Color3.fromRGB(92, 92, 92)
local CORPSE_MATERIAL = Enum.Material.Slate
local CORPSE_SIZE = Vector3.new(4, 1.2, 2)
local CORPSE_VERTICAL_OFFSET = -2.4
local MAZE_DIAG_PREFIX = '[MazeDiag]'

local Packages = ReplicatedStorage:WaitForChild('Packages')
local PlaceModules = ReplicatedStorage:WaitForChild('PlaceModules'):WaitForChild('Maze')
local SharedPackage = Packages:WaitForChild('Shared')
local GameplayPackage = Packages:WaitForChild('Gameplay')

local SessionConfig = require(SharedPackage:WaitForChild('Config'):WaitForChild('SessionConfig'))
local Remotes = require(SharedPackage:WaitForChild('Network'):WaitForChild('Remotes'))
local InventoryService =
    require(SharedPackage:WaitForChild('Runtime'):WaitForChild('InventoryService'))
local MonsterService = require(SharedPackage:WaitForChild('Runtime'):WaitForChild('MonsterService'))
local ControlStateService =
    require(SharedPackage:WaitForChild('Runtime'):WaitForChild('ControlStateService'))
local FormalLocomotion =
    require(SharedPackage:WaitForChild('Runtime'):WaitForChild('FormalLocomotion'))
local HeldFlashlightHeadlight =
    require(SharedPackage:WaitForChild('Runtime'):WaitForChild('HeldFlashlightHeadlight'))
local MazeLightingProfile =
    require(SharedPackage:WaitForChild('Runtime'):WaitForChild('MazeLightingProfile'))
local PlayerService = require(SharedPackage:WaitForChild('Runtime'):WaitForChild('PlayerService'))
local PlayerStateService =
    require(SharedPackage:WaitForChild('Runtime'):WaitForChild('PlayerStateService'))

local PlayerState = require(GameplayPackage:WaitForChild('PlayerState'))
local MonstersConfig = require(GameplayPackage:WaitForChild('Config'):WaitForChild('Monsters'))
local ToolItems = require(GameplayPackage:WaitForChild('Config'):WaitForChild('ToolItems'))
local MonsterCompiler =
    require(GameplayPackage:WaitForChild('Monsters'):WaitForChild('MonsterCompiler'))

local MazeBootstrapStatus = require(PlaceModules:WaitForChild('MazeBootstrapStatus'))

local MazeContentSessionState = require(script.Parent:WaitForChild('MazeContentSessionState'))
local MazeContentWorldBuilder = require(script.Parent:WaitForChild('MazeContentWorldBuilder'))

local DEBUG_DAMAGE_BY_ACTION = {
    RequestDebugLightDamage = PlayerState.DamageKind.Light,
    RequestDebugHeavyDamage = PlayerState.DamageKind.Heavy,
}
local DAMAGE_KIND_BY_PIPS = table.freeze({
    [1] = PlayerState.DamageKind.Light,
    [2] = PlayerState.DamageKind.Heavy,
})

local MazeContentHarnessService = {}
MazeContentHarnessService.__index = MazeContentHarnessService
MazeContentHarnessService.BootstrapPhaseAttribute = MazeBootstrapStatus.PhaseAttribute
MazeContentHarnessService.BootstrapErrorAttribute = MazeBootstrapStatus.ErrorAttribute
MazeContentHarnessService.BootstrapFailedAttribute = MazeBootstrapStatus.FailedAttribute

local function clearDefaultWorkspaceShell()
    for _, instanceName in ipairs(DEFAULT_WORKSPACE_SHELL_NAMES) do
        local instance = Workspace:FindFirstChild(instanceName)
        if instance then
            instance:Destroy()
        end
    end
end

local function buildMazeMonsterRuntimeProfile(monsterAuthorProfile)
    local compiledOk, runtimeProfileOrReason =
        MonsterCompiler.compileMonsterForMaze(monsterAuthorProfile)
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

local function crowbarMeleeMissText(reason)
    local code = if type(reason) == 'string' then reason else nil
    if code == 'ExpeditionInactive' then
        return '现在还没进入狩猎状态 - 迷宫主循环还没开始。'
    elseif code == 'NoMonster' then
        return '现在场上没有可命中的怪物。'
    elseif code == 'MissingMonsterPosition' then
        return '怪物位置还没稳定，稍后再试。'
    elseif code == 'OutOfRange' then
        return '这一下挥空了，靠近一点再试。'
    elseif code == 'OutOfSwingArc' then
        return '你得朝着怪物挥，才会命中。'
    elseif code == 'PathBlocked' then
        return '有障碍物挡住了这次挥击。'
    elseif code == 'BlockedLineOfSight' then
        return '你得看得到怪物，才能打中。'
    elseif code == 'InvalidFacing' then
        return '你当前朝向不对，没法挥击。'
    elseif code == 'NoCharacter' or code == 'MissingHumanoidRoot' then
        return '角色还没准备好，不能挥击。'
    elseif code == 'MonsterCombatStateMissing' then
        return '怪物现在还不能吃伤害。'
    elseif code == 'InvalidPlayer' then
        return '这次挥击没有成功生效。'
    end

    return string.format('撬棍挥空了（%s）。', tostring(reason))
end

local function formatDiagnosticValue(value)
    if value == nil then
        return 'nil'
    end

    return tostring(value)
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

local function damageKindFromPips(damagePips)
    return DAMAGE_KIND_BY_PIPS[damagePips]
end

local function localizeDamageKind(damageKind)
    local labels = {
        Light = '轻伤',
        Heavy = '重伤',
    }
    return labels[damageKind] or tostring(damageKind)
end

local function localizeReturnReason(reason)
    local labels = {
        returned = '已返回',
        death = '死亡',
        settled = '强制结算',
        timeout = '超时',
    }
    return labels[reason] or tostring(reason)
end

function MazeContentHarnessService.new(options)
    local runtimeOptions = options or {}
    local self = setmetatable({}, MazeContentHarnessService)

    self.Seed = runtimeOptions.Seed or SessionConfig.DefaultSeed
    self.SessionState = runtimeOptions.SessionState or MazeContentSessionState.new(self.Seed)
    self.Remotes = runtimeOptions.Remotes or Remotes.ensureScope(Remotes.Scope.Maze)
    self.InventoryService = runtimeOptions.InventoryService
        or InventoryService.new(SessionConfig.InventoryCapacity)
    self.ControlStateService = runtimeOptions.ControlStateService or ControlStateService.new()
    self.PlayerService = runtimeOptions.PlayerService or PlayerService.new()
    self.PlayerStateService = runtimeOptions.PlayerStateService or PlayerStateService.new()
    self.WorldBuilder = runtimeOptions.WorldBuilder or MazeContentWorldBuilder
    self.GetPlayers = runtimeOptions.GetPlayers
        or function()
            return Players:GetPlayers()
        end
    self.LoadCharacter = runtimeOptions.LoadCharacter
        or function(player)
            player:LoadCharacter()
        end
    self.Status = self.SessionState.Status
    self.World = nil
    self.WorldInteractions = nil
    self.SurfacePalette = runtimeOptions.SurfacePalette or MazeLightingProfile.SurfacePalette
    self.SnapshotThread = nil
    self.IsLaunched = false
    self.DiagnosticSequence = 0
    self.DynamicDropNodesById = {}
    self.NextDynamicDropNodeId = 1
    self.CorpsesByUserId = {}
    self.WorldBuildMetadata = nil
    self.BootPhase = 'New'
    self.MonsterServiceFactory = runtimeOptions.MonsterServiceFactory
        or function(
            monsterRuntimeProfile,
            isExpeditionActive,
            canTargetPlayer,
            canTraverse,
            monsterOptions
        )
            return MonsterService.new(
                monsterRuntimeProfile,
                isExpeditionActive,
                canTargetPlayer,
                canTraverse,
                monsterOptions
            )
        end

    local monsterAuthorProfile = runtimeOptions.MonsterAuthorProfile or MonstersConfig[1]
    if type(monsterAuthorProfile) ~= 'table' then
        error('迷宫内容测试场需要一个默认怪物配置。', 0)
    end

    self.MonsterService = self.MonsterServiceFactory(
        buildMazeMonsterRuntimeProfile(monsterAuthorProfile),
        function()
            return self.SessionState.LoopState == 'Expedition'
        end,
        function(player)
            return self.SessionState:isPlayerActive(player.UserId)
        end,
        function(fromPosition, toPosition)
            if not self.World or not self.World.CanTraverseBetweenPositions then
                return true
            end

            return self.World.CanTraverseBetweenPositions(fromPosition, toPosition)
        end,
        self:_buildMonsterRuntimeOptions(self.Seed)
    )

    self:_emitDiagnostic('InitDefaultState', {
        InitialIsDirectBoot = self.SessionState.IsDirectBoot,
        InitialMazeAccessCode = self.SessionState.MazeAccessCode,
        InitialSeed = self.Seed,
        InitialSessionId = self.SessionState.SessionId,
    })

    return self
end

function MazeContentHarnessService:_emitDiagnostic(event, fields)
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

function MazeContentHarnessService:_setBootPhase(phase)
    self.BootPhase = phase
    MazeBootstrapStatus.set(phase, nil)
    print(string.format('[MazeBoot] phase=%s', phase))
end

function MazeContentHarnessService:_setBootFailure(err)
    MazeBootstrapStatus.set(self.BootPhase, tostring(err))
    warn(
        string.format(
            '[MazeBoot] failure at phase=%s error=%s',
            tostring(self.BootPhase),
            tostring(err)
        )
    )
end

function MazeContentHarnessService:setSurfacePalette(surfacePalette)
    if type(surfacePalette) ~= 'table' then
        return
    end

    self.SurfacePalette = surfacePalette
end

function MazeContentHarnessService:_buildMonsterRuntimeOptions(randomSeed)
    return {
        RandomSeed = randomSeed,
        OnAttackHit = function(player, damagePips, hitContext)
            local damageKind = damageKindFromPips(damagePips)
            if damageKind == nil then
                return
            end

            self:_applyPlayerDamage(player, damageKind)
            if hitContext and hitContext.Effects then
                for _, effect in ipairs(hitContext.Effects) do
                    self.PlayerStateService:applyEffect(player, effect.Id, effect.DurationSeconds)
                end
            end
        end,
    }
end

function MazeContentHarnessService:_getPersistentWorldState()
    return self.SessionState:getPersistentWorldState()
end

function MazeContentHarnessService:_setPersistentWorldState(state)
    self.SessionState:setPersistentWorldState(state)
end

function MazeContentHarnessService:_replaceDropNodeState(nextDropNodes)
    local state = self:_getPersistentWorldState()
    state.DropNodes = nextDropNodes
    self:_setPersistentWorldState(state)
end

function MazeContentHarnessService:_markLootCollected(roomId)
    local state = self:_getPersistentWorldState()
    local collectedLootRoomIds = state.CollectedLootRoomIds or {}

    for _, collectedRoomId in ipairs(collectedLootRoomIds) do
        if collectedRoomId == roomId then
            return
        end
    end

    table.insert(collectedLootRoomIds, roomId)
    table.sort(collectedLootRoomIds)
    state.CollectedLootRoomIds = collectedLootRoomIds
    self:_setPersistentWorldState(state)
end

function MazeContentHarnessService:_reserveDynamicDropNodeId()
    local nextId = self.NextDynamicDropNodeId or 1
    local state = self:_getPersistentWorldState()

    for _, dropNodeState in ipairs(state.DropNodes or {}) do
        local existingId =
            tonumber(string.match(tostring(dropNodeState.DropNodeId or ''), '^DynamicDrop_(%d+)$'))
        if existingId ~= nil and existingId >= nextId then
            nextId = existingId + 1
        end
    end

    self.NextDynamicDropNodeId = nextId + 1
    return string.format('DynamicDrop_%d', nextId)
end

function MazeContentHarnessService:_destroyDynamicDropNode(dropNodeId)
    local dynamicNode = self.DynamicDropNodesById[dropNodeId]
    if dynamicNode == nil then
        return
    end

    if dynamicNode.Connection and dynamicNode.Connection.Disconnect then
        dynamicNode.Connection:Disconnect()
    end
    if dynamicNode.Part and dynamicNode.Part.Parent then
        dynamicNode.Part:Destroy()
    end
    self.DynamicDropNodesById[dropNodeId] = nil
end

function MazeContentHarnessService:_destroyDynamicDropNodes()
    for dropNodeId in pairs(self.DynamicDropNodesById) do
        self:_destroyDynamicDropNode(dropNodeId)
    end
end

function MazeContentHarnessService:_dropNodePositionToVector3(position)
    if typeof(position) == 'Vector3' then
        return position
    end

    if type(position) == 'table' then
        return Vector3.new(
            position.X or position[1] or 0,
            position.Y or position[2] or 0,
            position.Z or position[3] or 0
        )
    end

    return self.World and self.World.ReturnHoldCFrame.Position or Vector3.zero
end

function MazeContentHarnessService:_buildDropNodePart(dropNodeState)
    local position = self:_dropNodePositionToVector3(dropNodeState.Position)
    local part = Instance.new('Part')
    part.Name = dropNodeState.DropNodeId
    part.Anchored = true
    part.CanCollide = false
    part.Transparency = 0.15
    part.Material = Enum.Material.Metal
    part.Color = Color3.fromRGB(142, 236, 255)
    part.Size = Vector3.new(2.5, 2.5, 2.5)
    part.CFrame = CFrame.new(position + Vector3.new(0, 1.5, 0))
    part.Parent = self.World.Root

    local prompt = Instance.new('ProximityPrompt')
    prompt.ActionText = 'Recover'
    prompt.ObjectText = dropNodeState.Label or 'Dropped Pack'
    prompt.MaxActivationDistance = 10
    prompt.RequiresLineOfSight = false
    prompt.Parent = part

    return part, prompt
end

function MazeContentHarnessService:_spawnDynamicDropNode(dropNodeState)
    if not (self.World and self.World.Root) then
        return
    end

    local part, prompt = self:_buildDropNodePart(dropNodeState)
    local connection = prompt.Triggered:Connect(function(player)
        self:_pickupDropNode(player, dropNodeState.DropNodeId)
    end)

    self.DynamicDropNodesById[dropNodeState.DropNodeId] = {
        Part = part,
        Connection = connection,
    }
end

function MazeContentHarnessService:_applyPersistentWorldStateToWorld()
    local state = self:_getPersistentWorldState()

    for _, roomId in ipairs(state.CollectedLootRoomIds or {}) do
        local lootNode = self.World and self.World:getLootNode(roomId)
        if lootNode and lootNode.Collected ~= true then
            lootNode:markCollected()
        end
    end

    self:_destroyDynamicDropNodes()
    for _, dropNodeState in ipairs(state.DropNodes or {}) do
        self:_spawnDynamicDropNode(dropNodeState)
    end
end

function MazeContentHarnessService:_createPersistentDropNode(entries, position, label)
    if entries == nil or #entries == 0 then
        return
    end

    local state = self:_getPersistentWorldState()
    local dropNodeId = self:_reserveDynamicDropNodeId()
    local dropNodes = state.DropNodes or {}
    table.insert(dropNodes, {
        DropNodeId = dropNodeId,
        Label = label,
        Position = {
            X = position.X,
            Y = position.Y,
            Z = position.Z,
        },
        Entries = entries,
    })
    state.DropNodes = dropNodes
    self:_setPersistentWorldState(state)
    self:_spawnDynamicDropNode(dropNodes[#dropNodes])
end

function MazeContentHarnessService:_pickupDropNode(player, dropNodeId)
    if not self.SessionState:isPlayerActive(player.UserId) then
        return
    end

    local state = self:_getPersistentWorldState()
    local nextDropNodes = {}
    local pickedCount = 0
    local pickedAny = false

    for _, dropNodeState in ipairs(state.DropNodes or {}) do
        if dropNodeState.DropNodeId == dropNodeId then
            local remainingEntries = {}
            for _, itemEntry in ipairs(dropNodeState.Entries or {}) do
                local success = self.InventoryService:pickupEntry(player, itemEntry)
                if success == true then
                    pickedAny = true
                    pickedCount += 1
                else
                    table.insert(remainingEntries, itemEntry)
                end
            end

            if #remainingEntries > 0 then
                table.insert(nextDropNodes, {
                    DropNodeId = dropNodeState.DropNodeId,
                    Label = dropNodeState.Label,
                    Position = dropNodeState.Position,
                    Entries = remainingEntries,
                })
            end
        else
            table.insert(nextDropNodes, dropNodeState)
        end
    end

    if not pickedAny then
        self:_setStatus(
            string.format(
                '%s found a dropped pack but has no room to recover it.',
                player.DisplayName
            )
        )
        return
    end

    self:_destroyDynamicDropNode(dropNodeId)
    self:_replaceDropNodeState(nextDropNodes)
    for _, dropNodeState in ipairs(nextDropNodes) do
        if dropNodeState.DropNodeId == dropNodeId then
            self:_spawnDynamicDropNode(dropNodeState)
            break
        end
    end

    self:_setStatus(
        string.format('%s 从地上捡回了 %d 件掉落物。', player.DisplayName, pickedCount)
    )
end

function MazeContentHarnessService:_getWorldBuildMetadataFields()
    local metadata = self.WorldBuildMetadata or {}
    return {
        WorldBuildIsDirectBoot = metadata.IsDirectBoot,
        WorldBuildMazeAccessCode = metadata.MazeAccessCode,
        WorldBuildSeed = metadata.Seed,
        WorldBuildSessionId = metadata.SessionId,
        WorldBuildSource = metadata.Source,
    }
end

function MazeContentHarnessService:_applyWorldBuildMetadataToRoot()
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

function MazeContentHarnessService:_recordWorldBuildMetadata()
    self.WorldBuildMetadata = {
        IsDirectBoot = self.SessionState.IsDirectBoot == true,
        MazeAccessCode = self.SessionState.MazeAccessCode,
        Seed = self.Seed,
        SessionId = self.SessionState.SessionId,
        Source = self.SessionState.WorldBuildSource,
    }
    self:_applyWorldBuildMetadataToRoot()
end

function MazeContentHarnessService:_getServerTimeNow()
    local ok, result = pcall(function()
        return Workspace:GetServerTimeNow()
    end)
    if ok and type(result) == 'number' then
        return result
    end

    return os.time()
end

function MazeContentHarnessService:_syncHeldItemEffects(player)
    local inventory = self.InventoryService:getSummary(player)
    HeldFlashlightHeadlight.syncHeldItem(player, inventory.HeldItem)
end

function MazeContentHarnessService:_seedDefaultTools(player)
    local inventorySummary = self.InventoryService:getSummary(player)
    if inventorySummary.Count > 0 then
        return
    end

    for _, itemId in ipairs({ 'tool-flashlight', 'tool-crowbar', 'tool-potion' }) do
        local itemDef = ToolItems[itemId]
        if itemDef then
            local success, reason = self.InventoryService:pickup(player, itemDef)
            if not success then
                error(
                    string.format(
                        '把 %s 塞进内容测试背包失败（%s）。',
                        itemId,
                        tostring(reason)
                    ),
                    0
                )
            end
        end
    end
end

function MazeContentHarnessService:_addPlayerState(player)
    self.SessionState:addPlayer({
        UserId = player.UserId,
        Name = player.DisplayName,
    })
    self.InventoryService:addPlayer(player)
    self:_seedDefaultTools(player)
    self.ControlStateService:addPlayer(player)
    self.PlayerService:addPlayer(player)
    self.PlayerStateService:addPlayer(player)
end

function MazeContentHarnessService:_removePlayerState(player)
    self.SessionState:removePlayer(player.UserId)
    self.InventoryService:removePlayer(player)
    self.ControlStateService:removePlayer(player)
    self.PlayerService:removePlayer(player)
    self.PlayerStateService:removePlayer(player)
    HeldFlashlightHeadlight.clear(player)
end

function MazeContentHarnessService:_getMovementSummaryFor(player)
    local playerState = self.PlayerService:getSummary(player)
    local controlState = self.ControlStateService:getSummary(player)
    return FormalLocomotion.summarize(playerState, controlState)
end

function MazeContentHarnessService:_applyMovementMode(player)
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass('Humanoid')
    if not humanoid then
        return
    end

    FormalLocomotion.applyToHumanoid(humanoid, self:_getMovementSummaryFor(player))
end

function MazeContentHarnessService:_syncPlayerMovement(player)
    local playerState = self.PlayerService:getSummary(player)
    local ok, controlState = self.ControlStateService:syncPlayerState(player, playerState)
    if ok and controlState then
        self.PlayerService:setSprinting(player, controlState.Mode == FormalLocomotion.Mode.Sprint)
    end

    self:_applyMovementMode(player)
end

function MazeContentHarnessService:_clearPlayerMovement(player)
    self.ControlStateService:requestSprintStop(player)
    self.PlayerService:setSprinting(player, false)
    self:_applyMovementMode(player)
end

function MazeContentHarnessService:_bindCharacterTeleport(player)
    player.CharacterAdded:Connect(function(character)
        task.wait()
        if not self.World or not character.Parent then
            return
        end

        local targetCFrame = self.World.SpawnCFrame
        if not self.SessionState:isPlayerActive(player.UserId) then
            targetCFrame = self.World.ReturnHoldCFrame
        end

        character:PivotTo(targetCFrame)
        self:_applyMovementMode(player)
        self:_syncHeldItemEffects(player)
    end)
end

function MazeContentHarnessService:_getPlayerUpdateContext(player)
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass('Humanoid')
    local rootPart = humanoid and humanoid.RootPart
    local currentPosition = rootPart and rootPart.Position or Vector3.zero

    return {
        CurrentPosition = currentPosition,
        InputState = {},
    }
end

function MazeContentHarnessService:_isPlayerDead(player)
    local summary = self.PlayerService:getSummary(player)
    return summary ~= nil and summary.Health ~= nil and summary.Health.IsDead == true
end

function MazeContentHarnessService:_buildRoster()
    local roster = {}

    for _, player in ipairs(self.GetPlayers()) do
        table.insert(roster, {
            Name = player.DisplayName,
            UserId = player.UserId,
            InMaze = self.SessionState:isPlayerActive(player.UserId),
        })
    end

    table.sort(roster, function(left, right)
        return left.Name < right.Name
    end)

    return roster
end

function MazeContentHarnessService:_getPlayerArea(player)
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

function MazeContentHarnessService:_getObjectiveFor()
    if self.SessionState.LoopState == 'Completed' then
        return '这一轮内容测试已经完成。你可以先观察现场，再重新 Play 进行下一轮。'
    end

    return self.SessionState.Objective
end

function MazeContentHarnessService:_buildSnapshotFor(player)
    local worldBuildFields = self:_getWorldBuildMetadataFields()
    local inventory = self.InventoryService:getSummary(player)
    local playerSummary = self.PlayerService:getSummary(player)

    return {
        IsLaunched = true,
        Status = self.Status,
        Area = self:_getPlayerArea(player),
        Objective = self:_getObjectiveFor(),
        State = self.SessionState.LoopState,
        SessionPhase = self.SessionState.SessionPhase,
        HostUserId = nil,
        RoundStarted = self.SessionState.LoopState ~= 'Staging',
        DangerActive = self.SessionState.LoopState == 'Expedition',
        RoundTimeRemainingSeconds = nil,
        SettlementReason = nil,
        CurrentRound = self.SessionState.CurrentRound,
        MaxRounds = self.SessionState.MaxRounds,
        BankedItemCount = self.SessionState.BankedItemCount,
        TargetItemCount = self.SessionState.TargetItemCount,
        RoundOutcome = nil,
        SessionOutcome = if self.SessionState.LoopState == 'Completed' then 'content-test' else nil,
        Inventory = inventory,
        Movement = self:_getMovementSummaryFor(player),
        ControlState = self.ControlStateService:getSummary(player),
        PlayerState = playerSummary and playerSummary.PlayerState or nil,
        Roster = self:_buildRoster(),
        SessionId = self.SessionState.SessionId,
        MazeAccessCode = self.SessionState.MazeAccessCode,
        MazeStatus = self.SessionState.MazeStatus,
        ReturnedPlayerSummaries = self.SessionState:getReturnedSummaries(),
        IsDirectBoot = self.SessionState.IsDirectBoot,
        WorldBuildSeed = worldBuildFields.WorldBuildSeed,
        WorldBuildSessionId = worldBuildFields.WorldBuildSessionId,
        WorldBuildMazeAccessCode = worldBuildFields.WorldBuildMazeAccessCode,
        WorldBuildIsDirectBoot = worldBuildFields.WorldBuildIsDirectBoot,
        WorldBuildSource = worldBuildFields.WorldBuildSource,
    }
end

function MazeContentHarnessService:_broadcastSnapshot()
    if not self.IsLaunched then
        return
    end

    for _, player in ipairs(self.GetPlayers()) do
        self.Remotes.MazeState:FireClient(player, self:_buildSnapshotFor(player))
        self.Remotes.MazePrivateState:FireClient(player, nil)
    end
end

function MazeContentHarnessService:_setStatus(status)
    self.Status = status
    self.SessionState:setStatus(status)
    print(string.format('[Maze] %s', status))
    self:_broadcastSnapshot()
end

function MazeContentHarnessService:_rebuildWorld()
    self:_setBootPhase('RebuildWorld')
    if self.SessionState.LoopState == 'Expedition' then
        self.MonsterService:destroy()
    end

    clearDefaultWorkspaceShell()
    self:_destroyDynamicDropNodes()

    if self.WorldInteractions then
        self.WorldInteractions:disconnectAll()
        self.WorldInteractions = nil
    end

    self.World = self.WorldBuilder.build()
    self:_recordWorldBuildMetadata()
    self:_applyPersistentWorldStateToWorld()
    self:_setBootPhase('BindWorldInteractions')
    self.WorldInteractions = self.World:bindInteractions({
        OnReturnHold = function(player)
            self:_returnPlayerLocally(player, 'returned')
        end,
        OnLoot = function(player, roomId)
            self:_pickupLoot(player, roomId)
        end,
        OnDoor = function(player, doorwayId)
            self:_toggleDoor(player, doorwayId)
        end,
    })
end

function MazeContentHarnessService:_toggleDoor(player, doorwayId)
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

function MazeContentHarnessService:_buildSummaryFor(player, returnReason, countInventory, overrides)
    local inventorySummary = overrides and overrides.InventorySummary
        or self.InventoryService:getSummary(player)
    local shouldCountInventory = countInventory ~= false
    local lootItemCount = shouldCountInventory
            and (overrides and overrides.LootItemCount or inventorySummary.LootCount or 0)
        or 0
    local clueCount = shouldCountInventory
            and (overrides and overrides.ClueCount or inventorySummary.ClueCount or 0)
        or 0
    local toolCount = shouldCountInventory
            and (overrides and overrides.ToolCount or inventorySummary.ToolCount or 0)
        or 0
    local missionCount = shouldCountInventory
            and (overrides and overrides.MissionCount or inventorySummary.MissionCount or lootItemCount)
        or 0

    return {
        UserId = player.UserId,
        Name = player.DisplayName,
        ReturnReason = returnReason,
        Value = 0,
        ItemCount = shouldCountInventory and (lootItemCount + clueCount + toolCount) or 0,
        Weight = 0,
        WasSettled = false,
        CountedInSettlement = shouldCountInventory,
        LootItemCount = lootItemCount,
        ClueCount = clueCount,
        ToolCount = toolCount,
        MissionCount = missionCount,
    }
end

function MazeContentHarnessService:_spawnCorpseForPlayer(player)
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

function MazeContentHarnessService:_completeLoopIfNoActivePlayers()
    if self.SessionState:getActiveCount() ~= 0 then
        return false
    end

    local completed, reason = self.SessionState:completeExpedition()
    if not completed then
        return nil, reason
    end

    self.MonsterService:destroy()
    self.SessionState:setObjective(
        '内容循环已完成。你可以先检查当前迷宫现场，再重新 Play 开下一轮。'
    )
    return true
end

function MazeContentHarnessService:_applyDeathReturn(player)
    local summary = self:_buildSummaryFor(player, 'death', false)
    local recorded = self.SessionState:recordReturn(summary)
    if not recorded then
        return
    end

    local completed, reason = self:_completeLoopIfNoActivePlayers()
    if completed == nil then
        self:_setStatus(string.format('迷宫结算失败：%s', tostring(reason)))
        return
    end
end

function MazeContentHarnessService:_handlePlayerDeath(player, damageKind)
    self:_spawnCorpseForPlayer(player)
    self:_clearPlayerMovement(player)

    local droppedEntries = self.InventoryService:dropAllItems(player)
    local character = player.Character
    local rootPart = character and character:FindFirstChild('HumanoidRootPart')
    local dropPosition = rootPart and rootPart.Position or self.World.ReturnHoldCFrame.Position
    self:_createPersistentDropNode(
        droppedEntries,
        dropPosition,
        string.format('%s Pack', player.DisplayName)
    )

    self:_applyDeathReturn(player)
    HeldFlashlightHeadlight.clear(player)

    if character and character.Parent and self.World then
        character:PivotTo(self.World.ReturnHoldCFrame)
    end

    self:_setStatus(
        string.format(
            '%s 受到了 %s 伤害并死亡，背包掉在了迷宫里。',
            player.DisplayName,
            localizeDamageKind(damageKind)
        )
    )
end

function MazeContentHarnessService:_applyPlayerDamage(player, damageKind)
    if not self.SessionState:isPlayerActive(player.UserId) then
        return
    end

    local success, result = self.PlayerService:applyDamage(player, damageKind)
    if not success then
        self:_setStatus(
            string.format('%s 无法受伤（%s）。', player.DisplayName, tostring(result))
        )
        return
    end

    local summary = self.PlayerService:getSummary(player)
    if not summary then
        self:_setStatus(string.format('%s 受伤后状态摘要不可用。', player.DisplayName))
        return
    end

    if summary.Health.IsDead then
        self:_handlePlayerDeath(player, damageKind)
        return
    end

    self:_syncPlayerMovement(player)

    self:_setStatus(
        string.format(
            '%s 受到了 %s 伤害，现在生命是 %d/%d。',
            player.DisplayName,
            localizeDamageKind(damageKind),
            summary.Health.CurrentHealthPips,
            summary.Health.MaxHealthPips
        )
    )
end

function MazeContentHarnessService:_pickupLoot(player, roomId)
    if self.SessionState.LoopState ~= 'Expedition' then
        self:_setStatus('只有在探索阶段才能拾取战利品。')
        return
    end

    if not self.SessionState:isPlayerActive(player.UserId) then
        self:_setStatus(
            string.format('%s 已经返回，不能再继续捡东西了。', player.DisplayName)
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
                '%s 拿不起 %s（%s）。',
                player.DisplayName,
                lootEntry.ItemDef.Name,
                tostring(reason)
            )
        )
        return
    end

    lootEntry:markCollected()
    self:_markLootCollected(roomId)

    local inventorySummary = self.InventoryService:getSummary(player)
    self:_setStatus(
        string.format(
            '%s 拿到了 %s，现在身上有 %d 件战利品。',
            player.DisplayName,
            lootEntry.ItemDef.Name,
            inventorySummary.LootCount or 0
        )
    )
end

function MazeContentHarnessService:_canManageInventory(player)
    if not self.SessionState:isPlayerActive(player.UserId) then
        self:_setStatus(
            string.format('%s 已经返回，不能再改背包状态了。', player.DisplayName)
        )
        return false
    end

    if self:_isPlayerDead(player) then
        self:_setStatus(
            string.format('%s 这一轮已经死亡，不能再操作背包。', player.DisplayName)
        )
        return false
    end

    return true
end

function MazeContentHarnessService:_equipItem(player, itemInstanceId)
    if not self:_canManageInventory(player) then
        return
    end

    local success, result = self.InventoryService:equip(player, itemInstanceId)
    if not success then
        self:_setStatus(
            string.format(
                '%s 装备这个物品失败（%s）。',
                player.DisplayName,
                tostring(result)
            )
        )
        return
    end

    self:_syncHeldItemEffects(player)
    self:_setStatus(string.format('%s 装备了 %s。', player.DisplayName, result.Name))
end

function MazeContentHarnessService:_unequipItem(player)
    if not self:_canManageInventory(player) then
        return
    end

    local success, result = self.InventoryService:unequip(player)
    if not success then
        self:_setStatus(
            string.format(
                '%s 收起当前手持失败（%s）。',
                player.DisplayName,
                tostring(result)
            )
        )
        return
    end

    self:_syncHeldItemEffects(player)
    self:_setStatus(string.format('%s 把 %s 收回了背包。', player.DisplayName, result.Name))
end

function MazeContentHarnessService:_handleUseTool(player)
    if not self:_canManageInventory(player) then
        return
    end

    local summary = self.PlayerService:getSummary(player)
    local playerState = summary and summary.PlayerState
    if playerState and playerState.IsDead == true then
        self:_setStatus(
            string.format('%s 已经死亡，不能再使用工具。', player.DisplayName)
        )
        return
    end

    local inventorySummary = self.InventoryService:getSummary(player)
    local heldItem = inventorySummary and inventorySummary.HeldItem

    if not heldItem then
        self:_setStatus(
            string.format('%s 想使用工具，但手上是空的。', player.DisplayName)
        )
        return
    end

    if type(heldItem.CurrentState) ~= 'number' or type(heldItem.ConsumePerUse) ~= 'number' then
        self:_setStatus(
            string.format(
                '%s 不能主动使用 %s（它不是工具）。',
                player.DisplayName,
                heldItem.Name
            )
        )
        return
    end

    if heldItem.ConsumePerUse > 0 and heldItem.CurrentState < heldItem.ConsumePerUse then
        self:_setStatus(
            string.format(
                '%s 想使用 %s，但它已经没有 %s 了。',
                player.DisplayName,
                heldItem.Name,
                heldItem.StateModel or 'power'
            )
        )
        return
    end

    local consumeSuccess, consumeResult, cooldownRemaining =
        self.InventoryService:consumeHeldItemState(player, os.clock())
    if not consumeSuccess then
        if consumeResult == 'Cooldown' then
            self:_setStatus(
                string.format(
                    '%s 现在还不能用 %s（还剩 %.1f 秒冷却）。',
                    player.DisplayName,
                    heldItem.Name,
                    math.max(cooldownRemaining or 0, 0)
                )
            )
        else
            self:_setStatus(
                string.format(
                    '%s 使用 %s 失败（%s）。',
                    player.DisplayName,
                    heldItem.Name,
                    tostring(consumeResult)
                )
            )
        end
        return
    end

    local updatedHeldItem = consumeResult
    local effectText = '使用成功。'

    if updatedHeldItem.ToolCategory == 'Flashlight' then
        local enabled = HeldFlashlightHeadlight.toggle(player)
        if enabled == nil then
            effectText = '头灯切换失败（角色没有头部）。'
        elseif enabled then
            effectText = '头灯已打开。'
        else
            effectText = '头灯已关闭。'
        end
    elseif updatedHeldItem.ToolCategory == 'Crowbar' then
        effectText = '空气中划过一声很扎实的挥击声。'

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
                effectText = '撬棍命中了，怪物倒下了！'
            elseif meleeResult and type(meleeResult.RemainingHitPoints) == 'number' then
                effectText = string.format(
                    '撬棍命中了！怪物剩余血量约 %d。',
                    meleeResult.RemainingHitPoints
                )
            end
        else
            effectText = crowbarMeleeMissText(meleeResult)
        end
    elseif updatedHeldItem.ToolCategory == 'Potion' then
        local healPips = 1
        if
            type(updatedHeldItem.HealHealthPips) == 'number'
            and updatedHeldItem.HealHealthPips >= 1
        then
            healPips = math.floor(updatedHeldItem.HealHealthPips)
        end
        local healOk, healResult = self.PlayerService:healHealthPips(player, healPips)
        if healOk then
            effectText = string.format('药水生效了，当前生命为 %d。', healResult)
        else
            effectText = string.format('药水没有生效（%s）。', tostring(healResult))
        end
    end

    self:_setStatus(
        string.format(
            '%s 使用了 %s。%s（%s 剩余：%d）',
            player.DisplayName,
            updatedHeldItem.Name,
            effectText,
            updatedHeldItem.StateModel or '状态',
            updatedHeldItem.CurrentState
        )
    )
end

function MazeContentHarnessService:_returnPlayerLocally(player, returnReason)
    if self.SessionState.LoopState ~= 'Expedition' then
        self:_setStatus('只有在探索阶段才能使用返回点。')
        return
    end

    if not self.SessionState:isPlayerActive(player.UserId) then
        self:_setStatus(
            string.format('%s 这一轮本地迷宫已经完成了。', player.DisplayName)
        )
        return
    end

    if self:_isPlayerDead(player) then
        self:_setStatus(
            string.format('%s 已经死亡，只能先待在等待区。', player.DisplayName)
        )
        return
    end

    local inventorySummary, bankedCount = self.InventoryService:extractMissionCargo(player)
    self.SessionState:addBankedItems(bankedCount)

    local summary = self:_buildSummaryFor(player, returnReason, true, {
        InventorySummary = inventorySummary,
        LootItemCount = bankedCount,
        MissionCount = bankedCount,
    })
    local recorded, reason = self.SessionState:recordReturn(summary)
    if not recorded then
        if reason == 'MissingActivePlayer' then
            self:_setStatus(
                string.format('%s 这一轮本地迷宫已经完成了。', player.DisplayName)
            )
        end
        return
    end

    self:_clearPlayerMovement(player)
    HeldFlashlightHeadlight.clear(player)

    local character = player.Character
    if character and character.Parent and self.World then
        character:PivotTo(self.World.ReturnHoldCFrame)
    end

    local completed, completionReason = self:_completeLoopIfNoActivePlayers()
    if completed == nil then
        self:_setStatus(string.format('迷宫完成结算失败：%s', tostring(completionReason)))
        return
    end

    if completed then
        self:_setStatus(
            string.format(
                '%s 完成了这一轮本地迷宫测试，入账了 %d 件战利品（%s）。',
                player.DisplayName,
                bankedCount,
                localizeReturnReason(summary.ReturnReason)
            )
        )
        return
    end

    self:_setStatus(
        string.format(
            '%s 到达了返回点，入账了 %d 件战利品（%s）。',
            player.DisplayName,
            bankedCount,
            localizeReturnReason(summary.ReturnReason)
        )
    )
end

function MazeContentHarnessService:_beginFormalExpedition()
    self:_setBootPhase('BeginFormalExpedition')
    local started, reason = self.SessionState:beginExpedition()
    if not started then
        if reason ~= 'InvalidState' then
            self:_setStatus(string.format('迷宫流程启动失败：%s', tostring(reason)))
        end
        return
    end

    local patrolPoints, initialPatrolIndex = self.World:getPatrolPoints()
    if #patrolPoints == 0 then
        error('迷宫内容测试场要求 authored 世界里存在 MonsterSpawns 巡逻点。', 0)
    end

    self:_setBootPhase('SpawnMonster')
    self.MonsterService:spawn(patrolPoints, initialPatrolIndex)
    self:_setStatus(
        '迷宫内容测试场已启动。开始探索、拿战利品，并找到返回点。'
    )
end

function MazeContentHarnessService:_loadExistingPlayers()
    self:_setBootPhase('BindExistingPlayers')
    for _, player in ipairs(self.GetPlayers()) do
        self:_bindCharacterTeleport(player)
        self:_addPlayerState(player)

        if player.Character then
            player.Character:Destroy()
        end
    end
end

function MazeContentHarnessService:_launchMaze()
    if self.IsLaunched then
        return
    end

    self:_setBootPhase('LaunchMaze')
    self:_rebuildWorld()

    self:_setBootPhase('LoadCharacters')
    for _, player in ipairs(self.GetPlayers()) do
        self.LoadCharacter(player)
    end

    self.IsLaunched = true
    self:_beginFormalExpedition()
    self:_setBootPhase('StartSnapshotLoop')
    self:_startSnapshotLoop()
    self:_setBootPhase('FirstSnapshot')
    self:_broadcastSnapshot()
    self:_setBootPhase('Launched')
end

function MazeContentHarnessService:_startSnapshotLoop()
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

                self.PlayerStateService:step(dt)

                for _, player in ipairs(self.GetPlayers()) do
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

function MazeContentHarnessService:start()
    self:_setBootPhase('Start')
    Players.CharacterAutoLoads = false

    self:_loadExistingPlayers()

    self:_setBootPhase('BindPlayerSignals')
    Players.PlayerAdded:Connect(function(player)
        self:_bindCharacterTeleport(player)
        self:_addPlayerState(player)

        if self.IsLaunched then
            self.LoadCharacter(player)
            self:_setStatus(
                string.format('%s 已加入本地迷宫内容测试。', player.DisplayName)
            )
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
        elseif payload.Type == 'RequestUseTool' then
            self:_handleUseTool(player)
        elseif RunService:IsStudio() and DEBUG_DAMAGE_BY_ACTION[payload.Type] then
            self:_applyPlayerDamage(player, DEBUG_DAMAGE_BY_ACTION[payload.Type])
        end
    end)

    self:_setBootPhase('BeforeLaunchMaze')
    task.defer(function()
        local ok, err = pcall(function()
            self:_launchMaze()
        end)

        if not ok then
            self:_setBootFailure(err)
        end
    end)
end

function MazeContentHarnessService:_setPlayerSprinting(player, isSprinting)
    if not self.SessionState:isPlayerActive(player.UserId) then
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
            self:_setStatus(
                string.format('%s 太累了，暂时不能冲刺。', player.DisplayName)
            )
        elseif result == 'Dead' then
            self:_setStatus(string.format('%s 已经死亡，不能冲刺。', player.DisplayName))
        end
        self:_syncPlayerMovement(player)
        return
    end

    self:_syncPlayerMovement(player)
end

return MazeContentHarnessService
