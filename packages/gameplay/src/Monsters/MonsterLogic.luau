local MonsterLogic = {}

function MonsterLogic.pickNearestTarget(currentPosition, playerPositions, sightRange)
    -- Bolt: Negative sight range naturally fails distance comparison, but we guard it
    -- explicitly to avoid squared range becoming positive.
    if sightRange < 0 then
        return nil
    end

    local closestPlayer = nil
    local closestDistanceSq = sightRange * sightRange

    -- Bolt: Access raw components once to avoid multiple metatable lookups in the loop.
    local cx, cy, cz = currentPosition.X, currentPosition.Y, currentPosition.Z

    for player, position in pairs(playerPositions) do
        -- Bolt: Use squared distance to avoid expensive math.sqrt in Vector3.Magnitude.
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

    -- Bolt: Fast-path for arrival avoids unit vector and magnitude calculations.
    local stepDistance = speed * dt
    if stepDistance * stepDistance >= distanceSq then
        return targetPosition
    end

    -- Bolt: Perform math on raw components and allocate only one result Vector3.
    local distance = math.sqrt(distanceSq)
    local invDist = 1 / distance
    return Vector3.new(
        cx + dx * invDist * stepDistance,
        cy + dy * invDist * stepDistance,
        cz + dz * invDist * stepDistance
    )
end

return MonsterLogic
