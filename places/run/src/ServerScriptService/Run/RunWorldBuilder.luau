local Workspace = game:GetService('Workspace')

local RunScene = require(script.Parent.RunScene)
local RunSpawnPoint = require(script.Parent.RunSpawnPoint)

local RunWorldBuilder = {}

local STATIC_WORLD_ROOT_NAME = 'RunStaticWorld'

function RunWorldBuilder.build()
    local staticWorldRoot = Workspace:FindFirstChild(STATIC_WORLD_ROOT_NAME)
    if staticWorldRoot == nil then
        error('Workspace is missing required authored root "RunStaticWorld".', 0)
    end

    if not (staticWorldRoot:IsA('Folder') or staticWorldRoot:IsA('Model')) then
        error('RunStaticWorld must be a Folder or Model.', 0)
    end

    return RunScene.new(staticWorldRoot)
end

RunWorldBuilder.SpawnTarget = RunSpawnPoint.Kind

return RunWorldBuilder
