local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Workspace = game:GetService('Workspace')

local Packages = ReplicatedStorage:WaitForChild('Packages')
local Gameplay = require(Packages:WaitForChild('Gameplay'))

local MazeModuleAssetContract = require(script.Parent.MazeModuleAssetContract)
local MazePassageTemplates = Gameplay.ProcGen.MazePassageTemplates

local bit32_band = bit32.band
local bit32_lshift = bit32.lshift
local bit32_bor = bit32.bor
local math_ceil = math.ceil
local math_floor = math.floor
local math_sqrt = math.sqrt
local math_rad = math.rad
local math_cos = math.cos
local math_sin = math.sin
local math_tan = math.tan
local math_abs = math.abs
local math_pi = math.pi
local math_huge = math.huge

local Vector3_new = Vector3.new
local Vector3_zero = Vector3.zero
local CFrame_new = CFrame.new
local CFrame_lookAt = CFrame.lookAt
local Instance_new = Instance.new

local HexMazeWorldRenderer = {}

local ROOM_CLEAR_HEIGHT = 14
local ROOM_APOTHEM_DEFAULT = 20
local SLAB_THICKNESS = 1
local FLOOR_TILE_SIZE = 4
local WALL_HEIGHT = ROOM_CLEAR_HEIGHT
local WALL_THICKNESS = 2
local DOORWAY_WIDTH = 6
local DOORWAY_HEIGHT = 10
local DOOR_LEAF_THICKNESS = 0.5
local DOOR_CLEARANCE = 0
local ROOM_DETECTION_BUFFER = 18
local EXIT_CORRIDOR_LENGTH = 6
local CONNECTOR_OVERLAP = 1
local TAN_PI_6 = math_tan(math_pi / 6)
local HEX_CIRCUMRADIUS_MULTIPLIER = 1 / math_cos(math_pi / 6)
local SIDE_ANGLE_OFFSET_DEGREES = 0

local SIDE_NORMALS_X = {}
local SIDE_NORMALS_Z = {}
local SIDE_VECTORS_NORMAL = {}
local SIDE_VECTORS_TANGENT = {}
local SIDE_WALL_NAMES = {}
local SIDE_SEGMENT_NAMES = {}
local SIDE_LINTEL_NAMES = {}
local SIDE_ORIENTATIONS = {}

for directionIndex = 1, 6 do
    local angle = math_rad((-(directionIndex - 1) * 60) + SIDE_ANGLE_OFFSET_DEGREES)
    local nx = math_cos(angle)
    local nz = math_sin(angle)
    SIDE_NORMALS_X[directionIndex] = nx
    SIDE_NORMALS_Z[directionIndex] = nz
    local normal = Vector3_new(nx, 0, nz)
    SIDE_VECTORS_NORMAL[directionIndex] = normal
    SIDE_VECTORS_TANGENT[directionIndex] = Vector3_new(-nz, 0, nx)
    SIDE_WALL_NAMES[directionIndex] = 'Wall_' .. directionIndex
    SIDE_SEGMENT_NAMES[directionIndex] = 'Wall_' .. directionIndex .. '_Segment'
    SIDE_LINTEL_NAMES[directionIndex] = 'Wall_' .. directionIndex .. '_Lintel'
    SIDE_ORIENTATIONS[directionIndex] = CFrame_lookAt(Vector3_zero, normal)
end

local TILE_BUFFER_A = FLOOR_TILE_SIZE / 2
local TILE_BUFFER_B = (FLOOR_TILE_SIZE / 2) * (math_cos(math_rad(60)) + math_sin(math_rad(60)))
local SIN_60 = math_sin(math_rad(60))

local DEFAULT_SURFACE_PALETTE = table.freeze({
    WallMaterial = Enum.Material.Concrete,
    WallColor = Color3.fromRGB(116, 114, 110),
    FloorMaterial = Enum.Material.Concrete,
    FloorColor = Color3.fromRGB(98, 96, 92),
    CeilingMaterial = Enum.Material.Concrete,
    CeilingColor = Color3.fromRGB(88, 86, 82),
    DoorMaterial = Enum.Material.Concrete,
    DoorColor = Color3.fromRGB(74, 72, 68),
    ExitFloorMaterial = Enum.Material.Concrete,
    ExitFloorColor = Color3.fromRGB(40, 36, 28),
})

local DEFAULT_ROOM_KIND_COLORS = {
    Camp = Color3.fromRGB(83, 126, 78),
    Loot = Color3.fromRGB(88, 92, 112),
    Extraction = Color3.fromRGB(145, 119, 73),
}

local function resolveSurfacePalette(surfacePalette)
    local resolvedPalette = {}

    for property, defaultValue in pairs(DEFAULT_SURFACE_PALETTE) do
        resolvedPalette[property] = surfacePalette and surfacePalette[property] or defaultValue
    end

    return resolvedPalette
end

local function createPart(config, parent)
    local part = Instance_new('Part')
    part.Name = config.Name
    part.Anchored = true
    part.Size = config.Size
    part.CFrame = config.CFrame
    part.Color = config.Color
    part.Material = config.Material or Enum.Material.SmoothPlastic
    part.Transparency = config.Transparency or 0
    part.CanCollide = config.CanCollide ~= false
    part.Shape = config.Shape or Enum.PartType.Block
    part.Parent = parent
    return part
end

local function createPromptPart(config, parent)
    local part = createPart({
        Name = config.Name,
        Size = config.Size or Vector3_new(4, 4, 4),
        CFrame = config.CFrame,
        Color = config.Color,
        Material = config.Material or Enum.Material.Metal,
        Transparency = config.Transparency or 0,
        CanCollide = config.CanCollide,
        Shape = config.Shape,
    }, parent)

    local prompt = Instance_new('ProximityPrompt')
    prompt.ActionText = config.ActionText
    prompt.ObjectText = config.ObjectText
    prompt.HoldDuration = 0
    prompt.MaxActivationDistance = config.MaxActivationDistance or 10
    prompt.RequiresLineOfSight = false
    prompt.Parent = part

    return part, prompt
end

local function applyArchetypeShellAsset(roomFolder, roomCenter, room, moduleAssetsRoot)
    local shellModel = MazeModuleAssetContract.getRoomArchetypeShellModel(
        moduleAssetsRoot,
        room.AuthoringAssetId or room.ArchetypeId
    )
    if shellModel == nil then
        return
    end

    local clone = shellModel:Clone()
    clone.Name = string.format('AuthoredShell_%s', room.AuthoringAssetId or room.ArchetypeId)
    clone.Parent = roomFolder

    if clone:IsA('Model') then
        clone:PivotTo(CFrame_new(roomCenter))
    elseif clone:IsA('BasePart') then
        clone.CFrame = CFrame_new(roomCenter)
    end
end

local function applyShellModel(cloneParent, cloneName, shellModel, pivotCFrame)
    if shellModel == nil then
        return nil
    end

    local clone = shellModel:Clone()
    clone.Name = cloneName
    clone.Parent = cloneParent

    if clone:IsA('Model') then
        clone:PivotTo(pivotCFrame)
    elseif clone:IsA('BasePart') then
        clone.CFrame = pivotCFrame
    end

    return clone
end

local function createAuthoringSockets(roomFolder, roomCenter)
    local authoringFolder = Instance_new('Folder')
    authoringFolder.Name = 'AuthoringSockets'
    authoringFolder.Parent = roomFolder

    createPart({
        Name = 'ShellModelSocket',
        Size = Vector3_new(2, 2, 2),
        CFrame = CFrame_new(roomCenter + Vector3_new(0, 4, 0)),
        Color = Color3.fromRGB(255, 255, 255),
        Material = Enum.Material.ForceField,
        Transparency = 1,
        CanCollide = false,
    }, authoringFolder)
end

local function createConnectorAuthoringSockets(connectorFolder, connectorPivot)
    local authoringFolder = Instance_new('Folder')
    authoringFolder.Name = 'AuthoringSockets'
    authoringFolder.Parent = connectorFolder

    createPart({
        Name = 'ShellModelSocket',
        Size = Vector3_new(2, 2, 2),
        CFrame = connectorPivot,
        Color = Color3.fromRGB(255, 255, 255),
        Material = Enum.Material.ForceField,
        Transparency = 1,
        CanCollide = false,
    }, authoringFolder)

    return authoringFolder
end

local function addDecorPart(parent, roomCenter, name, size, offset, color, material, transparency)
    local part = Instance_new('Part')
    part.Name = name
    part.Anchored = true
    part.Size = size
    part.CFrame = CFrame_new(roomCenter + offset)
    part.Color = color
    part.Material = material or Enum.Material.SmoothPlastic
    part.Transparency = transparency or 0
    part.CanCollide = false
    part.Parent = parent
end

local function buildRoomTemplateDecor(roomFolder, room, roomCenter, roomApothem, surfacePalette)
    local decorFolder = Instance_new('Folder')
    decorFolder.Name = 'RoomTemplateDecor'
    decorFolder.Parent = roomFolder

    if room.RoomTemplateId == 'EntrySafe' then
        addDecorPart(
            decorFolder,
            roomCenter,
            'StagingPad',
            Vector3_new(roomApothem * 0.9, 0.4, roomApothem * 0.9),
            Vector3_new(0, 0.25, 0),
            Color3.fromRGB(98, 128, 112),
            Enum.Material.Metal
        )
        addDecorPart(
            decorFolder,
            roomCenter,
            'OrientationPylon',
            Vector3_new(2, 9, 2),
            Vector3_new(0, 4.5, roomApothem * 0.22),
            Color3.fromRGB(108, 152, 142),
            Enum.Material.Metal
        )
        return
    end

    if room.RoomTemplateId == 'TransitHall' then
        addDecorPart(
            decorFolder,
            roomCenter,
            'TransitBeam',
            Vector3_new(roomApothem * 1.05, 1.2, 3),
            Vector3_new(0, 10, 0),
            Color3.fromRGB(92, 102, 112),
            Enum.Material.Metal
        )
        addDecorPart(
            decorFolder,
            roomCenter,
            'TransitStripe',
            Vector3_new(roomApothem * 0.75, 0.15, 2),
            Vector3_new(0, 0.2, 0),
            Color3.fromRGB(124, 138, 150),
            Enum.Material.Neon,
            0.45
        )
        return
    end

    if room.RoomTemplateId == 'SearchCluster' then
        addDecorPart(
            decorFolder,
            roomCenter,
            'SearchCrateA',
            Vector3_new(5, 3, 4),
            Vector3_new(-roomApothem * 0.22, 1.5, 0),
            Color3.fromRGB(108, 100, 92),
            Enum.Material.WoodPlanks
        )
        addDecorPart(
            decorFolder,
            roomCenter,
            'SearchCrateB',
            Vector3_new(4, 2.2, 3),
            Vector3_new(roomApothem * 0.2, 1.1, roomApothem * 0.1),
            Color3.fromRGB(92, 90, 88),
            Enum.Material.Metal
        )
        return
    end

    if room.RoomTemplateId == 'HighValueRisk' then
        addDecorPart(
            decorFolder,
            roomCenter,
            'VaultCore',
            Vector3_new(7, 6, 7),
            Vector3_new(0, 3, 0),
            Color3.fromRGB(138, 118, 86),
            Enum.Material.Metal
        )
        addDecorPart(
            decorFolder,
            roomCenter,
            'HazardStrip',
            Vector3_new(roomApothem * 0.8, 0.2, 2),
            Vector3_new(0, 0.15, -roomApothem * 0.18),
            Color3.fromRGB(194, 156, 74),
            Enum.Material.Neon,
            0.3
        )
        return
    end

    if room.RoomTemplateId == 'LandmarkFacility' then
        addDecorPart(
            decorFolder,
            roomCenter,
            'LandmarkTower',
            Vector3_new(5, 12, 5),
            Vector3_new(0, 6, 0),
            Color3.fromRGB(82, 116, 136),
            Enum.Material.Metal
        )
        addDecorPart(
            decorFolder,
            roomCenter,
            'LandmarkRing',
            Vector3_new(roomApothem * 0.95, 0.2, roomApothem * 0.95),
            Vector3_new(0, 0.2, 0),
            Color3.fromRGB(96, 150, 184),
            Enum.Material.Neon,
            0.45
        )
        return
    end

    if room.RoomTemplateId == 'ExtractionReturn' then
        addDecorPart(
            decorFolder,
            roomCenter,
            'ExtractionFrame',
            Vector3_new(roomApothem * 0.95, 0.25, roomApothem * 0.95),
            Vector3_new(0, 0.2, 0),
            Color3.fromRGB(172, 142, 92),
            Enum.Material.Neon,
            0.35
        )
        addDecorPart(
            decorFolder,
            roomCenter,
            'ExtractionBeacon',
            Vector3_new(2.5, 10, 2.5),
            Vector3_new(0, 5, 0),
            Color3.fromRGB(184, 154, 98),
            Enum.Material.Metal
        )
        return
    end

    if room.RoomTemplateId == 'BulkheadGate' then
        addDecorPart(
            decorFolder,
            roomCenter,
            'BulkheadFrame',
            Vector3_new(roomApothem * 0.92, 7, 2),
            Vector3_new(0, 3.5, 0),
            Color3.fromRGB(126, 104, 88),
            Enum.Material.Metal
        )
        addDecorPart(
            decorFolder,
            roomCenter,
            'BulkheadThreshold',
            Vector3_new(roomApothem * 0.9, 0.2, 3),
            Vector3_new(0, 0.2, 0),
            Color3.fromRGB(154, 124, 92),
            Enum.Material.Neon,
            0.45
        )
        return
    end

    if room.RoomTemplateId == 'ShortcutLoop' then
        addDecorPart(
            decorFolder,
            roomCenter,
            'ShortcutBrace',
            Vector3_new(roomApothem * 0.8, 1.2, 3),
            Vector3_new(0, 9, 0),
            Color3.fromRGB(88, 118, 136),
            Enum.Material.Metal
        )
        addDecorPart(
            decorFolder,
            roomCenter,
            'ShortcutMarker',
            Vector3_new(roomApothem * 0.75, 0.15, 1.5),
            Vector3_new(0, 0.2, 0),
            surfacePalette.ExitFloorColor,
            Enum.Material.Neon,
            0.45
        )
    end
end

local function sideVectors(directionIndex)
    return SIDE_VECTORS_NORMAL[directionIndex], SIDE_VECTORS_TANGENT[directionIndex]
end

local function createHexTiledSlab(parent, name, center, apothem, yOffset, color, material)
    local slabFolder = Instance_new('Folder')
    slabFolder.Name = name
    slabFolder.Parent = parent

    local cx, cy, cz = center.X, center.Y, center.Z
    local tileSizeVector = Vector3_new(FLOOR_TILE_SIZE, SLAB_THICKNESS, FLOOR_TILE_SIZE)

    -- Bolt: Optimized loop bounds to eliminate redundant inner-loop condition checks.
    -- The hex boundary is defined by:
    --   |x| + TILE_BUFFER_A <= apothem
    --   |0.5x +/- SIN_60 * z| + TILE_BUFFER_B <= apothem
    local xLimit = apothem - TILE_BUFFER_A
    local xStart = math_ceil(-xLimit / FLOOR_TILE_SIZE) * FLOOR_TILE_SIZE
    local xEnd = math_floor(xLimit / FLOOR_TILE_SIZE) * FLOOR_TILE_SIZE
    local bPrime = apothem - TILE_BUFFER_B

    for x = xStart, xEnd, FLOOR_TILE_SIZE do
        -- Solve for z: |0.5x +/- SIN_60 * z| <= bPrime
        -- Yields: - (bPrime - 0.5|x|) / SIN_60 <= z <= (bPrime - 0.5|x|) / SIN_60
        local zMax = (bPrime - 0.5 * math_abs(x)) / SIN_60
        local zStart = math_ceil(-zMax / FLOOR_TILE_SIZE) * FLOOR_TILE_SIZE
        local zEnd = math_floor(zMax / FLOOR_TILE_SIZE) * FLOOR_TILE_SIZE

        for z = zStart, zEnd, FLOOR_TILE_SIZE do
            local part = Instance_new('Part')
            part.Name = 'Tile'
            part.Anchored = true
            part.Size = tileSizeVector
            part.CFrame = CFrame_new(cx + x, cy + yOffset, cz + z)
            part.Color = color
            part.Material = material
            part.Parent = slabFolder
        end
    end

    return slabFolder
end

local function createHexSideWall(
    parent,
    center,
    directionIndex,
    apothem,
    sideLength,
    hasDoorway,
    surfacePalette
)
    local nx = SIDE_NORMALS_X[directionIndex]
    local nz = SIDE_NORMALS_Z[directionIndex]
    local tangent = SIDE_VECTORS_TANGENT[directionIndex]

    -- Bolt: Inlined position calculation to avoid Vector3 allocations
    local wcx = center.X + nx * apothem
    local wcy = center.Y + WALL_HEIGHT / 2
    local wcz = center.Z + nz * apothem
    local wallForward = CFrame_new(wcx, wcy, wcz) * SIDE_ORIENTATIONS[directionIndex]

    if not hasDoorway then
        -- Bolt: Refactored to keep parity with createPart properties while avoiding table allocations
        local part = Instance_new('Part')
        part.Name = SIDE_WALL_NAMES[directionIndex]
        part.Anchored = true
        part.Size = Vector3_new(sideLength, WALL_HEIGHT, WALL_THICKNESS)
        part.CFrame = wallForward
        part.Color = surfacePalette.WallColor
        part.Material = surfacePalette.WallMaterial
        part.Transparency = 0
        part.CanCollide = true
        part.Shape = Enum.PartType.Block
        part.Parent = parent
        return
    end

    local segmentLength = (sideLength - DOORWAY_WIDTH) / 2
    local segmentOffset = (DOORWAY_WIDTH / 2) + (segmentLength / 2)
    local segmentSize = Vector3_new(segmentLength, WALL_HEIGHT, WALL_THICKNESS)

    for _, sign in ipairs({ -1, 1 }) do
        local part = Instance_new('Part')
        part.Name = SIDE_SEGMENT_NAMES[directionIndex]
        part.Anchored = true
        part.Size = segmentSize
        part.CFrame = wallForward + (tangent * (segmentOffset * sign))
        part.Color = surfacePalette.WallColor
        part.Material = surfacePalette.WallMaterial
        part.Transparency = 0
        part.CanCollide = true
        part.Shape = Enum.PartType.Block
        part.Parent = parent
    end

    local lintelHeight = WALL_HEIGHT - DOORWAY_HEIGHT
    if lintelHeight > 0 then
        local part = Instance_new('Part')
        part.Name = SIDE_LINTEL_NAMES[directionIndex]
        part.Anchored = true
        part.Size = Vector3_new(DOORWAY_WIDTH, lintelHeight, WALL_THICKNESS)
        part.CFrame = wallForward + Vector3_new(0, DOORWAY_HEIGHT + (lintelHeight / 2), 0)
        part.Color = surfacePalette.WallColor
        part.Material = surfacePalette.WallMaterial
        part.Transparency = 0
        part.CanCollide = true
        part.Shape = Enum.PartType.Block
        part.Parent = parent
    end
end

local function applyDoorState(doorway, isOpen)
    doorway.IsOpen = isOpen
    if not doorway.HasDoorLeaves then
        return
    end

    doorway.Prompt.ActionText = isOpen and 'Close' or 'Open'
    doorway.LeftLeaf.CFrame = isOpen and doorway.OpenLeftCFrame or doorway.ClosedLeftCFrame
    doorway.RightLeaf.CFrame = isOpen and doorway.OpenRightCFrame or doorway.ClosedRightCFrame
    doorway.LeftLeaf.CanCollide = not isOpen
    doorway.RightLeaf.CanCollide = not isOpen
end

local function createDoorwayInstance(
    parent,
    doorwayId,
    center,
    directionIndex,
    apothem,
    hasDoorLeaves,
    surfacePalette
)
    local normal, tangent = sideVectors(directionIndex)
    local openingCenter = center + normal * (apothem - WALL_THICKNESS * 0.5)
    local doorway = {
        Id = doorwayId,
        HasDoorLeaves = hasDoorLeaves == true,
        IsOpen = hasDoorLeaves ~= true,
        Prompt = nil,
    }

    if not doorway.HasDoorLeaves then
        return doorway
    end

    local leafWidth = (DOORWAY_WIDTH - (DOOR_CLEARANCE * 3)) / 2
    local closedLeftCenter = openingCenter
        - tangent * ((leafWidth / 2) + (DOOR_CLEARANCE / 2))
        + Vector3_new(0, DOORWAY_HEIGHT / 2, 0)
    local closedRightCenter = openingCenter
        + tangent * ((leafWidth / 2) + (DOOR_CLEARANCE / 2))
        + Vector3_new(0, DOORWAY_HEIGHT / 2, 0)

    local openOffset = (DOORWAY_WIDTH / 2) + (leafWidth / 2) + DOOR_CLEARANCE
    local openLeftCenter = openingCenter
        - tangent * openOffset
        + Vector3_new(0, DOORWAY_HEIGHT / 2, 0)
    local openRightCenter = openingCenter
        + tangent * openOffset
        + Vector3_new(0, DOORWAY_HEIGHT / 2, 0)

    local leafOrientation = CFrame_lookAt(Vector3_zero, normal)
    doorway.ClosedLeftCFrame = CFrame_new(closedLeftCenter) * leafOrientation
    doorway.ClosedRightCFrame = CFrame_new(closedRightCenter) * leafOrientation
    doorway.OpenLeftCFrame = CFrame_new(openLeftCenter) * leafOrientation
    doorway.OpenRightCFrame = CFrame_new(openRightCenter) * leafOrientation

    doorway.LeftLeaf = createPart({
        Name = string.format('Door_%s_Left', doorwayId),
        Size = Vector3_new(leafWidth, DOORWAY_HEIGHT, DOOR_LEAF_THICKNESS),
        CFrame = doorway.ClosedLeftCFrame,
        Color = surfacePalette.DoorColor,
        Material = surfacePalette.DoorMaterial,
    }, parent)

    doorway.RightLeaf = createPart({
        Name = string.format('Door_%s_Right', doorwayId),
        Size = Vector3_new(leafWidth, DOORWAY_HEIGHT, DOOR_LEAF_THICKNESS),
        CFrame = doorway.ClosedRightCFrame,
        Color = surfacePalette.DoorColor,
        Material = surfacePalette.DoorMaterial,
    }, parent)

    local _, prompt = createPromptPart({
        Name = string.format('DoorPrompt_%s', doorwayId),
        Size = Vector3_new(2, 2, 2),
        CFrame = CFrame_new(openingCenter + Vector3_new(0, 2, 0)),
        Color = Color3.fromRGB(118, 136, 150),
        Material = Enum.Material.Metal,
        Transparency = 1,
        CanCollide = false,
        ActionText = 'Open',
        ObjectText = 'Double Door',
        MaxActivationDistance = 12,
    }, parent)
    doorway.Prompt = prompt

    applyDoorState(doorway, false)
    return doorway
end

local function buildRoom(parent, room, roomCenter, roomApothem, options)
    local roomFolder = Instance_new('Folder')
    roomFolder.Name = room.Id
    roomFolder.Parent = parent

    createHexTiledSlab(
        roomFolder,
        'FloorTiles',
        roomCenter,
        roomApothem,
        -(SLAB_THICKNESS / 2),
        options.SurfacePalette.FloorColor,
        options.SurfacePalette.FloorMaterial
    )
    createHexTiledSlab(
        roomFolder,
        'CeilingTiles',
        roomCenter,
        roomApothem,
        ROOM_CLEAR_HEIGHT + (SLAB_THICKNESS / 2),
        options.SurfacePalette.CeilingColor,
        options.SurfacePalette.CeilingMaterial
    )

    if options.IncludeRoomMarker then
        local floorDiameter = roomApothem * HEX_CIRCUMRADIUS_MULTIPLIER * 2
        local roomKindColors = options.RoomKindColors or DEFAULT_ROOM_KIND_COLORS
        createPart({
            Name = 'RoomMarker',
            Size = Vector3_new(floorDiameter - 6, 0.3, floorDiameter - 6),
            CFrame = CFrame_new(roomCenter + Vector3_new(0, 0.15, 0)),
            Color = roomKindColors[room.Kind] or Color3.fromRGB(112, 112, 112),
            Material = Enum.Material.SmoothPlastic,
            Transparency = options.RoomMarkerTransparency or 0.6,
            CanCollide = false,
        }, roomFolder)
    end

    local sideLength = 2 * roomApothem * TAN_PI_6
    for directionIndex = 1, 6 do
        createHexSideWall(
            roomFolder,
            roomCenter,
            directionIndex,
            roomApothem,
            sideLength,
            room.Neighbors[directionIndex] ~= nil,
            options.SurfacePalette
        )
    end

    createAuthoringSockets(roomFolder, roomCenter)

    buildRoomTemplateDecor(roomFolder, room, roomCenter, roomApothem, options.SurfacePalette)

    applyArchetypeShellAsset(roomFolder, roomCenter, room, options.ModuleAssetsRoot)

    return roomFolder
end

local function resolvePassageDefinition(archetypeId)
    return MazePassageTemplates.getDefinition(archetypeId)
        or MazePassageTemplates.getDefinition('IndustrialHall')
end

local function buildPassageMock(
    passageFolder,
    namePrefix,
    corridorForward,
    passageLength,
    passageArchetypeId,
    surfacePalette,
    floorColor,
    floorMaterial
)
    local passageDefinition = resolvePassageDefinition(passageArchetypeId)
    local passageWidth = passageDefinition.Width or DOORWAY_WIDTH
    local passageHeight = passageDefinition.Height or ROOM_CLEAR_HEIGHT
    local wallThickness = WALL_THICKNESS * (passageDefinition.WallThicknessMultiplier or 1)

    createPart({
        Name = string.format('%sFloor', namePrefix),
        Size = Vector3_new(passageWidth, SLAB_THICKNESS, passageLength),
        CFrame = corridorForward,
        Color = floorColor or surfacePalette.FloorColor,
        Material = floorMaterial or surfacePalette.FloorMaterial,
    }, passageFolder)

    createPart({
        Name = string.format('%sCeiling', namePrefix),
        Size = Vector3_new(passageWidth, SLAB_THICKNESS, passageLength),
        CFrame = corridorForward + Vector3_new(0, passageHeight + SLAB_THICKNESS, 0),
        Color = surfacePalette.CeilingColor,
        Material = surfacePalette.CeilingMaterial,
    }, passageFolder)

    local normal = corridorForward.LookVector
    local tangent = Vector3_new(-normal.Z, 0, normal.X)

    for _, sign in ipairs({ -1, 1 }) do
        createPart({
            Name = string.format('%sWall', namePrefix),
            Size = Vector3_new(wallThickness, passageHeight, passageLength),
            CFrame = corridorForward
                + (tangent * ((passageWidth / 2) + (wallThickness / 2)) * sign)
                + Vector3_new(0, (passageHeight + SLAB_THICKNESS) / 2, 0),
            Color = surfacePalette.WallColor,
            Material = surfacePalette.WallMaterial,
        }, passageFolder)
    end

    createPart({
        Name = string.format('%sAccent', namePrefix),
        Size = Vector3_new(passageWidth * 0.85, 0.12, 1.5),
        CFrame = corridorForward + Vector3_new(0, (SLAB_THICKNESS / 2) + 0.06, 0),
        Color = passageDefinition.AccentColor,
        Material = Enum.Material.Neon,
        Transparency = 0.5,
        CanCollide = false,
    }, passageFolder)
end

local function buildPassageInstance(
    parent,
    folderName,
    namePrefix,
    pivotName,
    passageCenter,
    corridorForward,
    passageLength,
    passageArchetypeId,
    surfacePalette,
    moduleAssetsRoot,
    floorColor,
    floorMaterial
)
    local passageDefinition = resolvePassageDefinition(passageArchetypeId)
    local passagePivot = CFrame_new(
        passageCenter + Vector3_new(0, (passageDefinition.Height or ROOM_CLEAR_HEIGHT) / 2, 0)
    ) * CFrame_lookAt(Vector3_zero, corridorForward.LookVector)

    local passageFolder = Instance_new('Folder')
    passageFolder.Name = folderName
    passageFolder.Parent = parent

    local authoringSockets = createConnectorAuthoringSockets(passageFolder, passagePivot)
    local authoredShell = applyShellModel(
        passageFolder,
        string.format('AuthoredPassageShell_%s', passageArchetypeId),
        MazeModuleAssetContract.getConnectorShellModel(moduleAssetsRoot, passageArchetypeId),
        passagePivot
    )

    if authoredShell == nil then
        buildPassageMock(
            passageFolder,
            namePrefix,
            corridorForward,
            passageLength,
            passageArchetypeId,
            surfacePalette,
            floorColor,
            floorMaterial
        )
    end

    return {
        Id = pivotName,
        ArchetypeId = passageArchetypeId,
        Root = passageFolder,
        Shell = authoredShell,
        AuthoringSockets = authoringSockets,
        Length = passageLength,
    }
end

local function buildRoomConnector(
    parent,
    doorwayId,
    roomCenterA,
    roomCenterB,
    directionFromA,
    roomApothem,
    passageArchetypeId,
    surfacePalette,
    moduleAssetsRoot
)
    local normal = sideVectors(directionFromA)
    local centerDistance = (roomCenterB - roomCenterA).Magnitude
    local connectorLength = math.max(
        WALL_THICKNESS,
        centerDistance - (roomApothem * 2) + (WALL_THICKNESS + CONNECTOR_OVERLAP)
    )
    local connectorCenter = (roomCenterA + roomCenterB) * 0.5
    local floorCenter = connectorCenter + Vector3_new(0, -(SLAB_THICKNESS / 2), 0)
    local corridorForward = CFrame_lookAt(floorCenter, floorCenter + normal)

    return buildPassageInstance(
        parent,
        string.format('Connector_%s', doorwayId),
        string.format('Connector_%s_', doorwayId),
        doorwayId,
        connectorCenter,
        corridorForward,
        connectorLength,
        passageArchetypeId,
        surfacePalette,
        moduleAssetsRoot
    )
end

local function buildExitPassages(
    parent,
    room,
    roomCenter,
    roomApothem,
    roomExternalDoorways,
    surfacePalette,
    moduleAssetsRoot
)
    local exitPassages = {}

    for _, externalDoorway in ipairs(roomExternalDoorways or {}) do
        local directionIndex = externalDoorway.Direction
        local normal = sideVectors(directionIndex)
        local passageLength = EXIT_CORRIDOR_LENGTH + WALL_THICKNESS + CONNECTOR_OVERLAP
        local floorCenter = roomCenter
            + (normal * (roomApothem + (EXIT_CORRIDOR_LENGTH / 2)))
            + Vector3_new(0, -(SLAB_THICKNESS / 2), 0)
        local passageCenter = floorCenter + Vector3_new(0, SLAB_THICKNESS / 2, 0)
        local corridorForward = CFrame_lookAt(floorCenter, floorCenter + normal)
        local passageId = string.format('%s_%d', room.Id, directionIndex)

        exitPassages[passageId] = buildPassageInstance(
            parent,
            string.format('ExitPassage_%s', passageId),
            string.format('ExitPassage_%s_', passageId),
            passageId,
            passageCenter,
            corridorForward,
            passageLength,
            externalDoorway.PassageArchetypeId,
            surfacePalette,
            moduleAssetsRoot,
            surfacePalette.ExitFloorColor,
            surfacePalette.ExitFloorMaterial
        )
    end

    return exitPassages
end

function HexMazeWorldRenderer.build(params)
    local worldName = params.WorldName or 'GeneratedMazeWorld'
    local layout = params.Layout
    local originOffset = params.OriginOffset or Vector3_zero
    local roomApothem = math.max(8, params.RoomApothem or ROOM_APOTHEM_DEFAULT)
    local includeRoomMarker = params.IncludeRoomMarker ~= false
    local parent = params.Parent or Workspace
    local detectionBuffer = params.DetectionBuffer or ROOM_DETECTION_BUFFER
    local surfacePalette = resolveSurfacePalette(params.SurfacePalette)

    local existing = parent:FindFirstChild(worldName)
    if existing then
        existing:Destroy()
    end

    local worldFolder = Instance_new('Folder')
    worldFolder.Name = worldName
    worldFolder.Parent = parent

    local cellSize = roomApothem * 2
    local spatialHash = {}

    local roomCenters = {}
    local roomById = {}
    local roomIds = {}
    local roomFolders = {}
    local connectors = {}
    local exitPassages = {}
    local doorways = {}
    local doorwayByRoomIds = {}
    local externalDoorwaysByRoomId = {}

    for _, externalDoorway in ipairs(layout.ExternalDoorways or {}) do
        externalDoorwaysByRoomId[externalDoorway.RoomId] = externalDoorwaysByRoomId[externalDoorway.RoomId]
            or {}
        table.insert(externalDoorwaysByRoomId[externalDoorway.RoomId], externalDoorway)
    end

    for roomId in pairs(layout.Rooms) do
        table.insert(roomIds, roomId)
    end
    table.sort(roomIds)

    for _, roomId in ipairs(roomIds) do
        local room = layout.Rooms[roomId]
        local roomCenter = room.Position + originOffset
        roomCenters[roomId] = roomCenter
        roomById[roomId] = room

        local cq = math_floor(roomCenter.X / cellSize)
        local cr = math_floor(roomCenter.Z / cellSize)
        local key = bit32_bor(bit32_lshift(bit32_band(cq, 0xFFFF), 16), bit32_band(cr, 0xFFFF))

        if not spatialHash[key] then
            spatialHash[key] = {}
        end
        table.insert(spatialHash[key], roomId)

        roomFolders[roomId] = buildRoom(worldFolder, room, roomCenter, roomApothem, {
            IncludeRoomMarker = includeRoomMarker,
            RoomMarkerTransparency = params.RoomMarkerTransparency,
            RoomKindColors = params.RoomKindColors,
            ModuleAssetsRoot = params.ModuleAssetsRoot,
            SurfacePalette = surfacePalette,
        })
        for exitPassageId, exitPassage in
            pairs(
                buildExitPassages(
                    worldFolder,
                    room,
                    roomCenter,
                    roomApothem,
                    externalDoorwaysByRoomId[roomId],
                    surfacePalette,
                    params.ModuleAssetsRoot
                )
            )
        do
            exitPassages[exitPassageId] = exitPassage
        end
    end

    for doorwayId, doorwayLayout in pairs(layout.Doorways) do
        local roomCenter = roomCenters[doorwayLayout.RoomA]
        local otherRoomCenter = roomCenters[doorwayLayout.RoomB]
        if not roomCenter then
            continue
        end

        if otherRoomCenter then
            connectors[doorwayId] = buildRoomConnector(
                worldFolder,
                doorwayId,
                roomCenter,
                otherRoomCenter,
                doorwayLayout.DirectionFromA,
                roomApothem,
                doorwayLayout.PassageArchetypeId,
                surfacePalette,
                params.ModuleAssetsRoot
            )
        end

        local doorway = createDoorwayInstance(
            worldFolder,
            doorwayId,
            roomCenter,
            doorwayLayout.DirectionFromA,
            roomApothem,
            doorwayLayout.HasDoorLeaves,
            surfacePalette
        )
        doorway.RoomA = doorwayLayout.RoomA
        doorway.RoomB = doorwayLayout.RoomB
        doorway.DirectionFromA = doorwayLayout.DirectionFromA
        doorway.DirectionFromB = doorwayLayout.DirectionFromB
        doorways[doorwayId] = doorway

        local roomAId = doorwayLayout.RoomA
        local roomBId = doorwayLayout.RoomB

        if not doorwayByRoomIds[roomAId] then
            doorwayByRoomIds[roomAId] = {}
        end
        if not doorwayByRoomIds[roomBId] then
            doorwayByRoomIds[roomBId] = {}
        end
        doorwayByRoomIds[roomAId][roomBId] = doorway
        doorwayByRoomIds[roomBId][roomAId] = doorway
    end

    local detectionRadius = roomApothem + detectionBuffer
    local detectionRadiusSq = detectionRadius * detectionRadius
    local searchRadiusCells = math_ceil(detectionRadius / cellSize)
    if searchRadiusCells < 1 then
        searchRadiusCells = 1
    end

    local function findRoomByPosition(position)
        local nearestRoom = nil
        local nearestDistanceSq = math_huge

        local px, pz = position.X, position.Z
        local pq = math_floor(px / cellSize)
        local pr = math_floor(pz / cellSize)

        for dq = -searchRadiusCells, searchRadiusCells do
            -- Bolt: Hoist the bit-shifted component out of the inner dr loop
            local qPart = bit32_lshift(bit32_band(pq + dq, 0xFFFF), 16)

            for dr = -searchRadiusCells, searchRadiusCells do
                local key = bit32_bor(qPart, bit32_band(pr + dr, 0xFFFF))
                local cell = spatialHash[key]
                if cell then
                    for _, roomId in ipairs(cell) do
                        local roomCenter = roomCenters[roomId]
                        local dx = roomCenter.X - px
                        local dz = roomCenter.Z - pz
                        local distSq = dx * dx + dz * dz
                        if distSq < nearestDistanceSq then
                            nearestDistanceSq = distSq
                            nearestRoom = roomById[roomId]
                        end
                    end
                end
            end
        end

        local nearestDistance = math_sqrt(nearestDistanceSq)
        if nearestDistanceSq <= detectionRadiusSq then
            return nearestRoom, nearestDistance
        end

        return nil, nearestDistance
    end

    local function canTraverseBetweenPositions(fromPosition, toPosition)
        local fromRoom = findRoomByPosition(fromPosition)
        local toRoom = findRoomByPosition(toPosition)

        if not fromRoom or not toRoom then
            return true
        end

        local fromRoomId = fromRoom.Id
        local toRoomId = toRoom.Id

        if fromRoomId == toRoomId then
            return true
        end

        -- Bolt: Replaced string-based edgeKey with O(1) nested table lookup
        local doorway = doorwayByRoomIds[fromRoom.Id] and doorwayByRoomIds[fromRoom.Id][toRoom.Id]
        if not doorway then
            return false
        end
        if doorway.HasDoorLeaves and not doorway.IsOpen then
            return false
        end

        return true
    end

    local function toggleDoor(doorwayId)
        local doorway = doorways[doorwayId]
        if not doorway or not doorway.HasDoorLeaves then
            return false
        end

        applyDoorState(doorway, not doorway.IsOpen)
        return true
    end

    return {
        Root = worldFolder,
        Layout = layout,
        RoomCenters = roomCenters,
        RoomById = roomById,
        RoomIds = roomIds,
        RoomFolders = roomFolders,
        Connectors = connectors,
        ExitPassages = exitPassages,
        Doorways = doorways,
        ToggleDoor = toggleDoor,
        FindRoomByPosition = findRoomByPosition,
        CanTraverseBetweenPositions = canTraverseBetweenPositions,
    }
end

return HexMazeWorldRenderer
