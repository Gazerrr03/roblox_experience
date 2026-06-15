local math_sqrt = math.sqrt
local Vector3_new = Vector3.new

local MonsterLogic = {}

function MonsterLogic.pickNearestTarget(currentPosition, playerPositions, sightRange)
    -- Bolt: Optimized with squared distance and raw coordinate access to avoid Vector3 overhead.
    if sightRange < 0 then
        return nil
    end

    local closestPlayer = nil
    local closestDistanceSq = sightRange * sightRange
    local px, py, pz = currentPosition.X, currentPosition.Y, currentPosition.Z

    for player, position in pairs(playerPositions) do
        local dx = position.X - px
        local dy = position.Y - py
        local dz = position.Z - pz
        local distSq = dx * dx + dy * dy + dz * dz

        if distSq <= closestDistanceSq then
            closestPlayer = player
            closestDistanceSq = distSq
        end
    end

    return closestPlayer
end

function MonsterLogic.stepToward(currentPosition, targetPosition, speed, dt)
    -- Bolt: Optimized by calculating step on raw components and using a fast-path for arrival.
    local px, py, pz = currentPosition.X, currentPosition.Y, currentPosition.Z
    local tx, ty, tz = targetPosition.X, targetPosition.Y, targetPosition.Z

    local dx = tx - px
    local dy = ty - py
    local dz = tz - pz

    local distSq = dx * dx + dy * dy + dz * dz
    if distSq == 0 then
        return currentPosition
    end

    local maxStep = speed * dt
    if distSq <= maxStep * maxStep then
        return targetPosition
    end

    local dist = math_sqrt(distSq)
    local invDist = 1 / dist

    -- Bolt: If we're here, maxStep < dist, so we move exactly maxStep.
    return Vector3_new(
        px + dx * invDist * maxStep,
        py + dy * invDist * maxStep,
        pz + dz * invDist * maxStep
    )
end

return MonsterLogic
