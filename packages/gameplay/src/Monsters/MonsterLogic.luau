local MonsterLogic = {}

local Vector3_new = Vector3.new

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
    -- Bolt: If we are close enough to reach the target in this step, return target.
    -- The maxStep >= 0 check ensures that if speed is negative, we move away instead of jumping to target.
    if maxStep >= 0 and maxStep * maxStep >= distSq then
        return targetPosition
    end

    local distance = math.sqrt(distSq)
    local fraction = maxStep / distance

    return Vector3_new(cx + dx * fraction, cy + dy * fraction, cz + dz * fraction)
end

return MonsterLogic
