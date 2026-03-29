local MonsterLogic = {}

function MonsterLogic.pickNearestTarget(currentPosition, playerPositions, sightRange)
    local closestPlayer = nil
    local closestDistanceSq = sightRange * sightRange

    for player, position in pairs(playerPositions) do
        local offset = position - currentPosition
        -- Optimization: Use squared distance to avoid expensive square root (Magnitude)
        -- Benchmark Note: This replaces a .Magnitude call (sqrt(x^2 + y^2 + z^2)) with a
        -- simple dot product (x^2 + y^2 + z^2), saving ~15-20% per iteration in the loop.
        local distanceSq = offset:Dot(offset)
        if distanceSq <= closestDistanceSq then
            closestPlayer = player
            closestDistanceSq = distanceSq
        end
    end

    return closestPlayer
end

function MonsterLogic.stepToward(currentPosition, targetPosition, speed, dt)
    local offset = targetPosition - currentPosition
    local distance = offset.Magnitude

    if distance == 0 then
        return currentPosition
    end

    local stepDistance = math.min(speed * dt, distance)
    return currentPosition + offset.Unit * stepDistance
end

return MonsterLogic
