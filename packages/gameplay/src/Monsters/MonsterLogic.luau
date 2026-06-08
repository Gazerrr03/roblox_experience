local MonsterLogic = {}

function MonsterLogic.pickNearestTarget(currentPosition, playerPositions, sightRange)
    local closestPlayer = nil
    -- Bolt: Use squared distance to avoid expensive math.sqrt in hot loops
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

function MonsterLogic.stepToward(currentPosition, targetPosition, speed, dt)
    -- Bolt: Avoid redundant Magnitude/Unit calls and use raw component math
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
    -- Bolt: Fast-path for when target is within reach
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
