local InsertService = game:GetService('InsertService')
local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService('RunService')
local Workspace = game:GetService('Workspace')

local Packages = ReplicatedStorage:WaitForChild('Packages')
local Gameplay = require(Packages:WaitForChild('Gameplay'))

local MonsterBehaviorCatalog = Gameplay.Monsters.MonsterBehaviorCatalog
local MonsterComponentConfig = Gameplay.Monsters.MonsterComponentConfig
local MonsterLogic = Gameplay.Monsters.MonsterLogic
local Enemy = Gameplay.Monsters.Enemy
local MonsterRuntimeProfile = Gameplay.Monsters.MonsterRuntimeProfile
local PlayerMonsterMelee = Gameplay.Combat.PlayerMonsterMelee
local EnemyRuntime = require(script.Parent.MonsterRuntime.EnemyRuntime)

local MonsterService = {}
MonsterService.__index = MonsterService

local DEFAULT_FALLBACK_SIZE = Vector3.new(4, 4, 4)
local DEFAULT_R6_ANIMATIONS = table.freeze({
    Idle = 180435571,
    Walk = 180426354,
    Run = 180426354,
    Attack = 10469493270,
})
local DEFAULT_CHASE_LOOP_VOLUME = 0.45
local DEFAULT_CHASE_LOOP_MIN_DISTANCE = 8
local DEFAULT_CHASE_LOOP_MAX_DISTANCE = 48
local DEFAULT_ATTACK_ARC_DEGREES = 100
local DEFAULT_ATTACK_MARKER_NAME = 'Hit'
local DEFAULT_ATTACK_MARKER_TIMEOUT_SECONDS = 1.5
local DEFAULT_VISUAL_SMOOTHING_SPEED = 12
local DEFAULT_LOGIC_TICK_RATE_HZ = 10
local DEFAULT_MAX_LOGIC_STEPS_PER_UPDATE = 6
local DEFAULT_DECISION_LOG_LIMIT = 128

local function defaultOnAttackHit(_player, _damagePips, _hitContext) end

local function defaultRaycast(origin, direction, raycastParams)
    return Workspace:Raycast(origin, direction, raycastParams)
end

local function defaultWarn(message)
    warn(message)
end

local function defaultLoadMonsterModel(assetId)
    local ok, assetContainer = pcall(function()
        return InsertService:LoadAsset(assetId)
    end)
    if not ok then
        return nil, assetContainer
    end

    local model = if assetContainer:IsA('Model')
        then assetContainer:FindFirstChildWhichIsA('Model') or assetContainer
        else assetContainer:FindFirstChildWhichIsA('Model')
    if not model then
        assetContainer:Destroy()
        return nil, 'MissingModelInAsset'
    end

    local clone = model:Clone()
    assetContainer:Destroy()
    return clone
end

local function defaultLoadAnimationTrack(animator, animationId, animationName)
    local animation = Instance.new('Animation')
    animation.Name = animationName
    animation.AnimationId = string.format('rbxassetid://%d', animationId)

    local track = animator:LoadAnimation(animation)
    animation:Destroy()

    return track
end

local function defaultCreateLoopSound(parent, soundAssetId, soundName)
    local sound = Instance.new('Sound')
    sound.Name = soundName
    sound.SoundId = string.format('rbxassetid://%d', soundAssetId)
    sound.Looped = true
    sound.Volume = DEFAULT_CHASE_LOOP_VOLUME
    sound.RollOffMode = Enum.RollOffMode.InverseTapered
    sound.RollOffMinDistance = DEFAULT_CHASE_LOOP_MIN_DISTANCE
    sound.RollOffMaxDistance = DEFAULT_CHASE_LOOP_MAX_DISTANCE
    sound.Parent = parent

    return sound
end

local function defaultEnemyFactory(monsterRuntimeProfile, options)
    return Enemy.new(monsterRuntimeProfile, options)
end

function MonsterService.new(
    monsterRuntimeProfile,
    isExpeditionActiveCallback,
    canTargetPlayerCallback,
    canTraverseCallback,
    options
)
    local validRuntimeProfile, runtimeReason = MonsterRuntimeProfile.validate(monsterRuntimeProfile)
    if not validRuntimeProfile then
        error(string.format('Monster runtime profile invalid: %s', tostring(runtimeReason)), 0)
    end

    local runtimeOptions = options or {}
    local logicTickRateHz = runtimeOptions.LogicTickRateHz or DEFAULT_LOGIC_TICK_RATE_HZ
    if type(logicTickRateHz) ~= 'number' or logicTickRateHz <= 0 then
        logicTickRateHz = DEFAULT_LOGIC_TICK_RATE_HZ
    end

    local randomSeed = runtimeOptions.RandomSeed
    if type(randomSeed) == 'number' then
        randomSeed = math.floor(randomSeed)
        if randomSeed <= 0 then
            randomSeed = nil
        end
    else
        randomSeed = nil
    end

    local service = setmetatable({
        Definition = monsterRuntimeProfile,
        IsExpeditionActive = isExpeditionActiveCallback,
        CanTargetPlayer = canTargetPlayerCallback or function()
            return true
        end,
        CanTraverse = canTraverseCallback or function()
            return true
        end,
        PatrolPoints = {},
        PatrolIndex = 1,
        MonsterRoot = nil,
        MonsterPositionPart = nil,
        MonsterHumanoid = nil,
        ChaseLoopSound = nil,
        IsChaseLoopSoundPlaying = false,
        AnimationTracks = {},
        AttackAnimationTrack = nil,
        AttackMarkerConnection = nil,
        PendingAttack = nil,
        ActiveAnimation = nil,
        Connection = nil,
        LogicalPosition = nil,
        EnemyRuntime = nil,
        ComponentConfig = MonsterComponentConfig.fromRuntimeProfile(monsterRuntimeProfile),
        Warn = runtimeOptions.Warn or defaultWarn,
        LoadMonsterModel = runtimeOptions.AssetLoader or defaultLoadMonsterModel,
        LoadAnimationTrack = runtimeOptions.LoadAnimationTrack or defaultLoadAnimationTrack,
        CreateLoopSound = runtimeOptions.CreateLoopSound or defaultCreateLoopSound,
        EnemyFactory = runtimeOptions.EnemyFactory or defaultEnemyFactory,
        OnAttackHit = runtimeOptions.OnAttackHit or defaultOnAttackHit,
        Raycast = runtimeOptions.Raycast or defaultRaycast,
        GetPlayers = runtimeOptions.GetPlayers or function()
            return Players:GetPlayers()
        end,
        AttackMarkerTimeoutSeconds = runtimeOptions.AttackMarkerTimeoutSeconds
            or DEFAULT_ATTACK_MARKER_TIMEOUT_SECONDS,
        VisualSmoothingSpeed = runtimeOptions.VisualSmoothingSpeed
            or DEFAULT_VISUAL_SMOOTHING_SPEED,
        AutoUpdateOnHeartbeat = if runtimeOptions.AutoUpdateOnHeartbeat == nil
            then true
            else runtimeOptions.AutoUpdateOnHeartbeat == true,
        LogicTickRateHz = logicTickRateHz,
        LogicTickSeconds = 1 / logicTickRateHz,
        MaxLogicStepsPerUpdate = runtimeOptions.MaxLogicStepsPerUpdate
            or DEFAULT_MAX_LOGIC_STEPS_PER_UPDATE,
        LogicAccumulator = 0,
        LogicTickCount = 0,
        LastState = nil,
        LastTargetUserId = nil,
        PendingVisualCFrame = nil,
        DecisionLogLimit = runtimeOptions.DecisionLogLimit or DEFAULT_DECISION_LOG_LIMIT,
        DecisionLog = {},
        DecisionLogSink = runtimeOptions.DecisionLogSink,
        DecisionLogSequence = 0,
        RandomSeed = randomSeed,
        RandomSource = runtimeOptions.RandomSource
            or if randomSeed ~= nil then Random.new(randomSeed) else Random.new(),
        CombatHitPointsRemaining = nil,
    }, MonsterService)

    service.EnemyRuntime = EnemyRuntime.new({
        MemoryDurationSeconds = runtimeOptions.MemoryDurationSeconds,
        Perception = {
            GetPlayers = function()
                return service.GetPlayers()
            end,
            CanTargetPlayer = function(player)
                return service.CanTargetPlayer(player)
            end,
            GetCurrentPosition = function()
                return service:_getCurrentPosition()
            end,
            PickNearestTarget = MonsterLogic.pickNearestTarget,
            SightRange = monsterRuntimeProfile.SightRange,
            EnableSenseNearestTarget = monsterRuntimeProfile.Behaviors[MonsterBehaviorCatalog.Behavior.SenseNearestTarget]
                == true,
            GetNow = os.clock,
        },
        Movement = {
            StepToward = MonsterLogic.stepToward,
            GetCurrentPosition = function()
                return service:_getCurrentPosition()
            end,
            SpawnOffset = monsterRuntimeProfile.SpawnOffset,
            Speed = monsterRuntimeProfile.Speed,
            PatrolSpeedMultiplier = monsterRuntimeProfile.PatrolSpeedMultiplier,
            EnableChase = monsterRuntimeProfile.Behaviors[MonsterBehaviorCatalog.Behavior.Chase]
                == true,
            EnablePatrol = monsterRuntimeProfile.Behaviors[MonsterBehaviorCatalog.Behavior.Patrol]
                == true,
        },
        Attack = {
            AttackRange = monsterRuntimeProfile.AttackRange or 0,
            CooldownSeconds = monsterRuntimeProfile.AttackCooldownSeconds,
        },
    })

    local combatHp = monsterRuntimeProfile.CombatHitPoints
    if type(combatHp) ~= 'number' or combatHp < 1 or math.floor(combatHp) ~= combatHp then
        combatHp = 1
    else
        combatHp = math.floor(combatHp)
    end
    service.CombatMaxHealth = combatHp
    service.CombatCurrentHealth = combatHp

    return service
end

function MonsterService:_emitDecisionLog(eventName, fields)
    self:_recordDecisionEvent(eventName, fields)
end

function MonsterService:destroy()
    if self.Connection then
        self.Connection:Disconnect()
        self.Connection = nil
    end

    if self.AttackMarkerConnection then
        self.AttackMarkerConnection:Disconnect()
        self.AttackMarkerConnection = nil
    end

    for _, track in pairs(self.AnimationTracks) do
        if track.Stop then
            track:Stop(0)
        end
    end
    if self.AttackAnimationTrack and self.AttackAnimationTrack.Stop then
        self.AttackAnimationTrack:Stop(0)
    end

    self.AnimationTracks = {}
    self.AttackAnimationTrack = nil
    self.PendingAttack = nil
    self.ActiveAnimation = nil
    self.MonsterHumanoid = nil
    self.CombatHitPointsRemaining = nil
    self.MonsterPositionPart = nil
    self.LogicalPosition = nil
    self.LogicAccumulator = 0
    self.LogicTickCount = 0
    self.LastState = nil
    self.LastTargetUserId = nil
    self.PendingVisualCFrame = nil
    if self.EnemyRuntime then
        self.EnemyRuntime:destroy()
        self.EnemyRuntime = nil
    end

    if self.ChaseLoopSound then
        if self.ChaseLoopSound.Stop then
            self.ChaseLoopSound:Stop()
        end
        if self.ChaseLoopSound.Destroy then
            self.ChaseLoopSound:Destroy()
        end
        self.ChaseLoopSound = nil
    end
    self.IsChaseLoopSoundPlaying = false

    if self.MonsterRoot then
        self.MonsterRoot:Destroy()
        self.MonsterRoot = nil
    end
end

function MonsterService:_warnFallback(reason)
    self.Warn(
        string.format(
            '[MonsterService] Falling back to placeholder for %s: %s',
            tostring(self.Definition.Id),
            tostring(reason)
        )
    )
end

function MonsterService:_createFallbackPart(spawnPosition)
    local monster = Instance.new('Part')
    monster.Name = self.Definition.Name
    monster.Shape = Enum.PartType.Ball
    monster.Size = DEFAULT_FALLBACK_SIZE
    monster.Anchored = true
    monster.CanCollide = false
    monster.CanTouch = false
    monster.Material = Enum.Material.Neon
    monster.Color = Color3.fromRGB(214, 91, 91)
    monster.Position = spawnPosition
    monster.Parent = Workspace

    self.MonsterRoot = monster
    self.MonsterPositionPart = monster
    self.LogicalPosition = spawnPosition
    self:_attachChaseLoopSound(monster)
end

function MonsterService:_prepareModelForRuntime(model)
    if not model or not model:IsA('Model') then
        return nil, nil, nil, 'MonsterAssetMustBeModel'
    end

    local humanoid = model:FindFirstChildOfClass('Humanoid')
    if humanoid == nil then
        return nil, nil, nil, 'MonsterAssetMissingHumanoid'
    end

    local rootPart = model:FindFirstChild('HumanoidRootPart')
    if rootPart == nil then
        rootPart = model.PrimaryPart or model:FindFirstChildWhichIsA('BasePart')
    end

    if rootPart == nil or not rootPart:IsA('BasePart') then
        return nil, nil, nil, 'MonsterAssetMissingRootPart'
    end

    for _, descendant in ipairs(model:GetDescendants()) do
        if descendant:IsA('BasePart') then
            descendant.Anchored = true
            descendant.CanCollide = false
            descendant.CanTouch = false
            descendant.CanQuery = false
        end
    end

    model.PrimaryPart = rootPart
    model.Name = self.Definition.Name

    return model, rootPart, humanoid
end

function MonsterService:_loadAnimationTracks(humanoid)
    local animator = humanoid:FindFirstChildOfClass('Animator')
    if animator == nil then
        animator = Instance.new('Animator')
        animator.Parent = humanoid
    end

    local animationTracks = {
        Idle = self.LoadAnimationTrack(animator, DEFAULT_R6_ANIMATIONS.Idle, 'MonsterIdle'),
        Walk = self.LoadAnimationTrack(animator, DEFAULT_R6_ANIMATIONS.Walk, 'MonsterWalk'),
        Run = self.LoadAnimationTrack(animator, DEFAULT_R6_ANIMATIONS.Run, 'MonsterRun'),
    }

    if animationTracks.Idle then
        animationTracks.Idle.Looped = true
        animationTracks.Idle.Priority = Enum.AnimationPriority.Idle
    end

    if animationTracks.Walk then
        animationTracks.Walk.Looped = true
        animationTracks.Walk.Priority = Enum.AnimationPriority.Movement
    end

    if animationTracks.Run then
        animationTracks.Run.Looped = true
        animationTracks.Run.Priority = Enum.AnimationPriority.Movement
    end

    local attackTrack =
        self.LoadAnimationTrack(animator, DEFAULT_R6_ANIMATIONS.Attack, 'MonsterAttack')
    if attackTrack then
        attackTrack.Looped = false
        attackTrack.Priority = Enum.AnimationPriority.Action
        if attackTrack.GetMarkerReachedSignal then
            local markerSignal = attackTrack:GetMarkerReachedSignal(DEFAULT_ATTACK_MARKER_NAME)
            if markerSignal then
                self.AttackMarkerConnection = markerSignal:Connect(function()
                    self:_onAttackMarkerReached(DEFAULT_ATTACK_MARKER_NAME)
                end)
            end
        end
    end

    self.AnimationTracks = animationTracks
    self.AttackAnimationTrack = attackTrack
    self.MonsterHumanoid = humanoid
end

function MonsterService:_attachChaseLoopSound(parent)
    local soundAssetId = self.Definition.Presentation.ChaseLoopSoundAssetId
    if parent == nil or type(soundAssetId) ~= 'number' or soundAssetId <= 0 then
        return
    end

    local soundOk, soundOrErr = pcall(function()
        return self.CreateLoopSound(parent, soundAssetId, 'MonsterChaseLoop')
    end)
    if not soundOk then
        self:_warnFallback(string.format('ChaseLoopSoundFailed (%s)', tostring(soundOrErr)))
        return
    end

    self.ChaseLoopSound = soundOrErr
    self.IsChaseLoopSoundPlaying = false
end

function MonsterService:_spawnModel(spawnPosition)
    local presentation = self.Definition.Presentation
    local model, loadReason = self.LoadMonsterModel(presentation.ModelAssetId)
    if not model then
        return false, loadReason
    end

    local preparedModel, rootPart, humanoid, prepareReason = self:_prepareModelForRuntime(model)
    if not preparedModel then
        model:Destroy()
        return false, prepareReason
    end

    preparedModel.Parent = Workspace
    preparedModel:PivotTo(CFrame.new(spawnPosition))

    if presentation.AnimationMode == 'defaultR6' then
        local animationOk, animationErr = pcall(function()
            self:_loadAnimationTracks(humanoid)
        end)
        if not animationOk then
            self:_warnFallback(string.format('AnimationLoadFailed (%s)', tostring(animationErr)))
        end
    end

    self.MonsterRoot = preparedModel
    self.MonsterPositionPart = rootPart
    self.LogicalPosition = spawnPosition
    if self.MonsterHumanoid == nil then
        self.MonsterHumanoid = humanoid
    end
    self:_attachChaseLoopSound(rootPart)

    return true
end

function MonsterService:_applyDefinitionCombatHealth()
    local maxPips = self.Definition.CombatHitPoints
    if type(maxPips) ~= 'number' or maxPips < 1 or math.floor(maxPips) ~= maxPips then
        maxPips = 1
    end

    self.CombatMaxHealth = maxPips

    local humanoid = self.MonsterHumanoid
    if humanoid then
        humanoid.MaxHealth = maxPips
        humanoid.Health = maxPips
        self.CombatCurrentHealth = maxPips
        self.CombatHitPointsRemaining = nil
        return
    end

    self.CombatHitPointsRemaining = maxPips
    self.CombatCurrentHealth = maxPips
end

function MonsterService:_setAnimationState(animationName, speedMultiplier)
    if self.ActiveAnimation == animationName then
        local activeTrack = self.AnimationTracks[animationName]
        if activeTrack and activeTrack.AdjustSpeed then
            activeTrack:AdjustSpeed(speedMultiplier or 1)
        end
        return
    end

    for trackName, track in pairs(self.AnimationTracks) do
        if trackName ~= animationName and track and track.Stop then
            track:Stop(0.1)
        end
    end

    local nextTrack = self.AnimationTracks[animationName]
    if nextTrack then
        if nextTrack.Play then
            nextTrack:Play(0.1)
        end
        if nextTrack.AdjustSpeed then
            nextTrack:AdjustSpeed(speedMultiplier or 1)
        end
    end

    self.ActiveAnimation = animationName
end

function MonsterService:_getCurrentPosition()
    if self.LogicalPosition then
        return self.LogicalPosition
    end

    if not self.MonsterPositionPart then
        return nil
    end

    return self.MonsterPositionPart.Position
end

function MonsterService:_setChaseLoopSoundPlaying(shouldPlay)
    if not self.ChaseLoopSound then
        return
    end

    local isPlaying = self.IsChaseLoopSoundPlaying == true or self.ChaseLoopSound.IsPlaying == true
    if shouldPlay then
        if not isPlaying and self.ChaseLoopSound.Play then
            self.ChaseLoopSound:Play()
        end
        self.IsChaseLoopSoundPlaying = true
        return
    end

    if isPlaying and self.ChaseLoopSound.Stop then
        self.ChaseLoopSound:Stop()
    end
    self.IsChaseLoopSoundPlaying = false
end

function MonsterService:_applyVisualCFrame(nextCFrame, dt)
    if self.MonsterRoot == nil then
        return
    end

    local appliedCFrame = nextCFrame
    local smoothingAlpha = 1
    if type(dt) == 'number' and dt > 0 then
        smoothingAlpha = 1 - math.exp(-self.VisualSmoothingSpeed * dt)
        smoothingAlpha = math.clamp(smoothingAlpha, 0, 1)
    end

    local currentCFrame
    if self.MonsterRoot:IsA('Model') then
        currentCFrame = self.MonsterRoot:GetPivot()
    elseif self.MonsterRoot:IsA('BasePart') then
        currentCFrame = self.MonsterRoot.CFrame
    end

    if currentCFrame and smoothingAlpha < 1 then
        appliedCFrame = currentCFrame:Lerp(nextCFrame, smoothingAlpha)
    end

    if self.MonsterRoot:IsA('Model') then
        self.MonsterRoot:PivotTo(appliedCFrame)
    elseif self.MonsterRoot:IsA('BasePart') then
        self.MonsterRoot.CFrame = appliedCFrame
    end
end

function MonsterService:_recordDecisionEvent(eventName, fields)
    self.DecisionLogSequence += 1

    local entry = {
        Event = eventName,
        MonsterId = self.Definition.Id,
        Sequence = self.DecisionLogSequence,
        Tick = self.LogicTickCount,
    }

    for key, value in pairs(fields or {}) do
        entry[key] = value
    end

    table.insert(self.DecisionLog, entry)
    if #self.DecisionLog > self.DecisionLogLimit then
        table.remove(self.DecisionLog, 1)
    end

    if self.DecisionLogSink then
        self.DecisionLogSink(entry)
    end
end

function MonsterService:getDecisionLogSnapshot()
    local snapshot = {}
    for index, entry in ipairs(self.DecisionLog) do
        snapshot[index] = table.clone(entry)
    end
    return snapshot
end

function MonsterService:clearDecisionLog()
    table.clear(self.DecisionLog)
    self.DecisionLogSequence = 0
end

function MonsterService:setDeterministicSeed(seed, randomSource)
    local normalizedSeed = seed
    if type(normalizedSeed) == 'number' then
        normalizedSeed = math.floor(normalizedSeed)
        if normalizedSeed <= 0 then
            normalizedSeed = nil
        end
    else
        normalizedSeed = nil
    end

    self.RandomSeed = normalizedSeed
    self.RandomSource = randomSource
        or if normalizedSeed ~= nil then Random.new(normalizedSeed) else Random.new()
    self:_recordDecisionEvent('SeedUpdated', {
        Seed = self.RandomSeed,
    })
end

function MonsterService:_nextRandomInteger(minimum, maximum, reason)
    local result = self.RandomSource:NextInteger(minimum, maximum)
    self:_recordDecisionEvent('RandomRoll', {
        Maximum = maximum,
        Minimum = minimum,
        Reason = reason or 'unspecified',
        Result = result,
        Seed = self.RandomSeed,
    })
    return result
end

function MonsterService:_resolveTargetUserId(targetPlayer)
    if targetPlayer == nil then
        return nil
    end

    if typeof(targetPlayer) == 'Instance' and targetPlayer:IsA('Player') then
        return targetPlayer.UserId
    end

    if type(targetPlayer) == 'table' and type(targetPlayer.UserId) == 'number' then
        return targetPlayer.UserId
    end

    return tostring(targetPlayer)
end

function MonsterService:_recordDecisionTransitions(decision)
    local state = decision.State
    if type(state) == 'string' and state ~= self.LastState then
        self:_recordDecisionEvent('StateTransition', {
            FromState = self.LastState,
            ToState = state,
        })
        self.LastState = state
    end

    local targetUserId = self:_resolveTargetUserId(decision.TargetPlayer)
    if targetUserId ~= self.LastTargetUserId then
        self:_recordDecisionEvent('TargetSwitch', {
            FromTargetUserId = self.LastTargetUserId,
            ToTargetUserId = targetUserId,
        })
        self.LastTargetUserId = targetUserId
    end

    if decision.AttackResult ~= nil then
        self:_recordDecisionEvent('AttackResult', {
            Result = decision.AttackResult,
        })
    end
end

function MonsterService:_getAttackFacingDirection()
    local lookVector = nil
    if self.MonsterRoot and self.MonsterRoot:IsA('Model') then
        lookVector = self.MonsterRoot:GetPivot().LookVector
    elseif self.MonsterPositionPart then
        lookVector = self.MonsterPositionPart.CFrame.LookVector
    end

    if typeof(lookVector) ~= 'Vector3' then
        return Vector3.new(0, 0, -1)
    end

    local horizontalLook = Vector3.new(lookVector.X, 0, lookVector.Z)
    if horizontalLook.Magnitude <= 1e-5 then
        return lookVector.Unit
    end

    return horizontalLook.Unit
end

function MonsterService:_isWithinAttackArc(monsterPosition, targetPosition, arcDegrees)
    local toTarget = targetPosition - monsterPosition
    local horizontalToTarget = Vector3.new(toTarget.X, 0, toTarget.Z)
    if horizontalToTarget.Magnitude <= 1e-5 then
        return true
    end

    local facingDirection = self:_getAttackFacingDirection()
    local facingHorizontal = Vector3.new(facingDirection.X, 0, facingDirection.Z)
    if facingHorizontal.Magnitude <= 1e-5 then
        return true
    end
    facingHorizontal = facingHorizontal.Unit

    local targetDirection = horizontalToTarget.Unit
    local halfArcCosine = math.cos(math.rad((arcDegrees or DEFAULT_ATTACK_ARC_DEGREES) * 0.5))
    local dot = facingHorizontal:Dot(targetDirection)
    return dot + 1e-6 >= halfArcCosine
end

function MonsterService:_hasLineOfSight(targetPlayer, originPosition, targetPosition)
    local direction = targetPosition - originPosition
    if direction.Magnitude <= 1e-5 then
        return true
    end

    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.IgnoreWater = true
    if self.MonsterRoot then
        raycastParams.FilterDescendantsInstances = { self.MonsterRoot }
    end

    local raycastResult = self.Raycast(originPosition, direction, raycastParams)
    if raycastResult == nil then
        return true
    end

    local character = targetPlayer and targetPlayer.Character
    if
        character
        and raycastResult.Instance
        and raycastResult.Instance:IsDescendantOf(character)
    then
        return true
    end

    return false
end

function MonsterService:_resolveAttackHitContext(pendingAttack)
    local targetPlayer = pendingAttack.TargetPlayer
    if targetPlayer == nil or not self.CanTargetPlayer(targetPlayer) then
        return {
            Hit = false,
            Reason = 'InvalidTarget',
        }
    end

    local targetCharacter = targetPlayer.Character
    local targetRoot = targetCharacter and targetCharacter:FindFirstChild('HumanoidRootPart')
    if not targetRoot then
        return {
            Hit = false,
            Reason = 'MissingTargetRoot',
        }
    end

    local monsterPosition = self:_getCurrentPosition()
    if typeof(monsterPosition) ~= 'Vector3' then
        return {
            Hit = false,
            Reason = 'MissingMonsterPosition',
        }
    end

    local targetPosition = targetRoot.Position
    local distance = (targetPosition - monsterPosition).Magnitude
    if distance > pendingAttack.Range then
        return {
            Hit = false,
            Reason = 'OutOfRange',
        }
    end

    if not self:_isWithinAttackArc(monsterPosition, targetPosition, pendingAttack.ArcDegrees) then
        return {
            Hit = false,
            Reason = 'OutOfArc',
        }
    end

    if not self:_hasLineOfSight(targetPlayer, monsterPosition, targetPosition) then
        return {
            Hit = false,
            Reason = 'BlockedLineOfSight',
        }
    end

    return {
        Hit = true,
        Reason = 'HitConfirmed',
        Distance = distance,
        Effects = pendingAttack.Effects,
    }
end

function MonsterService:_playAttackAnimation()
    local attackTrack = self.AttackAnimationTrack
    if not attackTrack then
        return false
    end

    if attackTrack.Stop then
        attackTrack:Stop(0)
    end
    if attackTrack.Play then
        attackTrack:Play(0.05)
    else
        return false
    end
    if attackTrack.AdjustSpeed then
        attackTrack:AdjustSpeed(1)
    end

    return true
end

function MonsterService:_queueAttackIntent(attackIntent)
    if type(attackIntent) ~= 'table' then
        return
    end

    local targetPlayer = attackIntent.TargetPlayer
    if targetPlayer == nil or not self.CanTargetPlayer(targetPlayer) then
        return
    end

    local damagePips = attackIntent.DamagePips
    if damagePips ~= 1 and damagePips ~= 2 then
        return
    end

    local range = attackIntent.Range
    if type(range) ~= 'number' or range <= 0 then
        return
    end

    local markerName = if type(attackIntent.MarkerName) == 'string'
            and attackIntent.MarkerName ~= ''
        then attackIntent.MarkerName
        else DEFAULT_ATTACK_MARKER_NAME

    local hasMarkerConnection = self.AttackMarkerConnection ~= nil
    if hasMarkerConnection then
        if self.PendingAttack ~= nil then
            return
        end

        self.PendingAttack = {
            ArcDegrees = attackIntent.ArcDegrees or DEFAULT_ATTACK_ARC_DEGREES,
            DamagePips = damagePips,
            MarkerName = markerName,
            Range = range,
            RemainingWindowSeconds = self.AttackMarkerTimeoutSeconds,
            TargetPlayer = targetPlayer,
        }
    end

    local animationPlayed = self:_playAttackAnimation()
    if hasMarkerConnection and not animationPlayed then
        self.PendingAttack = nil
    end
end

function MonsterService:_stepPendingAttack(dt)
    if self.PendingAttack == nil then
        return
    end

    self.PendingAttack.RemainingWindowSeconds -= math.max(0, dt or 0)
    if self.PendingAttack.RemainingWindowSeconds <= 0 then
        self.PendingAttack = nil
    end
end

function MonsterService:_onAttackMarkerReached(markerName)
    local pendingAttack = self.PendingAttack
    if pendingAttack == nil then
        return
    end

    if markerName ~= pendingAttack.MarkerName then
        return
    end

    self.PendingAttack = nil

    local hitContext = self:_resolveAttackHitContext(pendingAttack)
    if hitContext.Hit ~= true then
        return
    end

    self.OnAttackHit(pendingAttack.TargetPlayer, pendingAttack.DamagePips, hitContext)
end

function MonsterService:_playerMeleeLineOfSightClear(player, playerPosition, monsterPosition)
    local offset = monsterPosition - playerPosition
    local distance = offset.Magnitude
    if distance <= 1e-3 then
        return true
    end

    local character = player and player.Character
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.IgnoreWater = true
    if character then
        raycastParams.FilterDescendantsInstances = { character }
    end

    local direction = offset.Unit * (distance + 0.25)
    local result = self.Raycast(playerPosition, direction, raycastParams)
    if result == nil then
        return true
    end

    if
        self.MonsterRoot
        and result.Instance
        and result.Instance:IsDescendantOf(self.MonsterRoot)
    then
        return true
    end

    return false
end

function MonsterService:tryApplyPlayerMeleeHit(player, meleeOptions)
    if not self.IsExpeditionActive() then
        return false, 'ExpeditionInactive'
    end

    if self.MonsterRoot == nil then
        return false, 'NoMonster'
    end

    local isPlayerInstance = typeof(player) == 'Instance' and player:IsA('Player')
    local isTestStub = type(player) == 'table' and type(player.UserId) == 'number'
    if not isPlayerInstance and not isTestStub then
        return false, 'InvalidPlayer'
    end

    local character = player.Character
    if character == nil then
        return false, 'NoCharacter'
    end

    local humanoidRoot = character:FindFirstChild('HumanoidRootPart')
    if humanoidRoot == nil or not humanoidRoot:IsA('BasePart') then
        return false, 'MissingHumanoidRoot'
    end

    local options = meleeOptions or {}
    local swingRange = options.SwingRange
    if type(swingRange) ~= 'number' or swingRange <= 0 then
        swingRange = 6
    end

    local swingArcDegrees = options.SwingArcDegrees
    if type(swingArcDegrees) ~= 'number' or swingArcDegrees <= 0 then
        swingArcDegrees = 70
    end

    local damagePips = options.DamagePips
    if type(damagePips) ~= 'number' or damagePips < 1 then
        damagePips = 1
    end
    damagePips = math.floor(damagePips)

    local monsterPosition = self:_getCurrentPosition()
    if typeof(monsterPosition) ~= 'Vector3' then
        return false, 'MissingMonsterPosition'
    end

    local playerPosition = humanoidRoot.Position
    local playerLook = humanoidRoot.CFrame.LookVector

    local geometryOk, geometryReason = PlayerMonsterMelee.evaluateSwing(
        playerPosition,
        playerLook,
        monsterPosition,
        swingRange,
        swingArcDegrees
    )
    if geometryOk ~= true then
        return false, geometryReason
    end

    if not self.CanTraverse(playerPosition, monsterPosition) then
        return false, 'PathBlocked'
    end

    if not self:_playerMeleeLineOfSightClear(player, playerPosition, monsterPosition) then
        return false, 'BlockedLineOfSight'
    end

    local monsterHumanoid = self.MonsterHumanoid
    local killed = false
    local remainingHitPoints

    if monsterHumanoid then
        local nextHealth = math.max(0, monsterHumanoid.Health - damagePips)
        monsterHumanoid.Health = nextHealth
        remainingHitPoints = math.ceil(nextHealth)
        self.CombatCurrentHealth = remainingHitPoints
        if nextHealth <= 0 then
            killed = true
        end
    elseif type(self.CombatHitPointsRemaining) == 'number' then
        self.CombatHitPointsRemaining -= damagePips
        remainingHitPoints = math.max(0, self.CombatHitPointsRemaining)
        self.CombatCurrentHealth = remainingHitPoints
        if remainingHitPoints <= 0 then
            killed = true
        end
    else
        return false, 'MonsterCombatStateMissing'
    end

    self:_recordDecisionEvent('PlayerMeleeHit', {
        DamagePips = damagePips,
        Killed = killed,
        RemainingHitPoints = remainingHitPoints,
        TargetUserId = player.UserId,
    })

    if self.EnemyRuntime then
        self.EnemyRuntime:applyDamage(damagePips, 'player')
    end

    if killed then
        self:destroy()
    end

    return true, {
        Killed = killed,
        RemainingHitPoints = remainingHitPoints,
    }
end

function MonsterService:spawn(patrolPoints, initialPatrolIndex)
    self:destroy()
    self.PatrolPoints = patrolPoints
    self.PatrolIndex = 1
    self.LogicAccumulator = 0
    self.LogicTickCount = 0
    self.LastState = nil
    self.LastTargetUserId = nil
    self.PendingVisualCFrame = nil
    self:clearDecisionLog()

    if #patrolPoints == 0 then
        return
    end

    self.PatrolIndex = math.clamp(initialPatrolIndex or 1, 1, #patrolPoints)
    self.EnemyRuntime:reset(self.PatrolPoints, self.PatrolIndex)
    local spawnPosition = patrolPoints[self.PatrolIndex] + self.Definition.SpawnOffset
    local spawnOk, spawnReason = self:_spawnModel(spawnPosition)
    if not spawnOk then
        self:_warnFallback(spawnReason)
        self:_createFallbackPart(spawnPosition)
    else
        self:_setAnimationState('Idle', 1)
    end

    self:_applyDefinitionCombatHealth()

    self.EnemyRuntime = self.EnemyFactory(self.Definition, {
        ComponentConfig = self.ComponentConfig,
    })
    if self.EnemyRuntime and self.EnemyRuntime.spawn then
        self.EnemyRuntime:spawn()
    end

    if self.AutoUpdateOnHeartbeat then
        self.Connection = RunService.Heartbeat:Connect(function(dt)
            self:update(dt)
        end)
    end
end

function MonsterService:_runLogicStep(dt)
    local currentPosition = self:_getCurrentPosition()
    if currentPosition == nil then
        return
    end

    local decision = self.EnemyRuntime:update(dt)
    self.PatrolIndex = self.EnemyRuntime.Context.PatrolIndex

    if decision.IsDead then
        self:_recordDecisionEvent('Died', {
            MonsterId = self.Definition.Id,
            DeathEvent = decision.DeathEvent,
        })
        self:destroy()
        return
    end

    if decision.TargetChanged then
        self:_emitDecisionLog('TargetChanged', {
            MonsterId = self.Definition.Id,
            State = decision.PerceptionState,
        })
    end
    if decision.StateChanged then
        self:_emitDecisionLog('StateChanged', {
            MonsterId = self.Definition.Id,
            State = decision.PerceptionState,
        })
    end
    if decision.AttackQueued then
        self:_emitDecisionLog('AttackQueued', {
            MonsterId = self.Definition.Id,
        })
        local target = self.EnemyRuntime.Blackboard.CurrentTarget
        if target then
            self:_queueAttackIntent({
                TargetPlayer = target,
                DamagePips = self.ComponentConfig.Attack.DamagePips,
                Range = self.ComponentConfig.Attack.Range,
                ArcDegrees = self.ComponentConfig.Attack.ArcDegrees,
                MarkerName = self.ComponentConfig.Attack.HitMarkerName,
                Effects = self.Definition.Effects,
            })
        end
    end

    local nextPosition = decision.NextPosition
    if nextPosition and self.CanTraverse(currentPosition, nextPosition) then
        local travelOffset = nextPosition - currentPosition
        self.LogicalPosition = nextPosition
        local currentRotation = CFrame.identity
        if self.MonsterRoot and self.MonsterRoot:IsA('Model') then
            currentRotation = self.MonsterRoot:GetPivot().Rotation
        elseif self.MonsterRoot and self.MonsterRoot:IsA('BasePart') then
            currentRotation = self.MonsterRoot.CFrame.Rotation
        end
        local facingCFrame = if travelOffset.Magnitude > 0
            then CFrame.lookAt(nextPosition, nextPosition + travelOffset.Unit)
            else currentRotation + nextPosition
        self.PendingVisualCFrame = facingCFrame

        self:_setAnimationState(decision.AnimationName or 'Idle', decision.AnimationSpeed or 1)
        self:_setChaseLoopSoundPlaying(decision.ShouldPlayChaseLoop == true)
    else
        self.PendingVisualCFrame = nil
        self:_setAnimationState('Idle', 1)
        self:_setChaseLoopSoundPlaying(false)
    end

    self:_recordDecisionTransitions(decision)
end

function MonsterService:update(dt)
    if not self.MonsterPositionPart or not self.IsExpeditionActive() or not self.EnemyRuntime then
        return
    end

    local elapsed = if type(dt) == 'number' and dt > 0 then dt else 0
    self:_stepPendingAttack(elapsed)
    self.LogicAccumulator += elapsed

    local maxSteps = self.MaxLogicStepsPerUpdate
    if type(maxSteps) ~= 'number' or maxSteps < 1 then
        maxSteps = DEFAULT_MAX_LOGIC_STEPS_PER_UPDATE
    end
    maxSteps = math.max(1, math.floor(maxSteps))

    local executed = 0
    while self.LogicAccumulator >= self.LogicTickSeconds and executed < maxSteps do
        self.LogicAccumulator -= self.LogicTickSeconds
        self.LogicTickCount += 1
        executed += 1
        self:_runLogicStep(self.LogicTickSeconds)
    end

    if self.LogicAccumulator >= self.LogicTickSeconds then
        local droppedTime = self.LogicAccumulator - (self.LogicAccumulator % self.LogicTickSeconds)
        self.LogicAccumulator = self.LogicAccumulator % self.LogicTickSeconds
        self:_recordDecisionEvent('TickDrop', {
            DroppedTime = droppedTime,
            Elapsed = elapsed,
            ExecutedSteps = executed,
            MaxStepsPerUpdate = maxSteps,
        })
    end

    if self.PendingVisualCFrame then
        self:_applyVisualCFrame(self.PendingVisualCFrame, elapsed)
    end
end

return MonsterService
