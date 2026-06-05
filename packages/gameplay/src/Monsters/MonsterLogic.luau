local MonsterLogic = {}

function MonsterLogic.pickNearestTarget(currentPosition, playerPositions, sightRange)
    -- Bolt: Using squared distance and unpacking Vector3 components to avoid
    -- redundant magnitude calculations and property lookups in the hot path.
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
            closestDistanceSq = distSq
            closestPlayer = player
        end
    end

    return closestPlayer
end

function MonsterLogic.stepToward(currentPosition, targetPosition, speed, dt)
    -- Bolt: Using raw component math and a fast-path for overshooting the target.
    -- This avoids intermediate Vector3 object allocations and reduces calculation overhead.
    local cx, cy, cz = currentPosition.X, currentPosition.Y, currentPosition.Z
    local tx, ty, tz = targetPosition.X, targetPosition.Y, targetPosition.Z
    local ox = tx - cx
    local oy = ty - cy
    local oz = tz - cz
    local distSq = ox * ox + oy * oy + oz * oz

    if distSq == 0 then
        return currentPosition
    end

    local maxStep = speed * dt
    -- If we can reach or overshoot the target in this step, return the target position directly.
    if maxStep >= 0 and maxStep * maxStep >= distSq then
        return targetPosition
    end

    local distance = math.sqrt(distSq)
    local stepDistance = math.min(maxStep, distance)
    local invDist = stepDistance / distance

    return Vector3.new(cx + ox * invDist, cy + oy * invDist, cz + oz * invDist)
end

return MonsterLogic
