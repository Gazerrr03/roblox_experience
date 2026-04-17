local Workspace = game:GetService('Workspace')

local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Packages = ReplicatedStorage:WaitForChild('Packages')
local Shared = require(Packages:WaitForChild('Shared'))

local MazeScene = require(script.Parent.MazeScene)

local MazeWorldBuilder = {}
local STATIC_WORLD_ROOT_NAME = 'MazeStaticWorld'

function MazeWorldBuilder.build()
    local staticWorldRoot = Workspace:FindFirstChild(STATIC_WORLD_ROOT_NAME)
    if staticWorldRoot == nil then
        error('Workspace is missing required authored root "MazeStaticWorld".', 0)
    end

    if not (staticWorldRoot:IsA('Folder') or staticWorldRoot:IsA('Model')) then
        error('MazeStaticWorld must be a Folder or Model.', 0)
    end

    return MazeScene.new(Shared.Runtime.MazeWorldScanner.BuildStaticWorld(staticWorldRoot))
end

return MazeWorldBuilder
