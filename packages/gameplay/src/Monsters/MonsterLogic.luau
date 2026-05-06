local MonsterLogic = {}

function MonsterLogic.pickNearestTarget(currentPosition, playerPositions, sightRange)
    local closestPlayer = nil
    local closestDistanceSq = sightRange * sightRange

    local cx, cy, cz = currentPosition.X, currentPosition.Y, currentPosition.Z

    for player, position in pairs(playerPositions) do
        -- Bolt: Use squared distance and direct numeric access to avoid Vector3 allocations and math.sqrt
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

local Vector3_new = Vector3.new

function MonsterLogic.stepToward(currentPosition, targetPosition, speed, dt)
    -- Bolt: Decompose to numeric components to minimize intermediate Vector3 allocations
    local cx, cy, cz = currentPosition.X, currentPosition.Y, currentPosition.Z
    local tx, ty, tz = targetPosition.X, targetPosition.Y, targetPosition.Z

    local dx = tx - cx
    local dy = ty - cy
    local dz = tz - cz

    local distanceSq = dx * dx + dy * dy + dz * dz
    if distanceSq == 0 then
        return currentPosition
    end

    local distance = math.sqrt(distanceSq)
    local stepDistance = math.min(speed * dt, distance)
    local alpha = stepDistance / distance

    return Vector3_new(cx + dx * alpha, cy + dy * alpha, cz + dz * alpha)
end

return MonsterLogic
