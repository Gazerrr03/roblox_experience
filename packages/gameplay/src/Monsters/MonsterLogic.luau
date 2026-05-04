local MonsterLogic = {}

-- Bolt: Optimized with squared distance and direct component access to avoid Vector3 allocations and redundant square roots.
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

-- Bolt: Optimized to minimize Vector3 allocations and redundant Magnitude/Unit calculations.
function MonsterLogic.stepToward(currentPosition, targetPosition, speed, dt)
    local cx, cy, cz = currentPosition.X, currentPosition.Y, currentPosition.Z
    local tx, ty, tz = targetPosition.X, targetPosition.Y, targetPosition.Z

    local dx = tx - cx
    local dy = ty - cy
    local dz = tz - cz

    local distSq = dx * dx + dy * dy + dz * dz

    if distSq <= 1e-8 then
        return currentPosition
    end

    local distance = math.sqrt(distSq)
    local maxStep = speed * dt
    local ratio = if maxStep >= distance then 1 else maxStep / distance

    return Vector3.new(cx + dx * ratio, cy + dy * ratio, cz + dz * ratio)
end

return MonsterLogic
