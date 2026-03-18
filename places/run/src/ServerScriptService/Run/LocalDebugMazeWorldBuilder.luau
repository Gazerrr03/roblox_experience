local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Packages = ReplicatedStorage:WaitForChild('Packages')
local Shared = require(Packages:WaitForChild('Shared'))

local LocalDebugMazeWorldBuilder = {}

local LOCAL_DEBUG_MAZE_WORLD_NAME = 'LocalDebugMazeWorld'
local DEFAULT_ORIGIN_OFFSET = Vector3.new(0, 0, 420)

function LocalDebugMazeWorldBuilder.build(seed, config, originOffset)
    return Shared.Runtime.MazeDebugWorldComposer.build(seed, config, {
        WorldName = LOCAL_DEBUG_MAZE_WORLD_NAME,
        OriginOffset = originOffset or DEFAULT_ORIGIN_OFFSET,
        IncludeRoomMarkers = true,
        RoomMarkerTransparency = 0.55,
        ReturnObjectText = 'Return To Camp (Local Debug)',
        ReturnMaxActivationDistance = 14,
    })
end

return LocalDebugMazeWorldBuilder
