local math_sqrt = math.sqrt
local Vector3_new = Vector3.new

local MonsterLogic = {}

function MonsterLogic.pickNearestTarget(currentPosition, playerPositions, sightRange)
	-- Bolt: Optimized by using squared distance and raw component access to avoid Vector3 allocation and math.sqrt
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

function MonsterLogic.stepToward(currentPosition, targetPosition, speed, dt)
	-- Bolt: Optimized by using raw components to avoid intermediate Vector3 allocations and using early exits.
	local tx, ty, tz = targetPosition.X, targetPosition.Y, targetPosition.Z
	local cx, cy, cz = currentPosition.X, currentPosition.Y, currentPosition.Z

	local dx = tx - cx
	local dy = ty - cy
	local dz = tz - cz

	local distSq = dx * dx + dy * dy + dz * dz
	if distSq == 0 then
		return currentPosition
	end

	local maxStep = speed * dt
	-- Check if we would reach or exceed the target this step.
	-- We must also check maxStep >= 0 to handle cases where we are moving away.
	if maxStep >= 0 and maxStep * maxStep >= distSq then
		return targetPosition
	end

	local distance = math_sqrt(distSq)
	local fraction = maxStep / distance

	return Vector3_new(cx + dx * fraction, cy + dy * fraction, cz + dz * fraction)
end

return MonsterLogic
