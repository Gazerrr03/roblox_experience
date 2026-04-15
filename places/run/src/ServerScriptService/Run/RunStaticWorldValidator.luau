local Workspace = game:GetService('Workspace')

local RunStaticWorldContract = require(script.Parent.RunStaticWorldContract)

local RunStaticWorldValidator = {}
local REQUIRED_MARKER_NAMES = table.freeze({
    'SpawnMarker',
    'ReturnMarker',
    'MazeReturnMarker',
})

local function requireContainer(parent, name, contextLabel)
    local child = parent:FindFirstChild(name)
    if child == nil or not (child:IsA('Folder') or child:IsA('Model')) then
        error(string.format('%s is missing required container "%s".', contextLabel, name), 0)
    end

    return child
end

local function collectBaseParts(root)
    local parts = {}

    for _, descendant in ipairs(root:GetDescendants()) do
        if descendant:IsA('BasePart') then
            table.insert(parts, descendant)
        end
    end

    return parts
end

local function requireBaseParts(root, contextLabel)
    local parts = collectBaseParts(root)
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

-- Validates the dedicated low-poly collision mesh (Scene_collision).
-- This mesh lives at Workspace.Scene_collision (sibling of RunStaticWorld), not inside it.
local function validateSceneCollisionMesh(workspace)
    local contract = RunStaticWorldContract.CollisionMeshContract
    local collisionRoot = workspace:FindFirstChild(contract.Name)
    if collisionRoot == nil then
        error(
            string.format(
                'Scene_collision not found at Workspace.Scene_collision. See places/run/TERRAIN_COLLISION_SETUP.md for import instructions.',
                contract.Name
            ),
            0
        )
    end

    local node = collisionRoot:FindFirstChild(contract.NodeName)
    if node == nil or not node:IsA('Model') then
        error(
            string.format(
                'Scene_collision is missing required Model child "%s".',
                contract.NodeName
            ),
            0
        )
    end

    local meshPart = node:FindFirstChild(contract.MeshPartName)
    if meshPart == nil or not meshPart:IsA('MeshPart') then
        error(
            string.format(
                'Scene_collision/%s is missing required MeshPart "%s".',
                contract.NodeName,
                contract.MeshPartName
            ),
            0
        )
    end

    local function check(name, actual, expected)
        if actual ~= expected then
            error(
                string.format(
                    'Scene_collision %s.%s has %s=%s (expected %s). See places/run/TERRAIN_COLLISION_SETUP.md.',
                    contract.NodeName,
                    contract.MeshPartName,
                    name,
                    tostring(actual),
                    tostring(expected)
                ),
                0
            )
        end
    end

    check('CanCollide', meshPart.CanCollide, contract.ExpectedCanCollide)
    check('Anchored', meshPart.Anchored, contract.ExpectedAnchored)
    check('Transparency', meshPart.Transparency, contract.ExpectedTransparency)

    if meshPart.CollisionFidelity ~= contract.ExpectedCollisionFidelity then
        error(
            string.format(
                'Scene_collision %s.%s has CollisionFidelity=%s (expected %s). See places/run/TERRAIN_COLLISION_SETUP.md.',
                contract.NodeName,
                contract.MeshPartName,
                tostring(meshPart.CollisionFidelity),
                tostring(contract.ExpectedCollisionFidelity)
            ),
            0
        )
    end
end

-- Validates the visual terrain mesh has collision disabled (collision is handled by Scene_collision).
local function validateVisualTerrain(root)
    local contract = RunStaticWorldContract.VisualTerrainContract
    local terrainRoot = root:FindFirstChild(contract.RootName)
    if terrainRoot == nil then
        return -- No terrain in this world, skip
    end

    local sceneFolder = terrainRoot:FindFirstChild(contract.SceneFolderName)
    if sceneFolder == nil then
        return
    end

    local terrainGroup = sceneFolder:FindFirstChild(contract.TerrainGroupName)
    if terrainGroup == nil then
        return
    end

    local meshPart = terrainGroup:FindFirstChild(contract.MeshPartName)
    if meshPart == nil or not meshPart:IsA('MeshPart') then
        return
    end

    if meshPart.CanCollide ~= contract.ExpectedCanCollide then
        error(
            string.format(
                'Visual terrain %s/%s/%s.%s has CanCollide=%s (expected %s). '
                    .. 'Visual terrain must have CanCollide=false; collision is handled by Scene_collision.',
                contract.RootName,
                contract.SceneFolderName,
                contract.TerrainGroupName,
                contract.MeshPartName,
                tostring(meshPart.CanCollide),
                tostring(contract.ExpectedCanCollide)
            ),
            0
        )
    end
end

local function buildSpawnGroundParams(sceneCollisionRoot, shipCollisionRoot, terrainMesh)
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Include
    local instances = { sceneCollisionRoot, shipCollisionRoot }
    if terrainMesh and terrainMesh:IsA('BasePart') then
        table.insert(instances, terrainMesh)
    end
    raycastParams.FilterDescendantsInstances = instances
    return raycastParams
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

local function assertSpawnHasGround(sceneCollisionRoot, shipCollisionRoot, terrainMesh, spawnMarker)
    local raycastParams = buildSpawnGroundParams(sceneCollisionRoot, shipCollisionRoot, terrainMesh)
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
            'RunStaticWorld SpawnMarker must raycast onto Collision/Scene, Collision/Ship, or terrain mesh within %d studs below it.',
            RunStaticWorldContract.SpawnGroundCheckDepth
        ),
        0
    )
end

function RunStaticWorldValidator.validate(root)
    if root.Parent ~= Workspace then
        error('RunStaticWorld must be parented to Workspace before validation.', 0)
    end

    -- Validate the dedicated collision mesh (at Workspace level, sibling of RunStaticWorld)
    validateSceneCollisionMesh(Workspace)

    -- Validate the visual terrain has collision disabled
    validateVisualTerrain(root)

    local collisionRoot =
        requireContainer(root, RunStaticWorldContract.CollisionRootName, 'RunStaticWorld')
    local sceneCollisionRoot = requireContainer(
        collisionRoot,
        RunStaticWorldContract.SceneCollisionName,
        'RunStaticWorld Collision'
    )
    local shipCollisionRoot = requireContainer(
        collisionRoot,
        RunStaticWorldContract.ShipCollisionName,
        'RunStaticWorld Collision'
    )
    local triggersRoot =
        requireContainer(root, RunStaticWorldContract.TriggersRootName, 'RunStaticWorld')
    local oceanTriggerRoot = requireContainer(
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

    -- Find terrain mesh: RunTerrain_Main.Scene.RunTerrain_OriginalHigh.RunTerrain_OriginalHighMesh
    local terrainRoot = root:FindFirstChild('RunTerrain_Main')
    local terrainMesh = nil
    if terrainRoot and terrainRoot:IsA('Model') then
        local sceneFolder = terrainRoot:FindFirstChild('Scene')
        if sceneFolder then
            local terrainGroup = sceneFolder:FindFirstChild('RunTerrain_OriginalHigh')
            if terrainGroup then
                terrainMesh = terrainGroup:FindFirstChild('RunTerrain_OriginalHighMesh')
            end
        end
    end

    assertSpawnHasGround(sceneCollisionRoot, shipCollisionRoot, terrainMesh, spawnMarker)
end

return RunStaticWorldValidator
