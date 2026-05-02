local Vector3_new = Vector3.new
local math_min = math.min
local math_sqrt = math.sqrt

local MonsterLogic = {}

function MonsterLogic.pickNearestTarget(currentPosition, playerPositions, sightRange)
    -- Bolt: Optimized using squared distance and direct numeric component access to avoid Vector3 metatable overhead.
    local closestPlayer = nil
    local closestDistanceSq = sightRange * sightRange

    local cx, cy, cz = currentPosition.X, currentPosition.Y, currentPosition.Z

    for player, position in pairs(playerPositions) do
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
    -- Bolt: Optimized by calculating raw numeric components to reduce Vector3 object allocations and redundant sqrt.
    local cx, cy, cz = currentPosition.X, currentPosition.Y, currentPosition.Z
    local tx, ty, tz = targetPosition.X, targetPosition.Y, targetPosition.Z
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
