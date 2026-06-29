local MonsterLogic = {}

-- Optimized monster logic functions for high-frequency runtime use.
-- Utilizes raw numeric component math to bypass Vector3 metatable dispatch and reduce GC pressure.

function MonsterLogic.pickNearestTarget(currentPosition, playerPositions, sightRange)
    local closestPlayer = nil

    -- Use squared distance comparison to avoid expensive square root calculations
    -- sightRange < 0 guard preserves original behavior where negative range comparisons naturally fail
    local closestDistanceSq = sightRange * sightRange
    if sightRange < 0 then
        closestDistanceSq = -1
    end

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

    local distance = math.sqrt(distanceSq)
    local maxStep = speed * dt

    -- Fast-path for arrival: if we can reach the target this frame, return target directly.
    -- Also avoids potential precision issues with unit vector scaling near zero distance.
    if maxStep >= distance then
        return targetPosition
    end

    local fraction = maxStep / distance
    return Vector3.new(cx + dx * fraction, cy + dy * fraction, cz + dz * fraction)
end

return MonsterLogic
