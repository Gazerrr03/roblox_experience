local MonsterLogic = {}

-- Bolt: Pre-cached Vector3 constructor and math functions for hot-path performance
local Vector3_new = Vector3.new

function MonsterLogic.pickNearestTarget(currentPosition, playerPositions, sightRange)
    -- Bolt: Using squared distance comparisons to avoid expensive square root calculations
    -- in the tight loop. We also access numeric components directly to reduce metatable overhead.
    local closestPlayer = nil

    -- Bolt: Negative sight range check to maintain parity with original behavior where
    -- negative range distance comparisons would naturally fail.
    if sightRange < 0 then
        return nil
    end

    local closestDistanceSq = sightRange * sightRange
    local cx, cy, cz = currentPosition.X, currentPosition.Y, currentPosition.Z

    for player, position in pairs(playerPositions) do
        local dx = position.X - cx
        local dy = position.Y - cy
        local dz = position.Z - cz
        local distSq = dx * dx + dy * dy + dz * dz

        if distSq <= closestDistanceSq then
            closestPlayer = player
            closestDistanceSq = distSq
        end
    end

    return closestPlayer
end

function MonsterLogic.stepToward(currentPosition, targetPosition, speed, dt)
    -- Bolt: Optimized stepToward to use raw numeric component math. This avoids redundant
    -- Vector3 allocations (like .Unit) and Magnitude (sqrt) calls when the step exceeds
    -- the remaining distance.
    local tx, ty, tz = targetPosition.X, targetPosition.Y, targetPosition.Z
    local cx, cy, cz = currentPosition.X, currentPosition.Y, currentPosition.Z

    local dx = tx - cx
    local dy = ty - cy
    local dz = tz - cz

    local distanceSq = dx * dx + dy * dy + dz * dz
    if distanceSq == 0 then
        return currentPosition
    end

    local maxStep = speed * dt
    -- Bolt: Fast-path for arrival/overshoot avoids expensive square root and division
    if maxStep * maxStep >= distanceSq then
        return targetPosition
    end

    local distance = math.sqrt(distanceSq)
    local fraction = maxStep / distance

    -- Bolt: Single Vector3 allocation for the result
    return Vector3_new(cx + dx * fraction, cy + dy * fraction, cz + dz * fraction)
end

return MonsterLogic
