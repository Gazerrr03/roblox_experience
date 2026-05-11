local Vector3_new = Vector3.new
local math_min = math.min
local math_sqrt = math.sqrt

local MonsterLogic = {}

-- Bolt: Optimized pickNearestTarget by using squared distance comparison
-- to avoid math.sqrt calls in the hot loop. Direct numeric coordinate access
-- minimizes Vector3 object churn and metatable overhead.
function MonsterLogic.pickNearestTarget(currentPosition, playerPositions, sightRange)
    local closestPlayer = nil
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

-- Bolt: Optimized stepToward by calculating on raw numeric components.
-- Reduced Vector3 allocation and metatable dispatch. Added early return
-- for target reachability to skip square root and division.
function MonsterLogic.stepToward(currentPosition, targetPosition, speed, dt)
    local cx, cy, cz = currentPosition.X, currentPosition.Y, currentPosition.Z
    local tx, ty, tz = targetPosition.X, targetPosition.Y, targetPosition.Z

    local dx = tx - cx
    local dy = ty - cy
    local dz = tz - cz
    local distSq = dx * dx + dy * dy + dz * dz

    if distSq == 0 then
        return currentPosition
    end

    local maxStep = speed * dt
    -- If the step distance exceeds the remaining distance, jump to target.
    -- We check maxStep >= 0 to preserve original behavior for negative speeds.
    if maxStep >= 0 and maxStep * maxStep >= distSq then
        return targetPosition
    end

    local distance = math_sqrt(distSq)
    local stepDistance = math_min(maxStep, distance)
    local fraction = stepDistance / distance

    return Vector3_new(cx + dx * fraction, cy + dy * fraction, cz + dz * fraction)
end

return MonsterLogic
