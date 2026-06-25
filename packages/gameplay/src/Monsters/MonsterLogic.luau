local MonsterLogic = {}

local Vector3_new = Vector3.new
local math_sqrt = math.sqrt

--[=[
    Finds the nearest player within sight range.
    Optimized with squared distance comparisons to avoid expensive Magnitude calculations.
]=]
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
        local distanceSq = dx * dx + dy * dy + dz * dz

        if distanceSq <= closestDistanceSq then
            closestPlayer = player
            closestDistanceSq = distanceSq
        end
    end

    return closestPlayer
end

--[=[
    Moves currentPosition toward targetPosition by speed * dt.
    Optimized with raw component math and a fast-path for arrival.
]=]
function MonsterLogic.stepToward(currentPosition, targetPosition, speed, dt)
    local tx, ty, tz = targetPosition.X, targetPosition.Y, targetPosition.Z
    local cx, cy, cz = currentPosition.X, currentPosition.Y, currentPosition.Z

    local dx = tx - cx
    local dy = ty - cy
    local dz = tz - cz

    local distanceSq = dx * dx + dy * dy + dz * dz
    if distanceSq == 0 then
        return currentPosition
    end

    local maxStep = speed * dt
    -- Bolt: Fast-path for arrival to avoid sqrt and Unit vector overhead
    if distanceSq <= maxStep * maxStep then
        return targetPosition
    end

    local distance = math_sqrt(distanceSq)
    local invDist = 1 / distance

    -- Bolt: Return a single new Vector3 to reduce allocation churn
    return Vector3_new(
        cx + dx * invDist * maxStep,
        cy + dy * invDist * maxStep,
        cz + dz * invDist * maxStep
    )
end

return MonsterLogic
