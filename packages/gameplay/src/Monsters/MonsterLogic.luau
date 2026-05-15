local MonsterLogic = {}

-- Bolt: Optimized to use squared distance and raw numeric component access to avoid Vector3 metatable overhead
function MonsterLogic.pickNearestTarget(currentPosition, playerPositions, sightRange)
    local closestPlayer = nil
    local closestDistanceSq = sightRange * sightRange

    local cx, cy, cz = currentPosition.X, currentPosition.Y, currentPosition.Z

    for player, position in pairs(playerPositions) do
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

-- Bolt: Optimized to use raw numeric component math and early exit to reduce object allocation
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

    local maxStep = speed * dt
    -- If we can reach the target in this step, return target directly
    -- Note: maxStep >= 0 ensures we don't jump to target if moving away (negative speed)
    if maxStep >= 0 and maxStep * maxStep >= distSq then
        return targetPosition
    end

    local distance = math.sqrt(distSq)
    local invDist = maxStep / distance
    return Vector3.new(cx + dx * invDist, cy + dy * invDist, cz + dz * invDist)
end

return MonsterLogic
