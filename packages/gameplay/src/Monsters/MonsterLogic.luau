local MonsterLogic = {}

function MonsterLogic.pickNearestTarget(currentPosition, playerPositions, sightRange)
    -- Bolt: Use squared distance to avoid expensive math.sqrt (Magnitude) in the loop.
    -- Bolt: sightRange < 0 guard prevents negative ranges from becoming positive when squared.
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

function MonsterLogic.stepToward(currentPosition, targetPosition, speed, dt)
    local tx, ty, tz = targetPosition.X, targetPosition.Y, targetPosition.Z
    local cx, cy, cz = currentPosition.X, currentPosition.Y, currentPosition.Z

    local ox = tx - cx
    local oy = ty - cy
    local oz = tz - cz

    -- Bolt: Use squared distance for the initial check to avoid math.sqrt.
    local distanceSq = ox * ox + oy * oy + oz * oz
    if distanceSq == 0 then
        return currentPosition
    end

    local distance = math.sqrt(distanceSq)
    local stepDistance = speed * dt

    -- Bolt: Return target position directly if we would overshoot, avoiding unit vector math.
    if stepDistance >= distance then
        return targetPosition
    end

    -- Bolt: Perform calculations on raw components to minimize Vector3 object churn.
    local invDist = 1 / distance
    return Vector3.new(
        cx + ox * invDist * stepDistance,
        cy + oy * invDist * stepDistance,
        cz + oz * invDist * stepDistance
    )
end

return MonsterLogic
