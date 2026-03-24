local MonsterLogic = {}

function MonsterLogic.pickNearestTarget(currentPosition, playerPositions, sightRange)
    local closestPlayer = nil
    local closestDistanceSq = sightRange * sightRange

    for player, position in pairs(playerPositions) do
        local offset = position - currentPosition
        -- Optimization: Use squared distance to avoid expensive square root (Magnitude)
        local distanceSq = offset.X * offset.X + offset.Y * offset.Y + offset.Z * offset.Z
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
