local MonsterLogic = {}

-- Bolt: Optimized to use squared distance and raw numeric components to avoid Vector3 overhead
function MonsterLogic.pickNearestTarget(currentPosition, playerPositions, sightRange)
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

-- Bolt: Optimized with component-wise math to minimize intermediate Vector3 allocations
function MonsterLogic.stepToward(currentPosition, targetPosition, speed, dt)
    local tx, ty, tz = targetPosition.X, targetPosition.Y, targetPosition.Z
    local cx, cy, cz = currentPosition.X, currentPosition.Y, currentPosition.Z

    local dx = tx - cx
    local dy = ty - cy
    local dz = tz - cz

    local distSq = dx * dx + dy * dy + dz * dz

    if distSq == 0 then
        return currentPosition
    end

    local maxStep = speed * dt
    -- If we can reach or overshoot the target in this step, return target directly.
    -- We check distSq against maxStep^2 to avoid sqrt.
    -- We also check if maxStep is positive to preserve original behavior (negative speed moves away).
    if maxStep >= 0 and maxStep * maxStep >= distSq then
        return targetPosition
    end

    local dist = math.sqrt(distSq)
    local invDist = 1 / dist
    local stepX = dx * invDist * maxStep
    local stepY = dy * invDist * maxStep
    local stepZ = dz * invDist * maxStep

    return Vector3.new(cx + stepX, cy + stepY, cz + stepZ)
end

return MonsterLogic
