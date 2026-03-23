local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Packages = ReplicatedStorage:WaitForChild('Packages')
local Shared = require(Packages:WaitForChild('Shared'))

local MazeWorldBuilder = {}
local LIGHTING_PROFILE = Shared.Runtime.MazeLightingProfile

function MazeWorldBuilder.build(seed, config, options)
    return Shared.Runtime.MazeFormalWorldComposer.build(seed, config, {
        WorldName = options and options.WorldName or 'GeneratedMazeWorld',
        Parent = options and options.Parent or nil,
        OriginOffset = options and options.OriginOffset or Vector3.zero,
        SurfacePalette = options and options.SurfacePalette or LIGHTING_PROFILE.SurfacePalette,
        IncludeRoomMarkers = if options and options.IncludeRoomMarkers ~= nil
            then options.IncludeRoomMarkers
            else true,
        RoomMarkerTransparency = options and options.RoomMarkerTransparency or 0.5,
        RoomKindColors = options and options.RoomKindColors or nil,
        DetectionBuffer = options and options.DetectionBuffer or nil,
        ModuleAssetsRoot = options and options.ModuleAssetsRoot or nil,
        RequireModuleAssets = options and options.RequireModuleAssets or false,
        ExtractionObjectText = options and options.ExtractionObjectText or 'Run Entrance',
    })
end

return MazeWorldBuilder
