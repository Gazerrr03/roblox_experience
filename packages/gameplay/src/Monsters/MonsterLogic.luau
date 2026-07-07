local MonsterLogic = {}

function MonsterLogic.pickNearestTarget(currentPosition, playerPositions, sightRange)
    -- Bolt: Optimized by using squared distance and raw component access to bypass Vector3 metatable
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
    -- Bolt: Optimized by using raw component math and a fast-path for arrival to minimize allocations
    local tx, ty, tz = targetPosition.X, targetPosition.Y, targetPosition.Z
    local cx, cy, cz = currentPosition.X, currentPosition.Y, currentPosition.Z

    local dx = tx - cx
    local dy = ty - cy
    local dz = tz - cz

    local distSq = dx * dx + dy * dy + dz * dz
    if distSq == 0 then
        return currentPosition
    end

    local stepDistance = speed * dt
    -- If we can reach the target in this step, return the target position directly
    if stepDistance * stepDistance >= distSq then
        return targetPosition
    end

    local distance = math.sqrt(distSq)
    local invDist = 1 / distance
    return Vector3.new(
        cx + dx * invDist * stepDistance,
        cy + dy * invDist * stepDistance,
        cz + dz * invDist * stepDistance
    )
end

return MonsterLogic
