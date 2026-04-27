local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Workspace = game:GetService('Workspace')

local Packages = ReplicatedStorage:WaitForChild('Packages')
local Shared = require(Packages:WaitForChild('Shared'))

local MazeScene = require(script.Parent.MazeScene)
local MazeStaticWorldAssembler = require(script.Parent.MazeStaticWorldAssembler)
local MazeStaticWorldContract = require(script.Parent.MazeStaticWorldContract)
local MazeCollisionOverlay = require(script.Parent.MazeCollisionOverlay)

local MazeWorldBuilder = {}

function MazeWorldBuilder.build()
    local staticWorldRoot = Workspace:FindFirstChild(MazeStaticWorldContract.RootName)
        or MazeStaticWorldAssembler.assemble()

    if not (staticWorldRoot:IsA('Folder') or staticWorldRoot:IsA('Model')) then
        error('MazeStaticWorld must be a Folder or Model.', 0)
    end

    MazeCollisionOverlay.apply(staticWorldRoot)

    return MazeScene.new(Shared.Runtime.MazeWorldScanner.BuildStaticWorld(staticWorldRoot))
end

return MazeWorldBuilder
