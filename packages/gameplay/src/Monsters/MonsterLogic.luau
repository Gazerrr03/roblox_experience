local MonsterLogic = {}

function MonsterLogic.pickNearestTarget(currentPosition, playerPositions, sightRange)
    local closestPlayer = nil
    local closestDistanceSq = sightRange * sightRange

    -- Bolt: Explicit guard for negative sight range to match original behavior where
    -- negative ranges naturally failed distance comparisons.
    if sightRange < 0 then
        return nil
    end

    -- Bolt: Hoist current position coordinates to avoid repeated metatable indexing.
    local cx, cy, cz = currentPosition.X, currentPosition.Y, currentPosition.Z

    for player, position in pairs(playerPositions) do
        -- Bolt: Use squared distance and raw component math to avoid math.sqrt and metatable overhead.
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

    -- Bolt: Fast-path for cases where the target is reachable in one step.
    -- The maxStep >= 0 check preserves behavior where negative speed moves away from target.
    if maxStep >= 0 and maxStep * maxStep >= distSq then
        return targetPosition
    end

    local dist = math.sqrt(distSq)
    local invDist = 1 / dist

    -- Bolt: Perform math on raw components and allocate only a single final Vector3 result.
    return Vector3.new(
        cx + dx * invDist * maxStep,
        cy + dy * invDist * maxStep,
        cz + dz * invDist * maxStep
    )
end

return MonsterLogic
