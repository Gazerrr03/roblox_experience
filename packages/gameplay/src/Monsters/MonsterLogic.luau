local MonsterLogic = {}

-- Bolt: Optimizing target selection by using squared distance comparisons to avoid math.sqrt calls.
-- Also using raw component math to reduce Vector3 metatable overhead in the loop.
function MonsterLogic.pickNearestTarget(currentPosition, playerPositions, sightRange)
    local closestPlayer = nil
    -- Bolt: Store the squared distance to avoid math.sqrt during comparison.
    -- If sightRange is negative, distance comparison will naturally fail as distance squared is >= 0.
    -- We must guard against negative sightRange because squaring it would make it positive.
    local closestDistanceSq = if sightRange < 0 then -1 else sightRange * sightRange

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

-- Bolt: Optimizing step toward by using squared distance for the arrival check and
-- minimizing intermediate Vector3 allocations by calculating the unit vector components manually.
function MonsterLogic.stepToward(currentPosition, targetPosition, speed, dt)
    local tx, ty, tz = targetPosition.X, targetPosition.Y, targetPosition.Z
    local cx, cy, cz = currentPosition.X, currentPosition.Y, currentPosition.Z

    local ox = tx - cx
    local oy = ty - cy
    local oz = tz - cz

    local distSq = ox * ox + oy * oy + oz * oz

    -- Bolt: Early exit if we are already at the target to skip magnitude and unit calculations.
    if distSq == 0 then
        return currentPosition
    end

    local maxStep = speed * dt
    -- Bolt: If the step distance is greater than or equal to the remaining distance, return the target position.
    -- We check maxStep >= 0 to ensure that negative speed (moving away) still works as expected.
    if maxStep >= 0 and maxStep * maxStep >= distSq then
        return targetPosition
    end

    local distance = math.sqrt(distSq)
    local invDist = 1 / distance

    -- Bolt: Allocate only one new Vector3 for the result.
    return Vector3.new(
        cx + ox * invDist * maxStep,
        cy + oy * invDist * maxStep,
        cz + oz * invDist * maxStep
    )
end

return MonsterLogic
