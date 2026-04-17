local EnemyBlackboard = {}
EnemyBlackboard.__index = EnemyBlackboard

function EnemyBlackboard.new(options)
    local runtimeOptions = options or {}

    return setmetatable({
        CurrentTarget = nil,
        PreviousTarget = nil,
        TargetPositions = {},
        Awareness = 0,
        PerceptionState = 'Idle',
        LastSeenPosition = nil,
        LastSeenAt = nil,
        MemoryDurationSeconds = runtimeOptions.MemoryDurationSeconds or 3,
    }, EnemyBlackboard)
end

function EnemyBlackboard:setTarget(nextTarget, targetPosition, now)
    if self.CurrentTarget ~= nextTarget then
        self.PreviousTarget = self.CurrentTarget
    end

    self.CurrentTarget = nextTarget
    self.Awareness = if nextTarget ~= nil then 1 else 0

    if nextTarget ~= nil and targetPosition ~= nil then
        self.LastSeenPosition = targetPosition
        self.LastSeenAt = now
    end
end

function EnemyBlackboard:canUseLastSeen(now)
    if self.LastSeenPosition == nil or self.LastSeenAt == nil then
        return false
    end

    return (now - self.LastSeenAt) <= self.MemoryDurationSeconds
end

return EnemyBlackboard
