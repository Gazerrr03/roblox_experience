local MonsterLogic = {}

local Vector3_new = Vector3.new

-- Bolt: Optimized pickNearestTarget to use squared distance comparisons and raw numeric component access.
-- This bypasses Vector3 metatable dispatch and avoids expensive square root calculations.
function MonsterLogic.pickNearestTarget(currentPosition, playerPositions, sightRange)
    if sightRange < 0 then
        return nil
    end

    local closestPlayer = nil
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

-- Bolt: Optimized stepToward to perform calculations on raw numeric components.
-- Implements a fast-path that returns the target position if the step exceeds the distance,
-- avoiding expensive unit vector and magnitude calculations.
function MonsterLogic.stepToward(currentPosition, targetPosition, speed, dt)
    local cx, cy, cz = currentPosition.X, currentPosition.Y, currentPosition.Z
    local tx, ty, tz = targetPosition.X, targetPosition.Y, targetPosition.Z

    local dx = tx - cx
    local dy = ty - cy
    local dz = tz - cz

    local distSq = dx * dx + dy * dy + dz * dz
    if distSq == 0 then
        return currentPosition
    end

    local maxStep = speed * dt
    -- Bolt: Fast-path if the step covers the remaining distance.
    -- The maxStep >= 0 check preserves original behavior for negative speeds.
    if maxStep >= 0 and maxStep * maxStep >= distSq then
        return targetPosition
    end

    local dist = math.sqrt(distSq)
    local fraction = maxStep / dist

    return Vector3_new(cx + dx * fraction, cy + dy * fraction, cz + dz * fraction)
end

return MonsterLogic
