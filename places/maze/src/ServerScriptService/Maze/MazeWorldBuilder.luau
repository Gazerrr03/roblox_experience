local Workspace = game:GetService('Workspace')

local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Packages = ReplicatedStorage:WaitForChild('Packages')
local Shared = require(Packages:WaitForChild('Shared'))

local MazeScene = require(script.Parent.MazeScene)
local MazeStaticWorldAssembler = require(script.Parent.MazeStaticWorldAssembler)
local MazeStaticWorldContract = require(script.Parent.MazeStaticWorldContract)

local MazeWorldBuilder = {}

function MazeWorldBuilder.build()
    local staticWorldRoot = MazeStaticWorldAssembler.assemble()
    if staticWorldRoot == nil then
        staticWorldRoot = Workspace:FindFirstChild(MazeStaticWorldContract.RootName)
    end

    if staticWorldRoot == nil then
        error(
            string.format(
                'Workspace is missing required authored root "%s".',
                MazeStaticWorldContract.RootName
            ),
            0
        )
    end

    if not (staticWorldRoot:IsA('Folder') or staticWorldRoot:IsA('Model')) then
        error('MazeStaticWorld must be a Folder or Model.', 0)
    end

    return MazeScene.new(Shared.Runtime.MazeWorldScanner.BuildStaticWorld(staticWorldRoot))
end

return MazeWorldBuilder
