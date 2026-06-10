local MonsterLogic = {}

-- Bolt: pickNearestTarget optimized with squared distance and raw numeric components
-- to eliminate Vector3 allocations and Magnitude (sqrt) overhead in sensing loops.
function MonsterLogic.pickNearestTarget(currentPosition, playerPositions, sightRange)
    -- Bolt: Replicate original behavior where negative range results in no target.
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

-- Bolt: stepToward optimized with component-based math and an overshoot fast-path.
-- Returns the target directly if speed*dt covers the remaining distance, avoiding
-- unit vector and magnitude calculations entirely.
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
    -- Bolt: Fast-path for overshoot. maxStep >= 0 guard preserves original behavior
    -- where negative speed causes the entity to move away from the target.
    if maxStep >= 0 and maxStep * maxStep >= distSq then
        return targetPosition
    end

    local distance = math.sqrt(distSq)
    local invDist = 1 / distance
    local stepDistance = math.min(maxStep, distance)

    return Vector3.new(
        cx + dx * invDist * stepDistance,
        cy + dy * invDist * stepDistance,
        cz + dz * invDist * stepDistance
    )
end

return MonsterLogic
