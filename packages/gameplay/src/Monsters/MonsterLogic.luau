local MonsterLogic = {}

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
    -- Bolt: Early exit if the step covers the entire distance to avoid unit vector overhead.
    -- We check maxStep >= 0 to ensure we don't jump to the target if speed is negative.
    if maxStep >= 0 and maxStep * maxStep >= distSq then
        return targetPosition
    end

    local distance = math.sqrt(distSq)
    local invDist = 1 / distance
    local step = math.min(maxStep, distance)

    return Vector3.new(cx + dx * invDist * step, cy + dy * invDist * step, cz + dz * invDist * step)
end

return MonsterLogic
