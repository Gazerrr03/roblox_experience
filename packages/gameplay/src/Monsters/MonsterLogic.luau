local Vector3_new = Vector3.new
local math_sqrt = math.sqrt

local MonsterLogic = {}

function MonsterLogic.pickNearestTarget(currentPosition, playerPositions, sightRange)
    -- Bolt: Explicit guard for negative sight range to match original behavior where distance comparison fails.
    if sightRange < 0 then
        return nil
    end

    local closestPlayer = nil
    local closestDistanceSq = sightRange * sightRange
    local cx, cy, cz = currentPosition.X, currentPosition.Y, currentPosition.Z

    for player, position in pairs(playerPositions) do
        -- Bolt: Use squared distance and direct component math to avoid Magnitude (sqrt) and Vector3 metatable overhead.
        local px, py, pz = position.X, position.Y, position.Z
        local dx, dy, dz = px - cx, py - cy, pz - cz
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
    local dx, dy, dz = tx - cx, ty - cy, tz - cz

    local distanceSq = dx * dx + dy * dy + dz * dz
    if distanceSq == 0 then
        return currentPosition
    end

    local distance = math_sqrt(distanceSq)
    local maxStep = speed * dt

    -- Bolt: Fast-path for arrival avoids expensive Unit vector calculation and multiple Vector3 allocations.
    if maxStep >= distance then
        return targetPosition
    end

    -- Bolt: Manual component math reduces intermediate Vector3 object churn in high-frequency AI loops.
    local invDist = 1 / distance
    return Vector3_new(
        cx + dx * invDist * maxStep,
        cy + dy * invDist * maxStep,
        cz + dz * invDist * maxStep
    )
end

return MonsterLogic
