local MonsterLogic = {}

local Vector3_new = Vector3.new

function MonsterLogic.pickNearestTarget(currentPosition, playerPositions, sightRange)
    -- Bolt: Optimized to use squared distance and raw numeric components to avoid Vector3 allocations and magnitude calculations.
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

function MonsterLogic.stepToward(currentPosition, targetPosition, speed, dt)
    -- Bolt: Optimized with raw numeric math to minimize intermediate Vector3 allocations.
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
    if maxStep >= 0 and maxStep * maxStep >= distSq then
        return targetPosition
    end

    local dist = math.sqrt(distSq)
    local stepDistance = math.min(maxStep, dist)
    local ratio = stepDistance / dist

    return Vector3_new(cx + dx * ratio, cy + dy * ratio, cz + dz * ratio)
end

return MonsterLogic
