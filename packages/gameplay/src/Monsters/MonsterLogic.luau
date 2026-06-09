local MonsterLogic = {}

-- Bolt: Optimizing pickNearestTarget to use squared distance and direct component access.
-- This avoids multiple Vector3 allocations and expensive Magnitude calculations in the hot path.
function MonsterLogic.pickNearestTarget(currentPosition, playerPositions, sightRange)
    local closestPlayer = nil

    if sightRange < 0 then
        return nil
    end

    local maxDistSq = sightRange * sightRange
    local closestDistSq = maxDistSq

    local cx, cy, cz = currentPosition.X, currentPosition.Y, currentPosition.Z

    for player, position in pairs(playerPositions) do
        local dx = position.X - cx
        local dy = position.Y - cy
        local dz = position.Z - cz
        local distSq = dx * dx + dy * dy + dz * dz

        if distSq <= closestDistSq then
            closestPlayer = player
            closestDistSq = distSq
        end
    end

    return closestPlayer
end

-- Bolt: Optimizing stepToward to use raw component math and a fast-path for target arrival.
-- This reduces Vector3 allocations and skips expensive operations when the target is reachable.
function MonsterLogic.stepToward(currentPosition, targetPosition, speed, dt)
    local maxStep = speed * dt
    local ox = targetPosition.X - currentPosition.X
    local oy = targetPosition.Y - currentPosition.Y
    local oz = targetPosition.Z - currentPosition.Z

    local distSq = ox * ox + oy * oy + oz * oz

    if distSq == 0 then
        return currentPosition
    end

    -- Fast-path: if we can reach the target in this step, return it directly.
    -- We check maxStep >= 0 to ensure we don't jump to target if speed is negative.
    if maxStep >= 0 and maxStep * maxStep >= distSq then
        return targetPosition
    end

    local distance = math.sqrt(distSq)
    local stepDistance = math.min(maxStep, distance)
    local invDist = 1 / distance

    return Vector3.new(
        currentPosition.X + ox * invDist * stepDistance,
        currentPosition.Y + oy * invDist * stepDistance,
        currentPosition.Z + oz * invDist * stepDistance
    )
end

return MonsterLogic
