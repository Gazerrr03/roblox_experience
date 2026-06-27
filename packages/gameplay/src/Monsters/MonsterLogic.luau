local MonsterLogic = {}

local Vector3_new = Vector3.new

function MonsterLogic.pickNearestTarget(currentPosition, playerPositions, sightRange)
    local closestPlayer = nil
    -- Bolt: Use squared distance to avoid expensive math.sqrt in Magnitude calculations
    local closestDistanceSq = sightRange * sightRange

    -- Bolt: Hoist current coordinates to avoid repetitive property access in the loop
    local cx, cy, cz = currentPosition.X, currentPosition.Y, currentPosition.Z

    -- Bolt: Handle negative sightRange to maintain original behavior (negative distance check)
    if sightRange < 0 then
        return nil
    end

    for player, position in pairs(playerPositions) do
        local dx = position.X - cx
        local dy = position.Y - cy
        local dz = position.Z - cz
        local distanceSq = dx * dx + dy * dy + dz * dz

        if distanceSq <= closestDistanceSq then
            closestPlayer = player
            closestDistanceSq = distanceSq
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

    -- Bolt: Squared distance check to avoid math.sqrt when already at target or within one step
    local distanceSq = dx * dx + dy * dy + dz * dz
    if distanceSq == 0 then
        return currentPosition
    end

    local maxStep = speed * dt
    -- Bolt: Fast-path for arrival to avoid Magnitude and Unit calculations
    if distanceSq <= maxStep * maxStep then
        return targetPosition
    end

    local distance = math.sqrt(distanceSq)
    local invDistance = 1 / distance

    -- Bolt: Numeric component math avoids multiple Vector3 object allocations
    return Vector3_new(
        cx + dx * invDistance * maxStep,
        cy + dy * invDistance * maxStep,
        cz + dz * invDistance * maxStep
    )
end

return MonsterLogic
