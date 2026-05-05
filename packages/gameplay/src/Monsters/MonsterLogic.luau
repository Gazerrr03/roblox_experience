local math_min = math.min
local math_sqrt = math.sqrt
local Vector3_new = Vector3.new

local MonsterLogic = {}

-- Bolt: Optimized pickNearestTarget to use squared distance comparisons and direct numeric coordinate access,
-- reducing Vector3 object churn and avoiding unnecessary math.sqrt calls in high-frequency AI ticks.
function MonsterLogic.pickNearestTarget(currentPosition, playerPositions, sightRange)
    local closestPlayer = nil
    local closestDistanceSq = sightRange * sightRange

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

-- Bolt: Optimized stepToward to perform calculations on raw numeric components and avoid redundant
-- magnitude calculations from the .Unit property, resulting in fewer heap allocations.
function MonsterLogic.stepToward(currentPosition, targetPosition, speed, dt)
    local ox = targetPosition.X - currentPosition.X
    local oy = targetPosition.Y - currentPosition.Y
    local oz = targetPosition.Z - currentPosition.Z
    local distanceSq = ox * ox + oy * oy + oz * oz

    if distanceSq == 0 then
        return currentPosition
    end

    local distance = math_sqrt(distanceSq)
    local stepDistance = math_min(speed * dt, distance)
    local ratio = stepDistance / distance

    return Vector3_new(
        currentPosition.X + ox * ratio,
        currentPosition.Y + oy * ratio,
        currentPosition.Z + oz * ratio
    )
end

return MonsterLogic
