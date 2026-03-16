local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Workspace = game:GetService('Workspace')

local Packages = ReplicatedStorage:WaitForChild('Packages')
local Gameplay = require(Packages:WaitForChild('Gameplay'))

local Items = Gameplay.Config.Items
local MazeBuilder = Gameplay.ProcGen.MazeBuilder

local MazeWorldBuilder = {}

local ROOM_CLEAR_HEIGHT = 14
local ROOM_APOTHEM_DEFAULT = 20
local SLAB_THICKNESS = 1
local WALL_HEIGHT = ROOM_CLEAR_HEIGHT
local WALL_THICKNESS = 2
local DOORWAY_WIDTH = 6
local DOORWAY_HEIGHT = 10
local DOOR_LEAF_THICKNESS = 0.5
local DOOR_CLEARANCE = 0
local ROOM_DETECTION_BUFFER = 18
local HEX_CIRCUMRADIUS_MULTIPLIER = 1 / math.cos(math.pi / 6)
local SIDE_ANGLE_OFFSET_DEGREES = 30

local WALL_MATERIAL = Enum.Material.Concrete
local WALL_COLOR = Color3.fromRGB(116, 114, 110)
local FLOOR_MATERIAL = Enum.Material.Concrete
local FLOOR_COLOR = Color3.fromRGB(98, 96, 92)
local CEILING_COLOR = Color3.fromRGB(88, 86, 82)
local DOOR_MATERIAL = Enum.Material.Concrete
local DOOR_COLOR = Color3.fromRGB(74, 72, 68)

local ROOM_KIND_COLORS = {
    Camp = Color3.fromRGB(83, 126, 78),
    Loot = Color3.fromRGB(88, 92, 112),
    Extraction = Color3.fromRGB(145, 119, 73),
}

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

local function edgeKey(roomIdA, roomIdB)
    if roomIdA < roomIdB then
        return string.format('%s|%s', roomIdA, roomIdB)
    end

    return string.format('%s|%s', roomIdB, roomIdA)
end

local function sideVectors(directionIndex)
    local angle = math.rad(((directionIndex - 1) * 60) + SIDE_ANGLE_OFFSET_DEGREES)
    local normal = Vector3.new(math.cos(angle), 0, math.sin(angle))
    local tangent = Vector3.new(-normal.Z, 0, normal.X)
    return normal, tangent
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

local function buildRoom(parent, room, roomCenter, roomRadius)
    local roomFolder = Instance.new('Folder')
    roomFolder.Name = room.Id
    roomFolder.Parent = parent

    local floorDiameter = roomRadius * HEX_CIRCUMRADIUS_MULTIPLIER * 2
    createPart({
        Name = 'Floor',
        Size = Vector3.new(floorDiameter, SLAB_THICKNESS, floorDiameter),
        CFrame = CFrame.new(roomCenter + Vector3.new(0, -(SLAB_THICKNESS / 2), 0)),
        Color = FLOOR_COLOR,
        Material = FLOOR_MATERIAL,
    }, roomFolder)

    createPart({
        Name = 'Ceiling',
        Size = Vector3.new(floorDiameter, SLAB_THICKNESS, floorDiameter),
        CFrame = CFrame.new(
            roomCenter + Vector3.new(0, ROOM_CLEAR_HEIGHT + (SLAB_THICKNESS / 2), 0)
        ),
        Color = CEILING_COLOR,
        Material = FLOOR_MATERIAL,
    }, roomFolder)

    createPart({
        Name = 'RoomMarker',
        Size = Vector3.new(floorDiameter - 4, 0.5, floorDiameter - 4),
        CFrame = CFrame.new(roomCenter + Vector3.new(0, 0.25, 0)),
        Color = ROOM_KIND_COLORS[room.Kind] or Color3.fromRGB(112, 112, 112),
        Material = Enum.Material.SmoothPlastic,
        Transparency = 0.5,
        CanCollide = false,
    }, roomFolder)

    local sideLength = 2 * roomRadius * math.tan(math.pi / 6)
    for directionIndex = 1, 6 do
        local hasDoorway = room.Neighbors[directionIndex] ~= nil
        createHexSideWall(
            roomFolder,
            roomCenter,
            directionIndex,
            roomRadius,
            sideLength,
            hasDoorway
        )
    end
end

function MazeWorldBuilder.build(seed, config, options)
    local existing = Workspace:FindFirstChild('GeneratedMazeWorld')
    if existing then
        existing:Destroy()
    end

    local layout = MazeBuilder.build(seed, config)
    local originOffset = (options and options.OriginOffset) or Vector3.zero
    local roomRadius = math.max(8, config.RoomApothem or ROOM_APOTHEM_DEFAULT)
    local roomCenters = {}
    local roomIds = {}
    local roomById = {}
    local doorways = {}
    local patrolPoints = {}
    local lootPrompts = {}

    local worldFolder = Instance.new('Folder')
    worldFolder.Name = 'GeneratedMazeWorld'
    worldFolder.Parent = Workspace

    for roomId in pairs(layout.Rooms) do
        table.insert(roomIds, roomId)
    end
    table.sort(roomIds)

    local itemIndex = 1
    for _, roomId in ipairs(roomIds) do
        local room = layout.Rooms[roomId]
        local roomCenter = room.Position + originOffset
        roomCenters[roomId] = roomCenter
        roomById[roomId] = room

        buildRoom(worldFolder, room, roomCenter, roomRadius)

        if room.Kind == 'Loot' then
            local itemDef = Items[itemIndex]
            itemIndex = (itemIndex % #Items) + 1

            local _, prompt = createPromptPart({
                Name = string.format('Loot_%s', roomId),
                Size = Vector3.new(3, 3, 3),
                CFrame = CFrame.new(roomCenter + Vector3.new(0, 1.5, 0)),
                Color = itemDef.Color,
                Material = Enum.Material.Neon,
                ActionText = 'Collect',
                ObjectText = itemDef.Name,
                CanCollide = false,
            }, worldFolder)

            lootPrompts[roomId] = {
                ItemDef = itemDef,
                Prompt = prompt,
                Position = roomCenter,
                Collected = false,
            }
            table.insert(patrolPoints, roomCenter)
        end
    end

    for doorwayId, doorwayLayout in pairs(layout.Doorways) do
        local roomA = roomById[doorwayLayout.RoomA]
        if not roomA then
            continue
        end

        local roomCenter = roomCenters[doorwayLayout.RoomA]
        local doorway = createDoorwayInstance(
            worldFolder,
            doorwayId,
            roomCenter,
            doorwayLayout.DirectionFromA,
            roomRadius,
            doorwayLayout.HasDoorLeaves
        )
        doorway.RoomA = doorwayLayout.RoomA
        doorway.RoomB = doorwayLayout.RoomB
        doorway.DirectionFromA = doorwayLayout.DirectionFromA
        doorway.DirectionFromB = doorwayLayout.DirectionFromB
        doorways[doorwayId] = doorway
    end

    local campCenter = roomCenters[layout.CampRoomId]
    local extractionCenter = roomCenters[layout.ExtractionRoomId]

    local _, deployPrompt = createPromptPart({
        Name = 'DeployConsole',
        Size = Vector3.new(4, 4, 4),
        CFrame = CFrame.new(campCenter + Vector3.new(-6, 2, 0)),
        Color = Color3.fromRGB(93, 196, 176),
        Material = Enum.Material.Metal,
        ActionText = 'Deploy',
        ObjectText = 'Expedition Console',
    }, worldFolder)

    createPart({
        Name = 'ReturnHoldPad',
        Size = Vector3.new(8, 1, 8),
        CFrame = CFrame.new(campCenter + Vector3.new(0, 0.5, -10)),
        Color = Color3.fromRGB(77, 147, 196),
        Material = Enum.Material.Neon,
        Transparency = 0.2,
        CanCollide = false,
    }, worldFolder)

    local _, returnPrompt = createPromptPart({
        Name = 'ReturnMarker',
        Size = Vector3.new(4, 1, 4),
        CFrame = CFrame.new(campCenter + Vector3.new(6, 0.5, 0)),
        Color = Color3.fromRGB(77, 147, 196),
        Material = Enum.Material.Neon,
        ActionText = 'Return',
        ObjectText = 'Return To Camp',
        CanCollide = false,
    }, worldFolder)

    local _, extractionPrompt = createPromptPart({
        Name = 'ExtractionPad',
        Size = Vector3.new(6, 1, 6),
        CFrame = CFrame.new(extractionCenter + Vector3.new(0, 0.5, 0)),
        Color = Color3.fromRGB(214, 170, 94),
        Material = Enum.Material.Neon,
        ActionText = 'Extract',
        ObjectText = 'Settlement Pad',
        CanCollide = false,
        MaxActivationDistance = 12,
    }, worldFolder)

    local detectionRadius = roomRadius + ROOM_DETECTION_BUFFER
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
            return nearestRoom
        end

        return nil
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

        local connectionDirection = nil
        for directionIndex, neighborRoomId in pairs(fromRoom.Neighbors) do
            if neighborRoomId == toRoom.Id then
                connectionDirection = directionIndex
                break
            end
        end

        if connectionDirection == nil then
            return false
        end

        local doorwayId = edgeKey(fromRoom.Id, toRoom.Id)
        local doorway = doorways[doorwayId]
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
        SpawnCFrame = CFrame.new(campCenter + Vector3.new(0, 4, 0)),
        ReturnHoldCFrame = CFrame.new(campCenter + Vector3.new(0, 4, -10)),
        DeployPrompt = deployPrompt,
        ReturnPrompt = returnPrompt,
        ExtractionPrompt = extractionPrompt,
        LootPrompts = lootPrompts,
        PatrolPoints = patrolPoints,
        Doorways = doorways,
        ToggleDoor = toggleDoor,
        FindRoomByPosition = findRoomByPosition,
        CanTraverseBetweenPositions = canTraverseBetweenPositions,
    }
end

return MazeWorldBuilder
