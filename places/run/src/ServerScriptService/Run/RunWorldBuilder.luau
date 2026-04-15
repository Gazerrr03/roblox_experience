local Workspace = game:GetService('Workspace')

local RunScene = require(script.Parent.RunScene)
local RunStaticWorldContract = require(script.Parent.RunStaticWorldContract)
local RunStaticWorldValidator = require(script.Parent.RunStaticWorldValidator)
local RunSpawnPoint = require(script.Parent.RunSpawnPoint)

local RunWorldBuilder = {}

local function stabilizeVisualModel(model)
    if model == nil then
        return
    end

    for _, descendant in ipairs(model:GetDescendants()) do
        if descendant:IsA('BasePart') then
            descendant.Anchored = true
            descendant.CanCollide = false
            descendant.CanTouch = false
            descendant.CanQuery = true
            descendant.AssemblyLinearVelocity = Vector3.zero
            descendant.AssemblyAngularVelocity = Vector3.zero
        end
    end
end

local function prepareRunTerrain(root)
    local terrainRoot = root:FindFirstChild('RunTerrain_Main')
    if terrainRoot == nil or not terrainRoot:IsA('Model') then
        return
    end

    stabilizeVisualModel(terrainRoot:FindFirstChild('Scene'))
    stabilizeVisualModel(terrainRoot:FindFirstChild('Sci-Fi Space Ship'))

    -- Keep terrain mesh visual only - collision is handled by collision mesh in Collision.Scene
    local terrainMesh = terrainRoot.Scene and terrainRoot.Scene:FindFirstChild('RunTerrain_OriginalHigh')
        and terrainRoot.Scene.RunTerrain_OriginalHigh:FindFirstChild('RunTerrain_OriginalHighMesh')
    if terrainMesh and terrainMesh:IsA('BasePart') then
        terrainMesh.CanCollide = false
    end
end

function RunWorldBuilder.build()
    local staticWorldRoot = Workspace:FindFirstChild(RunStaticWorldContract.RootName)
    if staticWorldRoot == nil then
        error(
            string.format(
                'Workspace is missing required authored root "%s".',
                RunStaticWorldContract.RootName
            ),
            0
        )
    end

    if not (staticWorldRoot:IsA('Folder') or staticWorldRoot:IsA('Model')) then
        error('RunStaticWorld must be a Folder or Model.', 0)
    end

    prepareRunTerrain(staticWorldRoot)
    RunStaticWorldValidator.validate(staticWorldRoot)

    return RunScene.new(staticWorldRoot)
end

RunWorldBuilder.SpawnTarget = RunSpawnPoint.Kind

return RunWorldBuilder
