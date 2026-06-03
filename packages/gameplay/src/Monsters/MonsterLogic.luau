local MonsterLogic = {}

-- Bolt: Optimized to use squared distance to avoid math.sqrt in the loop.
-- This reduces Vector3 allocations and CPU cycles for distance comparisons.
function MonsterLogic.pickNearestTarget(currentPosition, playerPositions, sightRange)
    local closestPlayer = nil

    -- Bolt: Negative sight range should naturally fail all distance checks
    if sightRange < 0 then
        return nil
    end

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

-- Bolt: Optimized with raw component math to reduce Vector3 churn.
-- Includes a fast-path for target arrival/overshoot to avoid unit vector calculations.
function MonsterLogic.stepToward(currentPosition, targetPosition, speed, dt)
    local tx, ty, tz = targetPosition.X, targetPosition.Y, targetPosition.Z
    local cx, cy, cz = currentPosition.X, currentPosition.Y, currentPosition.Z

    local ox = tx - cx
    local oy = ty - cy
    local oz = tz - cz
    local distSq = ox * ox + oy * oy + oz * oz

    if distSq == 0 then
        return currentPosition
    end

    local maxStep = speed * dt
    -- Bolt: Fast-path for arrival/overshoot. Avoids math.sqrt and Unit normalization.
    -- maxStep >= 0 check ensures we preserve negative speed behavior (moving away).
    if maxStep >= 0 and maxStep * maxStep >= distSq then
        return targetPosition
    end

    local distance = math.sqrt(distSq)
    local invDist = 1 / distance
    local stepX = ox * invDist * maxStep
    local stepY = oy * invDist * maxStep
    local stepZ = oz * invDist * maxStep

    return Vector3.new(cx + stepX, cy + stepY, cz + stepZ)
end

return MonsterLogic
