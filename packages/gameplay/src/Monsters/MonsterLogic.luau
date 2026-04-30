-- Bolt: Optimized logic for high-frequency monster AI routines.
-- Reduces Vector3 allocation churn and avoids square root operations in hot paths.

local math_min = math.min
local math_sqrt = math.sqrt
local Vector3_new = Vector3.new

local MonsterLogic = {}

function MonsterLogic.pickNearestTarget(currentPosition, playerPositions, sightRange)
    local closestPlayer = nil
    -- Bolt: Use squared distance to avoid math.sqrt calls in the search loop
    local closestDistanceSq = sightRange * sightRange

    local cx, cy, cz = currentPosition.X, currentPosition.Y, currentPosition.Z

    for player, position in pairs(playerPositions) do
        -- Bolt: Direct numeric coordinate access to avoid Vector3 metatable overhead
        local px, py, pz = position.X, position.Y, position.Z
        local dx = px - cx
        local dy = py - cy
        local dz = pz - cz
        local distSq = dx * dx + dy * dy + dz * dz

        if distSq <= closestDistanceSq then
            closestPlayer = player
            closestDistanceSq = distSq
        end
    end

    return closestPlayer
end

function MonsterLogic.stepToward(currentPosition, targetPosition, speed, dt)
    local cx, cy, cz = currentPosition.X, currentPosition.Y, currentPosition.Z
    local tx, ty, tz = targetPosition.X, targetPosition.Y, targetPosition.Z

    local dx = tx - cx
    local dy = ty - cy
    local dz = tz - cz

    local distanceSq = dx * dx + dy * dy + dz * dz
    if distanceSq == 0 then
        return currentPosition
    end

    -- Bolt: Calculate step using raw components to avoid temporary Vector3.Unit and subtraction objects
    local distance = math_sqrt(distanceSq)
    local stepDistance = math_min(speed * dt, distance)
    local ratio = stepDistance / distance

    return Vector3_new(cx + dx * ratio, cy + dy * ratio, cz + dz * ratio)
end

return MonsterLogic
