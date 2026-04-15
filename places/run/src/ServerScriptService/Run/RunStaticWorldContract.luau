local RunStaticWorldContract = table.freeze({
    RootName = 'RunStaticWorld',
    CollisionRootName = 'Collision',
    SceneCollisionName = 'Scene',
    ShipCollisionName = 'Ship',
    TriggersRootName = 'Triggers',
    OceanTriggerName = 'Ocean',
    BuildFingerprint = 'run-collision-contract-v2',
    SpawnGroundCheckDepth = 32,
    SpawnLiftStuds = 4,
    OceanSplashCooldownSeconds = 1.5,
})

-- Shared helper functions used by both RunScene and RunStaticWorldValidator
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

local function buildSpawnGroundParams(sceneCollisionRoot, shipCollisionRoot)
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Include
    raycastParams.FilterDescendantsInstances = { sceneCollisionRoot, shipCollisionRoot }
    return raycastParams
end

RunStaticWorldContract.requireContainer = requireContainer
RunStaticWorldContract.collectBaseParts = collectBaseParts
RunStaticWorldContract.buildSpawnGroundParams = buildSpawnGroundParams

return RunStaticWorldContract
