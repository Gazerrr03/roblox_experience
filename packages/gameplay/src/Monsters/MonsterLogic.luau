local MonsterLogic = {}

-- Bolt: Optimized to use squared distance and raw numeric components (X, Y, Z).
-- This avoids Vector3 metatable dispatch and eliminates square root calculations in the search loop.
function MonsterLogic.pickNearestTarget(currentPosition, playerPositions, sightRange)
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

-- Bolt: Optimized to use raw numeric components and a single Vector3 result allocation.
-- This bypasses .Unit and eliminates intermediate object churn.
function MonsterLogic.stepToward(currentPosition, targetPosition, speed, dt)
    local cx, cy, cz = currentPosition.X, currentPosition.Y, currentPosition.Z
    local tx, ty, tz = targetPosition.X, targetPosition.Y, targetPosition.Z

    local dx = tx - cx
    local dy = ty - cy
    local dz = tz - cz

    local distSq = dx * dx + dy * dy + dz * dz

    if distSq == 0 then
        return currentPosition
    end

    local dist = math.sqrt(distSq)
    local maxStep = speed * dt

    local stepDistance
    if maxStep >= 0 then
        stepDistance = if maxStep < dist then maxStep else dist
    else
        stepDistance = maxStep
    end

    local ratio = stepDistance / dist
    return Vector3.new(cx + dx * ratio, cy + dy * ratio, cz + dz * ratio)
end

return MonsterLogic
