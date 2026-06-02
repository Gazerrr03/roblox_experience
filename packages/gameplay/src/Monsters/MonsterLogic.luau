local MonsterLogic = {}

function MonsterLogic.pickNearestTarget(currentPosition, playerPositions, sightRange)
    local closestPlayer = nil
    -- Bolt: Use squared distance to avoid expensive math.sqrt in Magnitude calls.
    -- We must guard against negative sightRange to maintain original behavior.
    local closestDistSq = if sightRange < 0 then -1 else sightRange * sightRange

    -- Bolt: Access X, Y, Z components directly to avoid Vector3 metatable overhead.
    local cx, cy, cz = currentPosition.X, currentPosition.Y, currentPosition.Z

    for player, position in pairs(playerPositions) do
        local dx = position.X - cx
        local dy = position.Y - cy
        local dz = position.Z - cz
        local distSq = dx * dx + dy * dy + dz * dz

        if distSq <= closestDistSq then
            closestPlayer = player
            closestDistSq = distSq
        end
    end

    return closestPlayer
end

function MonsterLogic.stepToward(currentPosition, targetPosition, speed, dt)
    -- Bolt: Access X, Y, Z components directly to avoid intermediate Vector3 objects.
    local ox = targetPosition.X - currentPosition.X
    local oy = targetPosition.Y - currentPosition.Y
    local oz = targetPosition.Z - currentPosition.Z
    local distSq = ox * ox + oy * oy + oz * oz

    if distSq == 0 then
        return currentPosition
    end

    local maxStep = speed * dt
    -- Bolt: Fast-path for overshoot. If maxStep covers the distance, return target.
    -- We check maxStep >= 0 to preserve movement-away behavior for negative speeds.
    if maxStep >= 0 and maxStep * maxStep >= distSq then
        return targetPosition
    end

    local dist = math.sqrt(distSq)
    local invDist = maxStep / dist
    return Vector3.new(
        currentPosition.X + ox * invDist,
        currentPosition.Y + oy * invDist,
        currentPosition.Z + oz * invDist
    )
end

return MonsterLogic
