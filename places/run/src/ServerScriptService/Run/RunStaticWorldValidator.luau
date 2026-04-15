local Workspace = game:GetService('Workspace')

local RunStaticWorldContract = require(script.Parent.RunStaticWorldContract)

local RunStaticWorldValidator = {}
local REQUIRED_MARKER_NAMES = table.freeze({
    'SpawnMarker',
    'ReturnMarker',
    'MazeReturnMarker',
})

local function requireBaseParts(root, contextLabel)
    local parts = RunStaticWorldContract.collectBaseParts(root)
    if #parts == 0 then
        error(string.format('%s must contain at least one BasePart.', contextLabel), 0)
    end

    return parts
end

local function validateCollisionParts(parts, contextLabel)
    for _, part in ipairs(parts) do
        if part.Anchored ~= true then
            error(string.format('%s part "%s" must be Anchored.', contextLabel, part.Name), 0)
        end
        if part.CanCollide ~= true then
            error(
                string.format('%s part "%s" must have CanCollide=true.', contextLabel, part.Name),
                0
            )
        end
        if part.CanTouch ~= false then
            error(
                string.format('%s part "%s" must have CanTouch=false.', contextLabel, part.Name),
                0
            )
        end
        if part.CanQuery ~= true then
            error(
                string.format('%s part "%s" must have CanQuery=true.', contextLabel, part.Name),
                0
            )
        end
        if part.Transparency ~= 1 then
            error(
                string.format('%s part "%s" must have Transparency=1.', contextLabel, part.Name),
                0
            )
        end
    end
end

local function validateOceanParts(parts, contextLabel)
    for _, part in ipairs(parts) do
        if part.Anchored ~= true then
            error(string.format('%s part "%s" must be Anchored.', contextLabel, part.Name), 0)
        end
        if part.CanCollide ~= false then
            error(
                string.format('%s part "%s" must have CanCollide=false.', contextLabel, part.Name),
                0
            )
        end
        if part.CanTouch ~= true then
            error(
                string.format('%s part "%s" must have CanTouch=true.', contextLabel, part.Name),
                0
            )
        end
        if part.Transparency ~= 1 then
            error(
                string.format('%s part "%s" must have Transparency=1.', contextLabel, part.Name),
                0
            )
        end
    end
end

local function validateMarkerPart(part, contextLabel)
    if part.Anchored ~= true then
        error(string.format('%s must be Anchored.', contextLabel), 0)
    end
    if part.CanCollide ~= false then
        error(string.format('%s must have CanCollide=false.', contextLabel), 0)
    end
    if part.CanTouch ~= false then
        error(string.format('%s must have CanTouch=false.', contextLabel), 0)
    end
    if part.CanQuery ~= true then
        error(string.format('%s must have CanQuery=true.', contextLabel), 0)
    end
end

local function buildSpawnGroundParams(sceneCollisionRoot, shipCollisionRoot)
    return RunStaticWorldContract.buildSpawnGroundParams(sceneCollisionRoot, shipCollisionRoot)
end

local function buildSpawnGroundSampleOffsets(spawnMarker)
    local offsetX = math.max(spawnMarker.Size.X * 0.35, 1)
    local offsetZ = math.max(spawnMarker.Size.Z * 0.35, 1)

    return {
        Vector3.zero,
        Vector3.new(offsetX, 0, offsetZ),
        Vector3.new(offsetX, 0, -offsetZ),
        Vector3.new(-offsetX, 0, offsetZ),
        Vector3.new(-offsetX, 0, -offsetZ),
    }
end

local function assertSpawnHasGround(sceneCollisionRoot, shipCollisionRoot, spawnMarker)
    local raycastParams = buildSpawnGroundParams(sceneCollisionRoot, shipCollisionRoot)
    local sampleOffsets = buildSpawnGroundSampleOffsets(spawnMarker)
    local raycastDistance = Vector3.new(0, -RunStaticWorldContract.SpawnGroundCheckDepth, 0)
    local raycastStartHeight = (spawnMarker.Size.Y * 0.5) + 2

    for _, offset in ipairs(sampleOffsets) do
        local origin = spawnMarker.Position + Vector3.new(offset.X, raycastStartHeight, offset.Z)
        local result = Workspace:Raycast(origin, raycastDistance, raycastParams)
        if result and result.Instance and result.Instance.CanCollide and result.Normal.Y > 0.5 then
            return
        end
    end

    error(
        string.format(
            'RunStaticWorld SpawnMarker must raycast onto Collision/Scene or Collision/Ship within %d studs below it.',
            RunStaticWorldContract.SpawnGroundCheckDepth
        ),
        0
    )
end

function RunStaticWorldValidator.validate(root)
    if root.Parent ~= Workspace then
        error('RunStaticWorld must be parented to Workspace before validation.', 0)
    end

    local collisionRoot =
        RunStaticWorldContract.requireContainer(root, RunStaticWorldContract.CollisionRootName, 'RunStaticWorld')
    local sceneCollisionRoot = RunStaticWorldContract.requireContainer(
        collisionRoot,
        RunStaticWorldContract.SceneCollisionName,
        'RunStaticWorld Collision'
    )
    local shipCollisionRoot = RunStaticWorldContract.requireContainer(
        collisionRoot,
        RunStaticWorldContract.ShipCollisionName,
        'RunStaticWorld Collision'
    )
    local triggersRoot =
        RunStaticWorldContract.requireContainer(root, RunStaticWorldContract.TriggersRootName, 'RunStaticWorld')
    local oceanTriggerRoot = RunStaticWorldContract.requireContainer(
        triggersRoot,
        RunStaticWorldContract.OceanTriggerName,
        'RunStaticWorld Triggers'
    )

    validateCollisionParts(
        requireBaseParts(sceneCollisionRoot, 'RunStaticWorld Collision/Scene'),
        'RunStaticWorld Collision/Scene'
    )
    validateCollisionParts(
        requireBaseParts(shipCollisionRoot, 'RunStaticWorld Collision/Ship'),
        'RunStaticWorld Collision/Ship'
    )
    validateOceanParts(
        requireBaseParts(oceanTriggerRoot, 'RunStaticWorld Triggers/Ocean'),
        'RunStaticWorld Triggers/Ocean'
    )

    local spawnMarker = nil
    for _, markerName in ipairs(REQUIRED_MARKER_NAMES) do
        local markerPart = root:FindFirstChild(markerName, true)
        if markerPart == nil or not markerPart:IsA('BasePart') then
            error(string.format('RunStaticWorld is missing required part "%s".', markerName), 0)
        end

        validateMarkerPart(markerPart, string.format('RunStaticWorld marker "%s"', markerName))

        if markerName == 'SpawnMarker' then
            spawnMarker = markerPart
        end
    end

    assertSpawnHasGround(sceneCollisionRoot, shipCollisionRoot, spawnMarker)
end

return RunStaticWorldValidator
