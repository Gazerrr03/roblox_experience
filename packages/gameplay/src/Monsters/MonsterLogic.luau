local MonsterLogic = {}

function MonsterLogic.pickNearestTarget(currentPosition, playerPositions, sightRange)
    -- Bolt: Optimized by using squared distance and component-based math to avoid Vector3 metatable overhead.
    local closestPlayer = nil
    local closestDistanceSq = sightRange * sightRange

    if sightRange < 0 then
        return nil
    end

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
    -- Bolt: Optimized to use component-based math and avoid multiple Vector3 allocations and redundant sqrt/Unit calculations.
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
    if distanceSq <= maxStep * maxStep then
        return targetPosition
    end

    local distance = math.sqrt(distanceSq)
    local invDist = 1 / distance

    local stepX = dx * invDist * maxStep
    local stepY = dy * invDist * maxStep
    local stepZ = dz * invDist * maxStep

    return Vector3.new(cx + stepX, cy + stepY, cz + stepZ)
end

return MonsterLogic
