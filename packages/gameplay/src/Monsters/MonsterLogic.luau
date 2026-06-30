local MonsterLogic = {}

local Vector3_new = Vector3.new
local math_sqrt = math.sqrt

function MonsterLogic.pickNearestTarget(currentPosition, playerPositions, sightRange)
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
        local dSq = dx * dx + dy * dy + dz * dz

        if dSq <= closestDistanceSq then
            closestPlayer = player
            closestDistanceSq = dSq
        end
    end

    return closestPlayer
end

function MonsterLogic.stepToward(currentPosition, targetPosition, speed, dt)
    local dx = targetPosition.X - currentPosition.X
    local dy = targetPosition.Y - currentPosition.Y
    local dz = targetPosition.Z - currentPosition.Z
    local dSq = dx * dx + dy * dy + dz * dz

    if dSq == 0 then
        return currentPosition
    end

    local stepDistance = speed * dt
    if dSq <= stepDistance * stepDistance then
        return targetPosition
    end

    local distance = math_sqrt(dSq)
    local invDist = stepDistance / distance
    return Vector3_new(
        currentPosition.X + dx * invDist,
        currentPosition.Y + dy * invDist,
        currentPosition.Z + dz * invDist
    )
end

return MonsterLogic
