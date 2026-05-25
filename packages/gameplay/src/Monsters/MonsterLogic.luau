local MonsterLogic = {}

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
    -- Bolt: optimization - early exit if target is reached in current step.
    -- Also handles negative speed (moving away) if maxStep < 0.
    if maxStep >= 0 and maxStep * maxStep >= distSq then
        return targetPosition
    end

    local dist = math.sqrt(distSq)
    local invDist = maxStep / dist

    return Vector3.new(cx + dx * invDist, cy + dy * invDist, cz + dz * invDist)
end

return MonsterLogic
