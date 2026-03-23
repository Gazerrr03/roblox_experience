local Workspace = game:GetService('Workspace')

local MazeModuleAssetContract = require(script.Parent.MazeModuleAssetContract)

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
local HEX_CIRCUMRADIUS_MULTIPLIER = 1 / math.cos(math.pi / 6)
local SIDE_ANGLE_OFFSET_DEGREES = 0

local WALL_MATERIAL = Enum.Material.Concrete
local WALL_COLOR = Color3.fromRGB(116, 114, 110)
local FLOOR_MATERIAL = Enum.Material.Concrete
local FLOOR_COLOR = Color3.fromRGB(98, 96, 92)
local CEILING_COLOR = Color3.fromRGB(88, 86, 82)
local DOOR_MATERIAL = Enum.Material.Concrete
local DOOR_COLOR = Color3.fromRGB(74, 72, 68)
local EXIT_FLOOR_COLOR = Color3.fromRGB(40, 36, 28)

local DEFAULT_ROOM_KIND_COLORS = {
    Camp = Color3.fromRGB(83, 126, 78),
    Loot = Color3.fromRGB(88, 92, 112),
    Extraction = Color3.fromRGB(145, 119, 73),
}
local CAVE_ROCK_COLOR = Color3.fromRGB(84, 81, 76)
local CAVE_ROCK_MATERIAL = Enum.Material.Slate

local function edgeKey(roomIdA, roomIdB)
    if roomIdA < roomIdB then
        return string.format('%s|%s', roomIdA, roomIdB)
    end

    return string.format('%s|%s', roomIdB, roomIdA)
end

local function createPart(config, parent)
    local part = Instance.new('Part')
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
        Size = config.Size or Vector3.new(4, 4, 4),
        CFrame = config.CFrame,
        Color = config.Color,
        Material = config.Material or Enum.Material.Metal,
        Transparency = config.Transparency or 0,
        CanCollide = config.CanCollide,
        Shape = config.Shape,
    }, parent)

    local prompt = Instance.new('ProximityPrompt')
    prompt.ActionText = config.ActionText
    prompt.ObjectText = config.ObjectText
    prompt.HoldDuration = 0
    prompt.MaxActivationDistance = config.MaxActivationDistance or 10
    prompt.RequiresLineOfSight = false
    prompt.Parent = part

    return part, prompt
end

local function applyArchetypeShellAsset(roomFolder, roomCenter, room, moduleAssetsRoot)
    local shellModel =
        MazeModuleAssetContract.getRoomArchetypeShellModel(moduleAssetsRoot, room.ArchetypeId)
    if shellModel == nil then
        return
    end

    local clone = shellModel:Clone()
    clone.Name = string.format('AuthoredShell_%s', room.ArchetypeId)
    clone.Parent = roomFolder

    if clone:IsA('Model') then
        clone:PivotTo(CFrame.new(roomCenter))
    elseif clone:IsA('BasePart') then
        clone.CFrame = CFrame.new(roomCenter)
    end
end

local function createAuthoringSockets(roomFolder, roomCenter)
    local authoringFolder = Instance.new('Folder')
    authoringFolder.Name = 'AuthoringSockets'
    authoringFolder.Parent = roomFolder

    createPart({
        Name = 'ShellModelSocket',
        Size = Vector3.new(2, 2, 2),
        CFrame = CFrame.new(roomCenter + Vector3.new(0, 4, 0)),
        Color = Color3.fromRGB(255, 255, 255),
        Material = Enum.Material.ForceField,
        Transparency = 1,
        CanCollide = false,
    }, authoringFolder)
end

local function buildCavePocketDecor(roomFolder, roomCenter, roomApothem)
    local caveDecorFolder = Instance.new('Folder')
    caveDecorFolder.Name = 'CavePocketDecor'
    caveDecorFolder.Parent = roomFolder

    for index, decorConfig in ipairs({
        {
            Offset = Vector3.new(-roomApothem * 0.42, 2.4, -roomApothem * 0.12),
            Size = Vector3.new(8, 5, 7),
            Shape = Enum.PartType.Ball,
        },
        {
            Offset = Vector3.new(roomApothem * 0.38, 1.8, roomApothem * 0.18),
            Size = Vector3.new(9, 4, 6),
            Shape = Enum.PartType.Ball,
        },
        {
            Offset = Vector3.new(0, 11, roomApothem * 0.34),
            Size = Vector3.new(roomApothem * 0.8, 3, 6),
            Shape = Enum.PartType.Block,
        },
    }) do
        createPart({
            Name = string.format('CaveRock_%d', index),
            Size = decorConfig.Size,
            CFrame = CFrame.new(roomCenter + decorConfig.Offset),
            Color = CAVE_ROCK_COLOR,
            Material = CAVE_ROCK_MATERIAL,
            Shape = decorConfig.Shape,
            CanCollide = false,
        }, caveDecorFolder)
    end
end

local function sideVectors(directionIndex)
    local angle = math.rad((-(directionIndex - 1) * 60) + SIDE_ANGLE_OFFSET_DEGREES)
    local normal = Vector3.new(math.cos(angle), 0, math.sin(angle))
    local tangent = Vector3.new(-normal.Z, 0, normal.X)
    return normal, tangent
end

local function isInsideHex(offset, apothem)
    for directionIndex = 1, 6 do
        local normal = sideVectors(directionIndex)
        if offset:Dot(normal) > apothem then
            return false
        end
    end

    return true
end

local function createHexTiledSlab(parent, name, center, apothem, yOffset, color)
    local slabFolder = Instance.new('Folder')
    slabFolder.Name = name
    slabFolder.Parent = parent

    local radius = apothem * HEX_CIRCUMRADIUS_MULTIPLIER
    local halfTile = FLOOR_TILE_SIZE / 2
    local maxOffset = math.ceil(radius / FLOOR_TILE_SIZE) * FLOOR_TILE_SIZE
    local tileCount = 0

    for x = -maxOffset, maxOffset, FLOOR_TILE_SIZE do
        for z = -maxOffset, maxOffset, FLOOR_TILE_SIZE do
            local tileCenterOffset = Vector3.new(x, 0, z)
            local cornersInside = true

            for _, cornerX in ipairs({ -halfTile, halfTile }) do
                for _, cornerZ in ipairs({ -halfTile, halfTile }) do
                    local cornerOffset = tileCenterOffset + Vector3.new(cornerX, 0, cornerZ)
                    if not isInsideHex(cornerOffset, apothem) then
                        cornersInside = false
                        break
                    end
                end

                if not cornersInside then
                    break
                end
            end

            if cornersInside then
                tileCount += 1
                createPart({
                    Name = string.format('%sTile_%d', name, tileCount),
                    Size = Vector3.new(FLOOR_TILE_SIZE, SLAB_THICKNESS, FLOOR_TILE_SIZE),
                    CFrame = CFrame.new(center + tileCenterOffset + Vector3.new(0, yOffset, 0)),
                    Color = color,
                    Material = FLOOR_MATERIAL,
                }, slabFolder)
            end
        end
    end

    return slabFolder
end

local function createHexSideWall(parent, center, directionIndex, apothem, sideLength, hasDoorway)
    local normal, tangent = sideVectors(directionIndex)
    local wallCenter = center + normal * apothem + Vector3.new(0, WALL_HEIGHT / 2, 0)
    local wallForward = CFrame.lookAt(wallCenter, wallCenter + normal)

    if not hasDoorway then
        createPart({
            Name = string.format('Wall_%d', directionIndex),
            Size = Vector3.new(sideLength, WALL_HEIGHT, WALL_THICKNESS),
            CFrame = wallForward,
            Color = WALL_COLOR,
            Material = WALL_MATERIAL,
        }, parent)
        return
    end

    local segmentLength = (sideLength - DOORWAY_WIDTH) / 2
    local segmentOffset = (DOORWAY_WIDTH / 2) + (segmentLength / 2)

    for _, sign in ipairs({ -1, 1 }) do
        createPart({
            Name = string.format('Wall_%d_Segment', directionIndex),
            Size = Vector3.new(segmentLength, WALL_HEIGHT, WALL_THICKNESS),
            CFrame = wallForward + (tangent * (segmentOffset * sign)),
            Color = WALL_COLOR,
            Material = WALL_MATERIAL,
        }, parent)
    end

    local lintelHeight = WALL_HEIGHT - DOORWAY_HEIGHT
    if lintelHeight > 0 then
        createPart({
            Name = string.format('Wall_%d_Lintel', directionIndex),
            Size = Vector3.new(DOORWAY_WIDTH, lintelHeight, WALL_THICKNESS),
            CFrame = wallForward + Vector3.new(0, DOORWAY_HEIGHT + (lintelHeight / 2), 0),
            Color = WALL_COLOR,
            Material = WALL_MATERIAL,
        }, parent)
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
    hasDoorLeaves
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
        + Vector3.new(0, DOORWAY_HEIGHT / 2, 0)
    local closedRightCenter = openingCenter
        + tangent * ((leafWidth / 2) + (DOOR_CLEARANCE / 2))
        + Vector3.new(0, DOORWAY_HEIGHT / 2, 0)

    local openOffset = (DOORWAY_WIDTH / 2) + (leafWidth / 2) + DOOR_CLEARANCE
    local openLeftCenter = openingCenter
        - tangent * openOffset
        + Vector3.new(0, DOORWAY_HEIGHT / 2, 0)
    local openRightCenter = openingCenter
        + tangent * openOffset
        + Vector3.new(0, DOORWAY_HEIGHT / 2, 0)

    local leafOrientation = CFrame.lookAt(Vector3.zero, normal)
    doorway.ClosedLeftCFrame = CFrame.new(closedLeftCenter) * leafOrientation
    doorway.ClosedRightCFrame = CFrame.new(closedRightCenter) * leafOrientation
    doorway.OpenLeftCFrame = CFrame.new(openLeftCenter) * leafOrientation
    doorway.OpenRightCFrame = CFrame.new(openRightCenter) * leafOrientation

    doorway.LeftLeaf = createPart({
        Name = string.format('Door_%s_Left', doorwayId),
        Size = Vector3.new(leafWidth, DOORWAY_HEIGHT, DOOR_LEAF_THICKNESS),
        CFrame = doorway.ClosedLeftCFrame,
        Color = DOOR_COLOR,
        Material = DOOR_MATERIAL,
    }, parent)

    doorway.RightLeaf = createPart({
        Name = string.format('Door_%s_Right', doorwayId),
        Size = Vector3.new(leafWidth, DOORWAY_HEIGHT, DOOR_LEAF_THICKNESS),
        CFrame = doorway.ClosedRightCFrame,
        Color = DOOR_COLOR,
        Material = DOOR_MATERIAL,
    }, parent)

    local _, prompt = createPromptPart({
        Name = string.format('DoorPrompt_%s', doorwayId),
        Size = Vector3.new(2, 2, 2),
        CFrame = CFrame.new(openingCenter + Vector3.new(0, 2, 0)),
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
    local roomFolder = Instance.new('Folder')
    roomFolder.Name = room.Id
    roomFolder.Parent = parent

    createHexTiledSlab(
        roomFolder,
        'FloorTiles',
        roomCenter,
        roomApothem,
        -(SLAB_THICKNESS / 2),
        FLOOR_COLOR
    )
    createHexTiledSlab(
        roomFolder,
        'CeilingTiles',
        roomCenter,
        roomApothem,
        ROOM_CLEAR_HEIGHT + (SLAB_THICKNESS / 2),
        CEILING_COLOR
    )

    if options.IncludeRoomMarker then
        local floorDiameter = roomApothem * HEX_CIRCUMRADIUS_MULTIPLIER * 2
        local roomKindColors = options.RoomKindColors or DEFAULT_ROOM_KIND_COLORS
        createPart({
            Name = 'RoomMarker',
            Size = Vector3.new(floorDiameter - 6, 0.3, floorDiameter - 6),
            CFrame = CFrame.new(roomCenter + Vector3.new(0, 0.15, 0)),
            Color = roomKindColors[room.Kind] or Color3.fromRGB(112, 112, 112),
            Material = Enum.Material.SmoothPlastic,
            Transparency = options.RoomMarkerTransparency or 0.6,
            CanCollide = false,
        }, roomFolder)
    end

    local doorwayDirections = {}
    for directionIndex in pairs(room.Neighbors) do
        doorwayDirections[directionIndex] = true
    end
    for _, directionIndex in ipairs(room.ExitDirections or {}) do
        doorwayDirections[directionIndex] = true
    end

    local sideLength = 2 * roomApothem * math.tan(math.pi / 6)
    for directionIndex = 1, 6 do
        createHexSideWall(
            roomFolder,
            roomCenter,
            directionIndex,
            roomApothem,
            sideLength,
            doorwayDirections[directionIndex] == true
        )
    end

    createAuthoringSockets(roomFolder, roomCenter)

    if room.ArchetypeId == 'CavePocket' then
        buildCavePocketDecor(roomFolder, roomCenter, roomApothem)
    end

    applyArchetypeShellAsset(roomFolder, roomCenter, room, options.ModuleAssetsRoot)

    return roomFolder
end

local function buildExitCorridors(parent, room, roomCenter, roomApothem)
    for _, directionIndex in ipairs(room.ExitDirections or {}) do
        local normal = sideVectors(directionIndex)
        local corridorCenter = roomCenter
            + (normal * (roomApothem + (EXIT_CORRIDOR_LENGTH / 2)))
            + Vector3.new(0, -(SLAB_THICKNESS / 2), 0)
        local corridorForward = CFrame.lookAt(corridorCenter, corridorCenter + normal)

        createPart({
            Name = string.format('ExitCorridor_%s_%d', room.Id, directionIndex),
            Size = Vector3.new(DOORWAY_WIDTH, SLAB_THICKNESS, EXIT_CORRIDOR_LENGTH),
            CFrame = corridorForward,
            Color = EXIT_FLOOR_COLOR,
            Material = FLOOR_MATERIAL,
        }, parent)
    end
end

function HexMazeWorldRenderer.build(params)
    local worldName = params.WorldName or 'GeneratedMazeWorld'
    local layout = params.Layout
    local originOffset = params.OriginOffset or Vector3.zero
    local roomApothem = math.max(8, params.RoomApothem or ROOM_APOTHEM_DEFAULT)
    local includeRoomMarker = params.IncludeRoomMarker ~= false
    local parent = params.Parent or Workspace
    local detectionBuffer = params.DetectionBuffer or ROOM_DETECTION_BUFFER

    local existing = parent:FindFirstChild(worldName)
    if existing then
        existing:Destroy()
    end

    local worldFolder = Instance.new('Folder')
    worldFolder.Name = worldName
    worldFolder.Parent = parent

    local roomCenters = {}
    local roomById = {}
    local roomIds = {}
    local roomFolders = {}
    local doorways = {}

    for roomId in pairs(layout.Rooms) do
        table.insert(roomIds, roomId)
    end
    table.sort(roomIds)

    for _, roomId in ipairs(roomIds) do
        local room = layout.Rooms[roomId]
        local roomCenter = room.Position + originOffset
        roomCenters[roomId] = roomCenter
        roomById[roomId] = room

        roomFolders[roomId] = buildRoom(worldFolder, room, roomCenter, roomApothem, {
            IncludeRoomMarker = includeRoomMarker,
            RoomMarkerTransparency = params.RoomMarkerTransparency,
            RoomKindColors = params.RoomKindColors,
            ModuleAssetsRoot = params.ModuleAssetsRoot,
        })
        buildExitCorridors(worldFolder, room, roomCenter, roomApothem)
    end

    for doorwayId, doorwayLayout in pairs(layout.Doorways) do
        local roomCenter = roomCenters[doorwayLayout.RoomA]
        if not roomCenter then
            continue
        end

        local doorway = createDoorwayInstance(
            worldFolder,
            doorwayId,
            roomCenter,
            doorwayLayout.DirectionFromA,
            roomApothem,
            doorwayLayout.HasDoorLeaves
        )
        doorway.RoomA = doorwayLayout.RoomA
        doorway.RoomB = doorwayLayout.RoomB
        doorway.DirectionFromA = doorwayLayout.DirectionFromA
        doorway.DirectionFromB = doorwayLayout.DirectionFromB
        doorways[doorwayId] = doorway
    end

    local detectionRadius = roomApothem + detectionBuffer

    local function findRoomByPosition(position)
        local nearestRoom = nil
        local nearestDistance = math.huge
        local flatPosition = Vector3.new(position.X, 0, position.Z)

        for _, roomId in ipairs(roomIds) do
            local room = roomById[roomId]
            local roomCenter = roomCenters[roomId]
            local flatCenter = Vector3.new(roomCenter.X, 0, roomCenter.Z)
            local distance = (flatCenter - flatPosition).Magnitude
            if distance < nearestDistance then
                nearestDistance = distance
                nearestRoom = room
            end
        end

        if nearestDistance <= detectionRadius then
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

        if fromRoom.Id == toRoom.Id then
            return true
        end

        local doorwayId = edgeKey(fromRoom.Id, toRoom.Id)
        local doorway = doorways[doorwayId]
        if not doorway then
            return false
        end
        if doorway and doorway.HasDoorLeaves and not doorway.IsOpen then
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
        Doorways = doorways,
        ToggleDoor = toggleDoor,
        FindRoomByPosition = findRoomByPosition,
        CanTraverseBetweenPositions = canTraverseBetweenPositions,
    }
end

return HexMazeWorldRenderer
