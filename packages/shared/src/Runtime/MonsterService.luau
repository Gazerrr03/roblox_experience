local InsertService = game:GetService('InsertService')
local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService('RunService')
local Workspace = game:GetService('Workspace')

local Packages = ReplicatedStorage:WaitForChild('Packages')
local Gameplay = require(Packages:WaitForChild('Gameplay'))

local MonsterBehaviorCatalog = Gameplay.Monsters.MonsterBehaviorCatalog
local MonsterLogic = Gameplay.Monsters.MonsterLogic
local MonsterRuntimeProfile = Gameplay.Monsters.MonsterRuntimeProfile

local MonsterService = {}
MonsterService.__index = MonsterService

local DEFAULT_FALLBACK_SIZE = Vector3.new(4, 4, 4)
local DEFAULT_R6_ANIMATIONS = table.freeze({
    Idle = 180435571,
    Walk = 180426354,
    Run = 180426354,
})

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
        AnimationTracks = {},
        ActiveAnimation = nil,
        Connection = nil,
        Warn = runtimeOptions.Warn or defaultWarn,
        LoadMonsterModel = runtimeOptions.AssetLoader or defaultLoadMonsterModel,
        LoadAnimationTrack = runtimeOptions.LoadAnimationTrack or defaultLoadAnimationTrack,
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
    if not self.MonsterPositionPart then
        return nil
    end

    return self.MonsterPositionPart.Position
end

function MonsterService:_applyVisualCFrame(nextCFrame)
    if self.MonsterRoot == nil then
        return
    end

    if self.MonsterRoot:IsA('Model') then
        self.MonsterRoot:PivotTo(nextCFrame)
    elseif self.MonsterRoot:IsA('BasePart') then
        self.MonsterRoot.CFrame = nextCFrame
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

    self.Connection = RunService.Heartbeat:Connect(function(dt)
        self:update(dt)
    end)
end

function MonsterService:update(dt)
    if not self.MonsterPositionPart or not self.IsExpeditionActive() then
        return
    end

    local playerPositions = {}

    for _, player in ipairs(Players:GetPlayers()) do
        if self.CanTargetPlayer(player) then
            local character = player.Character
            local rootPart = character and character:FindFirstChild('HumanoidRootPart')
            if rootPart then
                playerPositions[player] = rootPart.Position
            end
        end
    end

    local currentPosition = self:_getCurrentPosition()
    local targetPlayer = nil
    if self.Definition.Behaviors[MonsterBehaviorCatalog.Behavior.SenseNearestTarget] then
        targetPlayer = MonsterLogic.pickNearestTarget(
            currentPosition,
            playerPositions,
            self.Definition.SightRange
        )
    end
    local nextPosition

    if targetPlayer and self.Definition.Behaviors[MonsterBehaviorCatalog.Behavior.Chase] then
        nextPosition = MonsterLogic.stepToward(
            currentPosition,
            playerPositions[targetPlayer],
            self.Definition.Speed,
            dt
        )
    elseif
        self.Definition.Behaviors[MonsterBehaviorCatalog.Behavior.Patrol]
        and #self.PatrolPoints > 0
    then
        local patrolTarget = self.PatrolPoints[self.PatrolIndex] + self.Definition.SpawnOffset
        nextPosition = MonsterLogic.stepToward(
            currentPosition,
            patrolTarget,
            self.Definition.Speed * self.Definition.PatrolSpeedMultiplier,
            dt
        )

        if (nextPosition - patrolTarget).Magnitude <= 2 then
            self.PatrolIndex = (self.PatrolIndex % #self.PatrolPoints) + 1
        end
    end

    if nextPosition and self.CanTraverse(currentPosition, nextPosition) then
        local travelOffset = nextPosition - currentPosition
        local facingCFrame = if travelOffset.Magnitude > 0
            then CFrame.lookAt(nextPosition, nextPosition + travelOffset.Unit)
            else CFrame.new(nextPosition)
        self:_applyVisualCFrame(facingCFrame)

        if targetPlayer and self.Definition.Behaviors[MonsterBehaviorCatalog.Behavior.Chase] then
            self:_setAnimationState('Run', 1.15)
        elseif travelOffset.Magnitude > 0 then
            self:_setAnimationState('Walk', 1)
        else
            self:_setAnimationState('Idle', 1)
        end
    else
        self:_setAnimationState('Idle', 1)
    end
end

return MonsterService
