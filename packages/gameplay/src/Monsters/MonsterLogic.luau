local MonsterLogic = {}

function MonsterLogic.pickNearestTarget(currentPosition, playerPositions, sightRange)
    -- Bolt: Guard against negative sight range as original behavior would naturally fail distance check
    if sightRange < 0 then
        return nil
    end

    local closestPlayer = nil
    local closestDistanceSq = sightRange * sightRange

    -- Bolt: Access numeric components once to avoid Vector3 metatable dispatch in the loop
    local cx, cy, cz = currentPosition.X, currentPosition.Y, currentPosition.Z

    for player, position in pairs(playerPositions) do
        -- Bolt: Use squared distance to avoid expensive math.sqrt call per target
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
    -- Bolt: Deconstruct vectors to raw components to avoid multiple intermediate Vector3 allocations
    local ox = targetPosition.X - currentPosition.X
    local oy = targetPosition.Y - currentPosition.Y
    local oz = targetPosition.Z - currentPosition.Z
    local distSq = ox * ox + oy * oy + oz * oz

    if distSq == 0 then
        return currentPosition
    end

    local maxStep = speed * dt
    -- Bolt: Fast-path if the step covers the remaining distance, skipping unit vector and magnitude math.
    -- maxStep >= 0 ensures negative speed (moving away) still uses the slow path for correct direction.
    if maxStep >= 0 and maxStep * maxStep >= distSq then
        return targetPosition
    end

    local dist = math.sqrt(distSq)
    local stepDistance = math.min(maxStep, dist)
    local invDist = 1 / dist

    -- Bolt: Return a single new Vector3 constructed from raw components
    return Vector3.new(
        currentPosition.X + ox * invDist * stepDistance,
        currentPosition.Y + oy * invDist * stepDistance,
        currentPosition.Z + oz * invDist * stepDistance
    )
end

return MonsterLogic
