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

function MonsterService.new(
    monsterRuntimeProfile,
    isExpeditionActiveCallback,
    canTargetPlayerCallback,
    canTraverseCallback
)
    local validRuntimeProfile, runtimeReason = MonsterRuntimeProfile.validate(monsterRuntimeProfile)
    if not validRuntimeProfile then
        error(string.format('Monster runtime profile invalid: %s', tostring(runtimeReason)), 0)
    end

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
        MonsterPart = nil,
        Connection = nil,
    }, MonsterService)
end

function MonsterService:destroy()
    if self.Connection then
        self.Connection:Disconnect()
        self.Connection = nil
    end

    if self.MonsterPart then
        self.MonsterPart:Destroy()
        self.MonsterPart = nil
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

    local monster = Instance.new('Part')
    monster.Name = self.Definition.Name
    monster.Shape = Enum.PartType.Ball
    monster.Size = Vector3.new(4, 4, 4)
    monster.Anchored = true
    monster.CanCollide = false
    monster.Material = Enum.Material.Neon
    monster.Color = Color3.fromRGB(214, 91, 91)
    monster.Position = patrolPoints[self.PatrolIndex] + self.Definition.SpawnOffset
    monster.Parent = Workspace

    self.MonsterPart = monster

    self.Connection = RunService.Heartbeat:Connect(function(dt)
        self:update(dt)
    end)
end

function MonsterService:update(dt)
    if not self.MonsterPart or not self.IsExpeditionActive() then
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

    local currentPosition = self.MonsterPart.Position
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
        self.MonsterPart.CFrame = CFrame.new(nextPosition)
    end
end

return MonsterService
