local PerceptionComponent = {}
PerceptionComponent.__index = PerceptionComponent

function PerceptionComponent.new(options)
    local runtimeOptions = options or {}

    return setmetatable({
        GetPlayers = runtimeOptions.GetPlayers,
        CanTargetPlayer = runtimeOptions.CanTargetPlayer,
        GetCurrentPosition = runtimeOptions.GetCurrentPosition,
        PickNearestTarget = runtimeOptions.PickNearestTarget,
        SightRange = runtimeOptions.SightRange,
        EnableSenseNearestTarget = runtimeOptions.EnableSenseNearestTarget,
        GetNow = runtimeOptions.GetNow,
    }, PerceptionComponent)
end

function PerceptionComponent:update(blackboard)
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

    blackboard.TargetPositions = playerPositions

    local targetPlayer
    if self.EnableSenseNearestTarget then
        targetPlayer =
            self.PickNearestTarget(self.GetCurrentPosition(), playerPositions, self.SightRange)
    end

    local now = self.GetNow()
    blackboard:setTarget(targetPlayer, playerPositions[targetPlayer], now)

    return targetPlayer ~= blackboard.PreviousTarget
end

return PerceptionComponent
