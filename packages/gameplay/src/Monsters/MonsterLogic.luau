local MonsterLogic = {}

-- Bolt: Optimized pickNearestTarget using squared distance and raw numeric component access
-- to avoid Vector3 metatable overhead and math.sqrt in the hot loop.
function MonsterLogic.pickNearestTarget(currentPosition, playerPositions, sightRange)
    -- Bolt: Early exit for invalid range
    if sightRange < 0 then
        return nil
    end

    local closestPlayer = nil
    local closestDistanceSq = sightRange * sightRange

    -- Use explicit numeric components to avoid metatable indexing in the loop
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

-- Bolt: Optimized stepToward by using raw numeric components and implementing an early exit
-- when the step distance exceeds the remaining distance, avoiding expensive unit vector math.
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

    -- Bolt: Fast-path for when the target is within one step, avoiding sqrt and division.
    -- maxStep >= 0 check preserves original behavior for negative speeds.
    if maxStep >= 0 and maxStep * maxStep >= distSq then
        return targetPosition
    end

    local distance = math.sqrt(distSq)
    local stepDistance = math.min(maxStep, distance)
    local invDist = stepDistance / distance

    return Vector3.new(
        cx + dx * invDist,
        cy + dy * invDist,
        cz + dz * invDist
    )
end

return MonsterLogic
