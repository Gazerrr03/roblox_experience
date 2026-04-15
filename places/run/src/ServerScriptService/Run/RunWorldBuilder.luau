local Workspace = game:GetService('Workspace')

local RunScene = require(script.Parent.RunScene)
local RunStaticWorldContract = require(script.Parent.RunStaticWorldContract)
local RunStaticWorldValidator = require(script.Parent.RunStaticWorldValidator)
local RunSpawnPoint = require(script.Parent.RunSpawnPoint)

local RunWorldBuilder = {}

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

    RunStaticWorldValidator.validate(staticWorldRoot)

    return RunScene.new(staticWorldRoot)
end

RunWorldBuilder.SpawnTarget = RunSpawnPoint.Kind

return RunWorldBuilder
