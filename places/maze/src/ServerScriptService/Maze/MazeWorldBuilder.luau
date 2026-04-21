local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Packages = ReplicatedStorage:WaitForChild('Packages')
local Shared = require(Packages:WaitForChild('Shared'))

local MazeScene = require(script.Parent.MazeScene)
local MazeStaticWorldAssembler = require(script.Parent.MazeStaticWorldAssembler)

local MazeWorldBuilder = {}

function MazeWorldBuilder.build()
    local staticWorldRoot = MazeStaticWorldAssembler.assemble()

    if not (staticWorldRoot:IsA('Folder') or staticWorldRoot:IsA('Model')) then
        error('MazeStaticWorld must be a Folder or Model.', 0)
    end

    return MazeScene.new(Shared.Runtime.MazeWorldScanner.BuildStaticWorld(staticWorldRoot))
end

return MazeWorldBuilder
