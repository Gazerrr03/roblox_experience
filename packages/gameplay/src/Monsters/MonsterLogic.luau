local MonsterLogic = {}

-- Bolt: Optimized to use squared distance comparisons and raw component access.
-- This avoids Vector3 metatable overhead and O(N) square root calculations in the loop.
function MonsterLogic.pickNearestTarget(currentPosition, playerPositions, sightRange)
    if sightRange < 0 then
        return nil
    end

    local closestPlayer = nil
    local maxDistSq = sightRange * sightRange

    local cx, cy, cz = currentPosition.X, currentPosition.Y, currentPosition.Z

    for player, position in pairs(playerPositions) do
        local px, py, pz = position.X, position.Y, position.Z
        local dx, dy, dz = px - cx, py - cy, pz - cz
        local distSq = dx * dx + dy * dy + dz * dz

        if distSq <= maxDistSq then
            closestPlayer = player
            maxDistSq = distSq
        end
    end

    return closestPlayer
end

-- Bolt: Optimized with raw component math and a fast-path for reachable targets.
-- Reduces object churn by allocating only one Vector3 result and skipping math when within range.
function MonsterLogic.stepToward(currentPosition, targetPosition, speed, dt)
    local cx, cy, cz = currentPosition.X, currentPosition.Y, currentPosition.Z
    local tx, ty, tz = targetPosition.X, targetPosition.Y, targetPosition.Z

    local dx, dy, dz = tx - cx, ty - cy, tz - cz
    local distSq = dx * dx + dy * dy + dz * dz

    if distSq == 0 then
        return currentPosition
    end

    local maxStep = speed * dt
    -- Fast-path: If we can reach the target in this step, return it directly.
    if maxStep >= 0 and maxStep * maxStep >= distSq then
        return targetPosition
    end

    local dist = math.sqrt(distSq)
    local scale = maxStep / dist
    return Vector3.new(cx + dx * scale, cy + dy * scale, cz + dz * scale)
end

return MonsterLogic
