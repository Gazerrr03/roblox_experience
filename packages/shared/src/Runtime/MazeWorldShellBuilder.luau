local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Packages = ReplicatedStorage:WaitForChild('Packages')
local Gameplay = require(Packages:WaitForChild('Gameplay'))

local MazeBuilder = Gameplay.ProcGen.MazeBuilder
local HexMazeWorldRenderer = require(script.Parent.HexMazeWorldRenderer)

local MazeWorldShellBuilder = {}

function MazeWorldShellBuilder.build(seed, config, options)
    local resolvedOptions = options or {}
    local layout = MazeBuilder.build(seed, config)
    local rendered = HexMazeWorldRenderer.build({
        WorldName = resolvedOptions.WorldName or 'GeneratedMazeWorld',
        Layout = layout,
        Parent = resolvedOptions.Parent,
        OriginOffset = resolvedOptions.OriginOffset or Vector3.zero,
        SurfacePalette = resolvedOptions.SurfacePalette,
        ModuleAssetsRoot = resolvedOptions.ModuleAssetsRoot,
        RoomApothem = config.RoomApothem,
        IncludeRoomMarker = resolvedOptions.IncludeRoomMarkers ~= false,
        RoomMarkerTransparency = resolvedOptions.RoomMarkerTransparency,
        RoomKindColors = resolvedOptions.RoomKindColors,
        DetectionBuffer = resolvedOptions.DetectionBuffer,
    })

    local campCenter = rendered.RoomCenters[layout.CampRoomId]
    local extractionCenter = rendered.RoomCenters[layout.ExtractionRoomId]

    return {
        Root = rendered.Root,
        Layout = layout,
        RoomCenters = rendered.RoomCenters,
        RoomById = rendered.RoomById,
        RoomIds = rendered.RoomIds,
        RoomFolders = rendered.RoomFolders,
        Connectors = rendered.Connectors,
        ExitPassages = rendered.ExitPassages,
        CampCenter = campCenter,
        ExtractionCenter = extractionCenter,
        SpawnCFrame = CFrame.new(campCenter + Vector3.new(0, 4, 0)),
        ReturnHoldCFrame = CFrame.new(campCenter + Vector3.new(0, 4, -10)),
        Doorways = rendered.Doorways,
        ToggleDoor = rendered.ToggleDoor,
        FindRoomByPosition = rendered.FindRoomByPosition,
        CanTraverseBetweenPositions = rendered.CanTraverseBetweenPositions,
    }
end

return MazeWorldShellBuilder
