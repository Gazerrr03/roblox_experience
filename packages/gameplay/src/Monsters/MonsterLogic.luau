local MonsterLogic = {}

function MonsterLogic.pickNearestTarget(currentPosition, playerPositions, sightRange)
    if sightRange < 0 then
        return nil
    end

    local closestPlayer = nil
    -- Bolt: Use squared distance to avoid expensive math.sqrt in the loop
    local closestDistanceSq = sightRange * sightRange

    -- Bolt: Cache components to avoid repeated Vector3 metatable property lookups
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

function MonsterLogic.stepToward(currentPosition, targetPosition, speed, dt)
    local stepDistance = speed * dt

    local tx, ty, tz = targetPosition.X, targetPosition.Y, targetPosition.Z
    local cx, cy, cz = currentPosition.X, currentPosition.Y, currentPosition.Z

    local dx = tx - cx
    local dy = ty - cy
    local dz = tz - cz
    local distanceSq = dx * dx + dy * dy + dz * dz

    -- Bolt: Fast-path for arrival (no square root or allocation needed)
    if distanceSq <= stepDistance * stepDistance then
        return targetPosition
    end

    local distance = math.sqrt(distanceSq)
    if distance == 0 then
        return currentPosition
    end

    -- Bolt: Manual vector construction to minimize object churn and metatable overhead
    local invDistance = 1 / distance
    return Vector3.new(
        cx + dx * invDistance * stepDistance,
        cy + dy * invDistance * stepDistance,
        cz + dz * invDistance * stepDistance
    )
end

return MonsterLogic
