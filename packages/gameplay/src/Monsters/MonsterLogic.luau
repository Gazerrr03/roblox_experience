local MonsterLogic = {}

local Vector3_new = Vector3.new
local math_sqrt = math.sqrt

-- Bolt: Optimized to use squared distance and raw component math to avoid Vector3 metatable overhead.
function MonsterLogic.pickNearestTarget(currentPosition, playerPositions, sightRange)
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

-- Bolt: Optimized to avoid intermediate Vector3 allocations and .Unit property access.
function MonsterLogic.stepToward(currentPosition, targetPosition, speed, dt)
    local ox = targetPosition.X - currentPosition.X
    local oy = targetPosition.Y - currentPosition.Y
    local oz = targetPosition.Z - currentPosition.Z
    local distanceSq = ox * ox + oy * oy + oz * oz

    if distanceSq == 0 then
        return currentPosition
    end

    local maxStep = speed * dt
    if maxStep >= 0 and distanceSq <= maxStep * maxStep then
        return targetPosition
    end

    local distance = math_sqrt(distanceSq)
    local invDist = 1 / distance
    return Vector3_new(
        currentPosition.X + ox * invDist * maxStep,
        currentPosition.Y + oy * invDist * maxStep,
        currentPosition.Z + oz * invDist * maxStep
    )
end

return MonsterLogic
