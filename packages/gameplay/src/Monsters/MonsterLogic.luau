local MonsterLogic = {}

function MonsterLogic.pickNearestTarget(currentPosition, playerPositions, sightRange)
    local closestPlayer = nil
    local closestDistance = sightRange

    for player, position in pairs(playerPositions) do
        local distance = (position - currentPosition).Magnitude
        if distance <= closestDistance then
            closestPlayer = player
            closestDistance = distance
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
