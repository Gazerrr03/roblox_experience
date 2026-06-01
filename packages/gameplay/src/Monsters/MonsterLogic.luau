local math_sqrt = math.sqrt
local Vector3_new = Vector3.new

local MonsterLogic = {}

function MonsterLogic.pickNearestTarget(currentPosition, playerPositions, sightRange)
    local closestPlayer = nil
    -- Bolt: Use squared distance to avoid expensive square root calculations in the loop.
    local closestDistanceSq = sightRange * sightRange

    local cx, cy, cz = currentPosition.X, currentPosition.Y, currentPosition.Z

    for player, position in pairs(playerPositions) do
        -- Bolt: Direct numeric component access is faster than Vector3 metatable dispatch.
        local dx = position.X - cx
        local dy = position.Y - cy
        local dz = position.Z - cz
        local distSq = dx * dx + dy * dy + dz * dz

        -- Bolt: Ensure sightRange was not negative to preserve original behavior where negative range fails.
        if sightRange >= 0 and distSq <= closestDistanceSq then
            closestPlayer = player
            closestDistanceSq = distSq
        end
    end

    return closestPlayer
end

function MonsterLogic.stepToward(currentPosition, targetPosition, speed, dt)
    local maxStep = speed * dt
    local ox = targetPosition.X - currentPosition.X
    local oy = targetPosition.Y - currentPosition.Y
    local oz = targetPosition.Z - currentPosition.Z
    local distSq = ox * ox + oy * oy + oz * oz

    if distSq == 0 then
        return currentPosition
    end

    -- Bolt: Fast-path for when the step exceeds the remaining distance.
    if maxStep >= 0 and maxStep * maxStep >= distSq then
        return targetPosition
    end

    -- Bolt: Perform math on raw components to avoid multiple intermediate Vector3 allocations.
    local distance = math_sqrt(distSq)
    local invDist = 1 / distance

    return Vector3_new(
        currentPosition.X + ox * invDist * maxStep,
        currentPosition.Y + oy * invDist * maxStep,
        currentPosition.Z + oz * invDist * maxStep
    )
end

return MonsterLogic
