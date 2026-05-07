local math_sqrt = math.sqrt
local math_min = math.min
local Vector3_new = Vector3.new

local MonsterLogic = {}

-- Bolt: Optimized to use squared distance comparisons and direct numeric coordinate access.
-- This avoids math.sqrt calls and Vector3 object property access overhead in the hot loop.
function MonsterLogic.pickNearestTarget(currentPosition, playerPositions, sightRange)
    local closestPlayer = nil
    local closestDistanceSq = sightRange * sightRange

    local cx, cy, cz = currentPosition.X, currentPosition.Y, currentPosition.Z

    for player, position in pairs(playerPositions) do
        local px, py, pz = position.X, position.Y, position.Z
        local dx = px - cx
        local dy = py - cy
        local dz = pz - cz
        local distanceSq = dx * dx + dy * dy + dz * dz

        if distanceSq <= closestDistanceSq then
            closestPlayer = player
            closestDistanceSq = distanceSq
        end
    end

    return closestPlayer
end

-- Bolt: Optimized to use direct numeric coordinate math.
-- This avoids multiple Vector3 allocations and Unit vector calculation overhead.
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
