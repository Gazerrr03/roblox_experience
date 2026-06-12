local MonsterLogic = {}

-- Bolt: Optimized pickNearestTarget to use squared distance and raw numeric component access.
-- This avoids expensive Vector3.Magnitude calls and metatable overhead in the hot loop.
function MonsterLogic.pickNearestTarget(currentPosition, playerPositions, sightRange)
    -- Bolt: Guard against negative sight range as original distance comparisons would naturally fail.
    if sightRange < 0 then
        return nil
    end

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

-- Bolt: Optimized stepToward to perform raw component math and avoid intermediate Vector3 objects.
-- Reduces GC pressure and metatable dispatch costs significantly.
function MonsterLogic.stepToward(currentPosition, targetPosition, speed, dt)
    local tx, ty, tz = targetPosition.X, targetPosition.Y, targetPosition.Z
    local cx, cy, cz = currentPosition.X, currentPosition.Y, currentPosition.Z

    local dx = tx - cx
    local dy = ty - cy
    local dz = tz - cz

    local distSq = dx * dx + dy * dy + dz * dz
    if distSq == 0 then
        return currentPosition
    end

    local maxStep = speed * dt
    -- Bolt: Check if the step covers the remaining distance.
    -- maxStep >= 0 guard ensures we don't 'jump' to target if moving away (negative speed).
    if maxStep >= 0 and maxStep * maxStep >= distSq then
        return targetPosition
    end

    local dist = math.sqrt(distSq)
    local invDist = 1 / dist

    return Vector3.new(
        cx + dx * invDist * maxStep,
        cy + dy * invDist * maxStep,
        cz + dz * invDist * maxStep
    )
end

return MonsterLogic
