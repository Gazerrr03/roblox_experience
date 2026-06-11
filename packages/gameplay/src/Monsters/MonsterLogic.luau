local MonsterLogic = {}

function MonsterLogic.pickNearestTarget(currentPosition, playerPositions, sightRange)
    -- Bolt: If sightRange is negative, no target can be in range.
    -- This guard preserves original behavior where negative ranges never match.
    if sightRange < 0 then
        return nil
    end

    local closestPlayer = nil
    local closestDistSq = sightRange * sightRange

    -- Bolt: Accessing Vector3 components directly and using squared distance
    -- avoids expensive Magnitude calculations and metatable dispatch in the loop.
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

function MonsterLogic.stepToward(currentPosition, targetPosition, speed, dt)
    local tx, ty, tz = targetPosition.X, targetPosition.Y, targetPosition.Z
    local cx, cy, cz = currentPosition.X, currentPosition.Y, currentPosition.Z

    local ox = tx - cx
    local oy = ty - cy
    local oz = tz - cz

    local distSq = ox * ox + oy * oy + oz * oz
    if distSq == 0 then
        return currentPosition
    end

    local maxStep = speed * dt
    -- Bolt: Fast-path for when the target is within the reach of a single step.
    -- The maxStep >= 0 check preserves original behavior for negative speeds.
    if maxStep >= 0 and maxStep * maxStep >= distSq then
        return targetPosition
    end

    -- Bolt: Using raw component math and allocating a single result Vector3
    -- avoids intermediate Unit vector and magnitude objects.
    local distance = math.sqrt(distSq)
    local invDist = 1 / distance

    return Vector3.new(
        cx + ox * invDist * maxStep,
        cy + oy * invDist * maxStep,
        cz + oz * invDist * maxStep
    )
end

return MonsterLogic
