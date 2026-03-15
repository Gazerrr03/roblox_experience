local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Workspace = game:GetService('Workspace')

local Packages = ReplicatedStorage:WaitForChild('Packages')
local Gameplay = require(Packages:WaitForChild('Gameplay'))

local Items = Gameplay.Config.Items
local MazeBuilder = Gameplay.ProcGen.MazeBuilder

local MazeWorldBuilder = {}

local WALL_HEIGHT = 16
local WALL_THICKNESS = 2
local DOOR_GAP = 10
local MARKER_HEIGHT = 1

local DIRECTIONS = {
    North = Vector3.new(0, 0, -1),
    South = Vector3.new(0, 0, 1),
    East = Vector3.new(1, 0, 0),
    West = Vector3.new(-1, 0, 0),
}

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

local function buildPositionIndex(layout)
    local index = {}

    for roomId, room in pairs(layout.Rooms) do
        index[string.format('%d:%d:%d', room.Position.X, room.Position.Y, room.Position.Z)] = roomId
    end

    return index
end

local function wallHasOpening(positionIndex, room, roomSpacing, directionName)
    local direction = DIRECTIONS[directionName]
    local neighborPosition = room.Position + (direction * roomSpacing)
    local key =
        string.format('%d:%d:%d', neighborPosition.X, neighborPosition.Y, neighborPosition.Z)

    return positionIndex[key] ~= nil
end

local function createNorthSouthWall(parent, room, roomSize, isNorth, hasOpening)
    local zOffset = (roomSize.Z / 2) * (isNorth and -1 or 1)
    local center = room.Position + Vector3.new(0, WALL_HEIGHT / 2, zOffset)

    if not hasOpening then
        createPart({
            Name = isNorth and 'NorthWall' or 'SouthWall',
            Size = Vector3.new(roomSize.X, WALL_HEIGHT, WALL_THICKNESS),
            CFrame = CFrame.new(center),
            Color = Color3.fromRGB(83, 69, 56),
            Material = Enum.Material.WoodPlanks,
        }, parent)
        return
    end

    local segmentWidth = (roomSize.X - DOOR_GAP) / 2
    local xOffset = (DOOR_GAP / 2) + (segmentWidth / 2)

    for _, direction in ipairs({ -1, 1 }) do
        createPart({
            Name = isNorth and 'NorthWallSegment' or 'SouthWallSegment',
            Size = Vector3.new(segmentWidth, WALL_HEIGHT, WALL_THICKNESS),
            CFrame = CFrame.new(center + Vector3.new(xOffset * direction, 0, 0)),
            Color = Color3.fromRGB(83, 69, 56),
            Material = Enum.Material.WoodPlanks,
        }, parent)
    end
end

local function createEastWestWall(parent, room, roomSize, isEast, hasOpening)
    local xOffset = (roomSize.X / 2) * (isEast and 1 or -1)
    local center = room.Position + Vector3.new(xOffset, WALL_HEIGHT / 2, 0)

    if not hasOpening then
        createPart({
            Name = isEast and 'EastWall' or 'WestWall',
            Size = Vector3.new(WALL_THICKNESS, WALL_HEIGHT, roomSize.Z),
            CFrame = CFrame.new(center),
            Color = Color3.fromRGB(83, 69, 56),
            Material = Enum.Material.WoodPlanks,
        }, parent)
        return
    end

    local segmentDepth = (roomSize.Z - DOOR_GAP) / 2
    local zOffset = (DOOR_GAP / 2) + (segmentDepth / 2)

    for _, direction in ipairs({ -1, 1 }) do
        createPart({
            Name = isEast and 'EastWallSegment' or 'WestWallSegment',
            Size = Vector3.new(WALL_THICKNESS, WALL_HEIGHT, segmentDepth),
            CFrame = CFrame.new(center + Vector3.new(0, 0, zOffset * direction)),
            Color = Color3.fromRGB(83, 69, 56),
            Material = Enum.Material.WoodPlanks,
        }, parent)
    end
end

local function createRoomMarker(parent, room, roomSize)
    createPart({
        Name = 'RoomMarker',
        Size = Vector3.new(roomSize.X - 4, MARKER_HEIGHT, roomSize.Z - 4),
        CFrame = CFrame.new(room.Position + Vector3.new(0, MARKER_HEIGHT / 2, 0)),
        Color = ROOM_KIND_COLORS[room.Kind] or Color3.fromRGB(112, 112, 112),
        Material = Enum.Material.SmoothPlastic,
        Transparency = 0.35,
        CanCollide = false,
    }, parent)
end

local function buildRoom(parent, room, roomSize, positionIndex, roomSpacing)
    local roomFolder = Instance.new('Folder')
    roomFolder.Name = room.Id
    roomFolder.Parent = parent

    createPart({
        Name = 'Floor',
        Size = Vector3.new(roomSize.X, 1, roomSize.Z),
        CFrame = CFrame.new(room.Position + Vector3.new(0, -0.5, 0)),
        Color = Color3.fromRGB(61, 72, 81),
        Material = Enum.Material.Slate,
    }, roomFolder)

    createPart({
        Name = 'Ceiling',
        Size = Vector3.new(roomSize.X, 1, roomSize.Z),
        CFrame = CFrame.new(room.Position + Vector3.new(0, WALL_HEIGHT + 0.5, 0)),
        Color = Color3.fromRGB(52, 44, 38),
        Material = Enum.Material.WoodPlanks,
    }, roomFolder)

    createNorthSouthWall(
        roomFolder,
        room,
        roomSize,
        true,
        wallHasOpening(positionIndex, room, roomSpacing, 'North')
    )
    createNorthSouthWall(
        roomFolder,
        room,
        roomSize,
        false,
        wallHasOpening(positionIndex, room, roomSpacing, 'South')
    )
    createEastWestWall(
        roomFolder,
        room,
        roomSize,
        true,
        wallHasOpening(positionIndex, room, roomSpacing, 'East')
    )
    createEastWestWall(
        roomFolder,
        room,
        roomSize,
        false,
        wallHasOpening(positionIndex, room, roomSpacing, 'West')
    )

    createRoomMarker(roomFolder, room, roomSize)

    return roomFolder
end

function MazeWorldBuilder.build(seed, config)
    local existing = Workspace:FindFirstChild('GeneratedMazeWorld')
    if existing then
        existing:Destroy()
    end

    local layout = MazeBuilder.build(seed, config)
    local roomSize = config.RoomSize or Vector3.new(28, 16, 28)
    local roomSpacing = config.RoomSpacing or 40
    local positionIndex = buildPositionIndex(layout)

    local worldFolder = Instance.new('Folder')
    worldFolder.Name = 'GeneratedMazeWorld'
    worldFolder.Parent = Workspace

    local campRoom = layout.Rooms[layout.CampRoomId]
    local extractionRoom = layout.Rooms[layout.ExtractionRoomId]
    local patrolPoints = {}
    local lootPrompts = {}
    local roomOrder = {}

    for roomId in pairs(layout.Rooms) do
        table.insert(roomOrder, roomId)
    end
    table.sort(roomOrder)

    local itemIndex = 1
    for _, roomId in ipairs(roomOrder) do
        local room = layout.Rooms[roomId]
        local roomFolder = buildRoom(worldFolder, room, roomSize, positionIndex, roomSpacing)

        if room.Kind == 'Loot' then
            local itemDef = Items[itemIndex]
            itemIndex = (itemIndex % #Items) + 1
            local _, prompt = createPromptPart({
                Name = string.format('Loot_%s', roomId),
                Size = Vector3.new(3, 3, 3),
                CFrame = CFrame.new(room.Position + Vector3.new(0, 1.5, 0)),
                Color = itemDef.Color,
                Material = Enum.Material.Neon,
                ActionText = 'Collect',
                ObjectText = itemDef.Name,
                CanCollide = false,
            }, roomFolder)

            lootPrompts[roomId] = {
                ItemDef = itemDef,
                Prompt = prompt,
                Position = room.Position,
            }
            table.insert(patrolPoints, room.Position)
        end
    end

    local _, deployPrompt = createPromptPart({
        Name = 'DeployConsole',
        Size = Vector3.new(4, 4, 4),
        CFrame = CFrame.new(campRoom.Position + Vector3.new(-6, 2, 0)),
        Color = Color3.fromRGB(93, 196, 176),
        Material = Enum.Material.Metal,
        ActionText = 'Deploy',
        ObjectText = 'Expedition Console',
    }, worldFolder)

    local _, returnPrompt = createPromptPart({
        Name = 'ReturnMarker',
        Size = Vector3.new(4, 1, 4),
        CFrame = CFrame.new(campRoom.Position + Vector3.new(6, 0.5, 0)),
        Color = Color3.fromRGB(77, 147, 196),
        Material = Enum.Material.Neon,
        ActionText = 'Return',
        ObjectText = 'Camp Return',
        CanCollide = false,
    }, worldFolder)

    local _, extractionPrompt = createPromptPart({
        Name = 'ExtractionPad',
        Size = Vector3.new(6, 1, 6),
        CFrame = CFrame.new(extractionRoom.Position + Vector3.new(0, 0.5, 0)),
        Color = Color3.fromRGB(214, 170, 94),
        Material = Enum.Material.Neon,
        ActionText = 'Extract',
        ObjectText = 'Settlement Pad',
        CanCollide = false,
        MaxActivationDistance = 12,
    }, worldFolder)

    return {
        Root = worldFolder,
        Layout = layout,
        SpawnCFrame = CFrame.new(campRoom.Position + Vector3.new(0, 4, 0)),
        CampRoomId = layout.CampRoomId,
        ExtractionRoomId = layout.ExtractionRoomId,
        DeployPrompt = deployPrompt,
        ReturnPrompt = returnPrompt,
        ExtractionPrompt = extractionPrompt,
        LootPrompts = lootPrompts,
        PatrolPoints = patrolPoints,
        FindRoomByPosition = function(position)
            local nearestRoom = nil
            local nearestDistance = math.huge

            for _, room in pairs(layout.Rooms) do
                local distance = (room.Position - position).Magnitude
                if distance < nearestDistance then
                    nearestRoom = room
                    nearestDistance = distance
                end
            end

            return nearestRoom
        end,
    }
end

return MazeWorldBuilder
