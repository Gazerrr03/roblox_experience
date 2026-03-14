local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService('RunService')
local Workspace = game:GetService('Workspace')

local Packages = ReplicatedStorage:WaitForChild('Packages')
local Gameplay = require(Packages:WaitForChild('Gameplay'))

local MonsterLogic = Gameplay.Monsters.MonsterLogic

local MonsterService = {}
MonsterService.__index = MonsterService

function MonsterService.new(monsterDefinition, isExpeditionActiveCallback)
    return setmetatable({
        Definition = monsterDefinition,
        IsExpeditionActive = isExpeditionActiveCallback,
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

function MonsterService:spawn(patrolPoints)
    self:destroy()
    self.PatrolPoints = patrolPoints
    self.PatrolIndex = 1

    if #patrolPoints == 0 then
        return
    end

    local monster = Instance.new('Part')
    monster.Name = self.Definition.Name
    monster.Shape = Enum.PartType.Ball
    monster.Size = Vector3.new(4, 4, 4)
    monster.Anchored = true
    monster.CanCollide = false
    monster.Material = Enum.Material.Neon
    monster.Color = Color3.fromRGB(214, 91, 91)
    monster.Position = patrolPoints[1] + Vector3.new(0, 4, 0)
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
        local character = player.Character
        local rootPart = character and character:FindFirstChild('HumanoidRootPart')
        if rootPart then
            playerPositions[player] = rootPart.Position
        end
    end

    local currentPosition = self.MonsterPart.Position
    local targetPlayer =
        MonsterLogic.pickNearestTarget(currentPosition, playerPositions, self.Definition.SightRange)
    local nextPosition

    if targetPlayer then
        nextPosition = MonsterLogic.stepToward(
            currentPosition,
            playerPositions[targetPlayer],
            self.Definition.Speed,
            dt
        )
    elseif #self.PatrolPoints > 0 then
        local patrolTarget = self.PatrolPoints[self.PatrolIndex] + Vector3.new(0, 4, 0)
        nextPosition =
            MonsterLogic.stepToward(currentPosition, patrolTarget, self.Definition.Speed * 0.45, dt)

        if (nextPosition - patrolTarget).Magnitude <= 2 then
            self.PatrolIndex = (self.PatrolIndex % #self.PatrolPoints) + 1
        end
    end

    if nextPosition then
        self.MonsterPart.CFrame = CFrame.new(nextPosition)
    end
end

return MonsterService
