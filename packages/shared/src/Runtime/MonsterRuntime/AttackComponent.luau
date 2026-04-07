local AttackComponent = {}
AttackComponent.__index = AttackComponent

function AttackComponent.new(options)
    local runtimeOptions = options or {}

    return setmetatable({
        Clock = runtimeOptions.Clock or os.clock,
        AttackRange = runtimeOptions.AttackRange or 0,
        CooldownSeconds = runtimeOptions.CooldownSeconds or 0.8,
        LastAttackAt = -math.huge,
    }, AttackComponent)
end

function AttackComponent:tryQueueAttack(currentPosition, blackboard)
    local target = blackboard.CurrentTarget
    if target == nil then
        return false
    end

    local targetPosition = blackboard.TargetPositions[target]
    if targetPosition == nil then
        return false
    end

    local now = self.Clock()
    if (now - self.LastAttackAt) < self.CooldownSeconds then
        return false
    end

    if self.AttackRange <= 0 then
        return false
    end

    if (targetPosition - currentPosition).Magnitude > self.AttackRange then
        return false
    end

    self.LastAttackAt = now
    return true
end

return AttackComponent
