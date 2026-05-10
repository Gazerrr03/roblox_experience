local MonsterLogic = {}

local math_sqrt = math.sqrt

function MonsterLogic.pickNearestTarget(currentPosition, playerPositions, sightRange)
    local closestPlayer = nil
    local closestDistanceSq = sightRange * sightRange

    local cx, cy, cz = currentPosition.X, currentPosition.Y, currentPosition.Z

    for player, position in pairs(playerPositions) do
        -- Bolt: Using squared distance and raw component access to avoid Vector3 allocations and metatable overhead
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

function MonsterLogic.stepToward(currentPosition, targetPosition, speed, dt)
    local offset = targetPosition - currentPosition
    local distSq = offset.X * offset.X + offset.Y * offset.Y + offset.Z * offset.Z

    if distSq == 0 then
        return currentPosition
    end

    local maxStep = speed * dt
    -- Bolt: Early exit if target is reached in one step; avoids sqrt and division
    if maxStep >= 0 and maxStep * maxStep >= distSq then
        return targetPosition
    end

    local distance = math_sqrt(distSq)
    return currentPosition + (offset * (maxStep / distance))
end

return MonsterLogic
