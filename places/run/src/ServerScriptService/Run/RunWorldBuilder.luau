local Workspace = game:GetService('Workspace')

local RunScene = require(script.Parent.RunScene)
local RunStaticWorldValidator = require(script.Parent.RunStaticWorldValidator)

local RunWorldBuilder = {}

local OUTDOOR_THRESHOLD_Z = 20
local DEFAULT_SPAWN_CFRAME = CFrame.new(0, 4, -6)
local DEFAULT_RETURN_CFRAME = CFrame.new(0, 4, -2)
local MAZE_RETURN_CFRAME = CFrame.new(0, 4, 108)
local GENERATED_WORLD_ROOT_NAME = 'GeneratedWorld'
local STATIC_WORLD_ROOT_NAME = 'RunStaticWorld'

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
end

function RunWorldBuilder.build()
    local staticWorldRoot = Workspace:FindFirstChild(STATIC_WORLD_ROOT_NAME)
    if staticWorldRoot and (staticWorldRoot:IsA('Folder') or staticWorldRoot:IsA('Model')) then
        prepareRunTerrain(staticWorldRoot)
        RunStaticWorldValidator.validate(staticWorldRoot)
        return RunScene.new(staticWorldRoot)
    end

    local existing = Workspace:FindFirstChild(GENERATED_WORLD_ROOT_NAME)
    if existing then
        existing:Destroy()
    end

    local worldFolder = Instance.new('Folder')
    worldFolder.Name = GENERATED_WORLD_ROOT_NAME
    worldFolder.Parent = Workspace

    return {
        Root = worldFolder,
        SpawnCFrame = DEFAULT_SPAWN_CFRAME,
        ReturnCFrame = DEFAULT_RETURN_CFRAME,
        MazeReturnCFrame = MAZE_RETURN_CFRAME,
        OutdoorThresholdZ = OUTDOOR_THRESHOLD_Z,
        OpenGate = function() end,
    }
end

RunWorldBuilder.SpawnCFrame = DEFAULT_SPAWN_CFRAME
RunWorldBuilder.ReturnCFrame = DEFAULT_RETURN_CFRAME
RunWorldBuilder.MazeReturnCFrame = MAZE_RETURN_CFRAME

return RunWorldBuilder
