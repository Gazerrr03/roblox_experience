local MonsterLogic = {}

function MonsterLogic.pickNearestTarget(currentPosition, playerPositions, sightRange)
    -- Negative sight range should never match any target
    if sightRange < 0 then
        return nil
    end

    local closestPlayer = nil
    local closestDistanceSq = sightRange * sightRange

    -- Use numeric components to avoid Vector3 metatable overhead
    local cx, cy, cz = currentPosition.X, currentPosition.Y, currentPosition.Z

    for player, position in pairs(playerPositions) do
        local px, py, pz = position.X, position.Y, position.Z
        local dx = px - cx
        local dy = py - cy
        local dz = pz - cz

        -- Squared distance comparison avoids expensive math.sqrt
        local distSq = dx * dx + dy * dy + dz * dz
        if distSq <= closestDistanceSq then
            closestPlayer = player
            closestDistanceSq = distSq
        end
    end

    return closestPlayer
end

function MonsterLogic.stepToward(currentPosition, targetPosition, speed, dt)
    local tx, ty, tz = targetPosition.X, targetPosition.Y, targetPosition.Z
    local cx, cy, cz = currentPosition.X, currentPosition.Y, currentPosition.Z

    local dx = tx - cx
    local dy = ty - cy
    local dz = tz - cz

    -- Squared distance check for early exit/target arrival
    local distSq = dx * dx + dy * dy + dz * dz
    if distSq == 0 then
        return currentPosition
    end

    local maxStep = speed * dt
    if distSq <= maxStep * maxStep then
        -- We can reach the target in this step; avoid all Unit/Magnitude math
        return targetPosition
    end

    -- Normalizing manually avoids intermediate Vector3 allocations for .Unit
    local dist = math.sqrt(distSq)
    local invDist = maxStep / dist

    return Vector3.new(cx + dx * invDist, cy + dy * invDist, cz + dz * invDist)
end

return MonsterLogic
