local MonsterLogic = {}

-- Bolt: Optimized pickNearestTarget using squared distance and numeric coordinate access
-- to avoid Vector3 metatable dispatch and square root calculations in the hot loop.
function MonsterLogic.pickNearestTarget(currentPosition, playerPositions, sightRange)
    local closestPlayer = nil
    -- Bolt: Using squared distance for comparison avoids expensive math.sqrt
    local closestDistanceSq = sightRange * sightRange

    -- Bolt: Sight range < 0 guard matches original behavior where negative ranges fail naturally
    if sightRange < 0 then
        return nil
    end

    local cx, cy, cz = currentPosition.X, currentPosition.Y, currentPosition.Z

    for player, position in pairs(playerPositions) do
        local px, py, pz = position.X, position.Y, position.Z
        local dx = px - cx
        local dy = py - cy
        local dz = pz - cz
        local distSq = dx * dx + dy * dy + dz * dz

        if distSq <= closestDistanceSq then
            closestPlayer = player
            closestDistanceSq = distSq
        end
    end

    return closestPlayer
end

-- Bolt: Optimized stepToward to perform calculations on raw numeric components,
-- minimizing intermediate Vector3 object churn and reusing calculated values.
function MonsterLogic.stepToward(currentPosition, targetPosition, speed, dt)
    local tx, ty, tz = targetPosition.X, targetPosition.Y, targetPosition.Z
    local cx, cy, cz = currentPosition.X, currentPosition.Y, currentPosition.Z

    local ox, oy, oz = tx - cx, ty - cy, tz - cz
    local distanceSq = ox * ox + oy * oy + oz * oz

    if distanceSq == 0 then
        return currentPosition
    end

    local distance = math.sqrt(distanceSq)
    local stepDistance = speed * dt

    -- Bolt: Direct arrival fast-path
    if stepDistance >= distance then
        return targetPosition
    end

    -- Bolt: Component-wise calculation avoids Unit vector object creation
    local invDist = 1 / distance
    return Vector3.new(
        cx + ox * invDist * stepDistance,
        cy + oy * invDist * stepDistance,
        cz + oz * invDist * stepDistance
    )
end

return MonsterLogic
