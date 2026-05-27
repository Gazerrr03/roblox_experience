local Vector3_new = Vector3.new

local MonsterLogic = {}

-- Bolt: Optimized to use squared distance comparisons and raw component access to avoid Vector3 metatable overhead and square root operations in the hot loop.
function MonsterLogic.pickNearestTarget(currentPosition, playerPositions, sightRange)
    local closestPlayer = nil
    local closestDistanceSq = if sightRange < 0 then -1 else sightRange * sightRange

    local cx, cy, cz = currentPosition.X, currentPosition.Y, currentPosition.Z

    for player, position in pairs(playerPositions) do
        local dx = position.X - cx
        local dy = position.Y - cy
        local dz = position.Z - cz
        local distanceSq = dx * dx + dy * dy + dz * dz

        if distanceSq <= closestDistanceSq then
            closestPlayer = player
            closestDistanceSq = distanceSq
        end
    end

    return closestPlayer
end

-- Bolt: Optimized to perform component-wise math and avoid .Unit property access, reducing intermediate Vector3 allocations.
-- Also includes a fast-path for steps that exceed the remaining distance.
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
    if maxStep >= 0 and maxStep * maxStep >= distSq then
        return targetPosition
    end

    local distance = math.sqrt(distSq)
    local invDist = 1 / distance
    local stepX = dx * invDist * maxStep
    local stepY = dy * invDist * maxStep
    local stepZ = dz * invDist * maxStep

    return Vector3_new(cx + stepX, cy + stepY, cz + stepZ)
end

return MonsterLogic
