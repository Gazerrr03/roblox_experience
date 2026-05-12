local math_sqrt = math.sqrt

local MonsterLogic = {}

-- Bolt: Optimized with squared distance comparisons and raw numeric component access
-- to avoid Vector3 metatable dispatch overhead in hot loops.
function MonsterLogic.pickNearestTarget(currentPosition, playerPositions, sightRange)
    local closestPlayer = nil
    local closestDistanceSq = sightRange * sightRange

    local cx, cy, cz = currentPosition.X, currentPosition.Y, currentPosition.Z

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

-- Bolt: Optimized by performing calculations on raw numeric components and allocating
-- only a single final Vector3 result, significantly reducing intermediate object churn.
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
    -- Bolt: maxStep >= 0 check preserves original behavior where negative speed moves away.
    if maxStep >= 0 and maxStep * maxStep >= distSq then
        return targetPosition
    end

    local dist = math_sqrt(distSq)
    local invDist = 1 / dist
    local step = maxStep * invDist

    return Vector3.new(cx + dx * step, cy + dy * step, cz + dz * step)
end

return MonsterLogic
