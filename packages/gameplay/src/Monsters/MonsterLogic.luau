local Vector3_new = Vector3.new
local math_min = math.min
local math_sqrt = math.sqrt

local MonsterLogic = {}

-- Bolt: Optimized pickNearestTarget by using squared distance comparisons and direct numeric coordinate access.
-- This avoids the expensive math.sqrt involved in .Magnitude and reduces object property lookup overhead.
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

-- Bolt: Optimized stepToward by performing calculations on raw numeric components.
-- This reduces heap allocations by only creating a single Vector3 result, avoiding intermediate
-- objects for offset, Unit, and scalar multiplication.
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

    local distance = math_sqrt(distanceSq)
    local stepDistance = math_min(speed * dt, distance)
    local ratio = stepDistance / distance

    return Vector3_new(cx + dx * ratio, cy + dy * ratio, cz + dz * ratio)
end

return MonsterLogic
