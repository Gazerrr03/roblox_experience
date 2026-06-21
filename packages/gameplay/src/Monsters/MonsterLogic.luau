local MonsterLogic = {}

-- Bolt: Optimized to use squared distance comparisons and raw numeric components to avoid Vector3 overhead.
function MonsterLogic.pickNearestTarget(currentPosition, playerPositions, sightRange)
    -- Bolt: Guard against negative sightRange to maintain original behavior (negative distance check would fail).
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

-- Bolt: Optimized to use raw numeric components and a fast-path for arrival to avoid Unit and Magnitude overhead.
function MonsterLogic.stepToward(currentPosition, targetPosition, speed, dt)
    local ox = targetPosition.X - currentPosition.X
    local oy = targetPosition.Y - currentPosition.Y
    local oz = targetPosition.Z - currentPosition.Z
    local distanceSq = ox * ox + oy * oy + oz * oz

    if distanceSq == 0 then
        return currentPosition
    end

    local maxStep = speed * dt
    -- Bolt: Fast-path for arrival: if the step exceeds the remaining distance, return the target position directly.
    if distanceSq <= maxStep * maxStep then
        return targetPosition
    end

    local distance = math.sqrt(distanceSq)
    local invDist = maxStep / distance
    return Vector3.new(
        currentPosition.X + ox * invDist,
        currentPosition.Y + oy * invDist,
        currentPosition.Z + oz * invDist
    )
end

return MonsterLogic
