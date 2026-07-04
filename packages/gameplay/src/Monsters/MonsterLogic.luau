local MonsterLogic = {}

-- Bolt: Optimized to use squared distance and raw component math to bypass Vector3 metatable overhead.
function MonsterLogic.pickNearestTarget(currentPosition, playerPositions, sightRange)
    local closestPlayer = nil
    -- Preserving original behavior where negative sightRange results in no target.
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

-- Bolt: Optimized with a fast-path for arrival and pure numeric math to reduce object churn and metatable dispatch.
function MonsterLogic.stepToward(currentPosition, targetPosition, speed, dt)
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
    -- Fast-path: If the step exceeds the remaining distance, we have arrived.
    if distanceSq <= maxStep * maxStep then
        return targetPosition
    end

    local distance = math.sqrt(distanceSq)
    local ratio = maxStep / distance

    return Vector3.new(cx + dx * ratio, cy + dy * ratio, cz + dz * ratio)
end

return MonsterLogic
