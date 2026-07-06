local MonsterLogic = {}

-- Optimized target selection using squared distance to avoid expensive square root (Magnitude) calculations
-- and raw coordinate access to bypass Vector3 metatable overhead.
function MonsterLogic.pickNearestTarget(currentPosition, playerPositions, sightRange)
    if sightRange < 0 then
        return nil
    end

    local closestPlayer = nil
    local closestDistanceSq = sightRange * sightRange

    local cx, cy, cz = currentPosition.X, currentPosition.Y, currentPosition.Z

    for player, position in pairs(playerPositions) do
        local px, py, pz = position.X, position.Y, position.Z
        local dx = px - cx
        local dy = py - cy
        local dz = pz - cz
        local dSq = dx * dx + dy * dy + dz * dz

        if dSq <= closestDistanceSq then
            closestPlayer = player
            closestDistanceSq = dSq
        end
    end

    return closestPlayer
end

-- Optimized movement using raw component math and a fast-path for arrival to minimize Vector3 allocations.
function MonsterLogic.stepToward(currentPosition, targetPosition, speed, dt)
    local cx, cy, cz = currentPosition.X, currentPosition.Y, currentPosition.Z
    local tx, ty, tz = targetPosition.X, targetPosition.Y, targetPosition.Z

    local dx = tx - cx
    local dy = ty - cy
    local dz = tz - cz

    if dx == 0 and dy == 0 and dz == 0 then
        return currentPosition
    end

    local dSq = dx * dx + dy * dy + dz * dz
    local step = speed * dt

    -- Arrival fast-path: return target if we can reach it in this step
    if dSq <= step * step then
        return targetPosition
    end

    local d = math.sqrt(dSq)
    return Vector3.new(cx + (dx / d) * step, cy + (dy / d) * step, cz + (dz / d) * step)
end

return MonsterLogic
