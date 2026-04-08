local InsertService = game:GetService('InsertService')
local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService('RunService')
local Workspace = game:GetService('Workspace')

local Packages = ReplicatedStorage:WaitForChild('Packages')
local Gameplay = require(Packages:WaitForChild('Gameplay'))

local MonsterBehaviorCatalog = Gameplay.Monsters.MonsterBehaviorCatalog
local MonsterComponentConfig = Gameplay.Monsters.MonsterComponentConfig
local Enemy = Gameplay.Monsters.Enemy
local MonsterRuntimeProfile = Gameplay.Monsters.MonsterRuntimeProfile

local MonsterService = {}
MonsterService.__index = MonsterService

local DEFAULT_FALLBACK_SIZE = Vector3.new(4, 4, 4)
local DEFAULT_R6_ANIMATIONS = table.freeze({
    Idle = 180435571,
    Walk = 180426354,
    Run = 180426354,
})
local DEFAULT_CHASE_LOOP_VOLUME = 0.45
local DEFAULT_CHASE_LOOP_MIN_DISTANCE = 8
local DEFAULT_CHASE_LOOP_MAX_DISTANCE = 48
local DEFAULT_VISUAL_SMOOTHING_SPEED = 12

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

    return setmetatable({
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
        GetPlayers = runtimeOptions.GetPlayers or function()
            return Players:GetPlayers()
        end,
        VisualSmoothingSpeed = runtimeOptions.VisualSmoothingSpeed
            or DEFAULT_VISUAL_SMOOTHING_SPEED,
    }, MonsterService)
end

function MonsterService:destroy()
    if self.Connection then
        self.Connection:Disconnect()
        self.Connection = nil
    end

    for _, track in pairs(self.AnimationTracks) do
        if track.Stop then
            track:Stop(0)
        end
    end

    self.AnimationTracks = {}
    self.ActiveAnimation = nil
    self.MonsterHumanoid = nil
    self.MonsterPositionPart = nil
    self.LogicalPosition = nil
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

    self.AnimationTracks = animationTracks
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
    self:_attachChaseLoopSound(rootPart)

    return true
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

function MonsterService:spawn(patrolPoints, initialPatrolIndex)
    self:destroy()
    self.PatrolPoints = patrolPoints
    self.PatrolIndex = 1

    if #patrolPoints == 0 then
        return
    end

    self.PatrolIndex = math.clamp(initialPatrolIndex or 1, 1, #patrolPoints)
    local spawnPosition = patrolPoints[self.PatrolIndex] + self.Definition.SpawnOffset
    local spawnOk, spawnReason = self:_spawnModel(spawnPosition)
    if not spawnOk then
        self:_warnFallback(spawnReason)
        self:_createFallbackPart(spawnPosition)
    else
        self:_setAnimationState('Idle', 1)
    end

    self.EnemyRuntime = self.EnemyFactory(self.Definition, {
        ComponentConfig = self.ComponentConfig,
    })
    if self.EnemyRuntime and self.EnemyRuntime.spawn then
        self.EnemyRuntime:spawn()
    end

    self.Connection = RunService.Heartbeat:Connect(function(dt)
        self:update(dt)
    end)
end

function MonsterService:update(dt)
    if not self.MonsterPositionPart or not self.IsExpeditionActive() or not self.EnemyRuntime then
        return
    end

    local playerPositions = {}

    for _, player in ipairs(self.GetPlayers()) do
        if self.CanTargetPlayer(player) then
            local character = player.Character
            local rootPart = character and character:FindFirstChild('HumanoidRootPart')
            if rootPart then
                playerPositions[player] = rootPart.Position
            end
        end
    end

    local currentPosition = self:_getCurrentPosition()
    local patrolTarget = nil
    if
        self.Definition.Behaviors[MonsterBehaviorCatalog.Behavior.Patrol]
        and #self.PatrolPoints > 0
    then
        patrolTarget = self.PatrolPoints[self.PatrolIndex] + self.Definition.SpawnOffset
    end

    local decision = self.EnemyRuntime:update(dt, {
        Behaviors = self.Definition.Behaviors,
        ComponentConfig = self.ComponentConfig,
        CurrentPosition = currentPosition,
        PatrolReachDistance = 2,
        PatrolSpeedMultiplier = self.Definition.PatrolSpeedMultiplier,
        PatrolTargetPosition = patrolTarget,
        PlayerPositions = playerPositions,
        SightRange = self.Definition.SightRange,
        Speed = self.Definition.Speed,
    })
    local nextPosition = decision.NextPosition
    if decision.ShouldAdvancePatrol and #self.PatrolPoints > 0 then
        self.PatrolIndex = (self.PatrolIndex % #self.PatrolPoints) + 1
    end

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
        self:_applyVisualCFrame(facingCFrame, dt)

        self:_setAnimationState(decision.DesiredAnimation, decision.DesiredAnimationSpeed)
        self:_setChaseLoopSoundPlaying(decision.ShouldPlayChaseLoop)
    else
        self:_setAnimationState('Idle', 1)
        self:_setChaseLoopSoundPlaying(false)
    end
end

return MonsterService
