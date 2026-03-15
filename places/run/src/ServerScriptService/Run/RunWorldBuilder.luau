local Workspace = game:GetService('Workspace')

local RunWorldBuilder = {}

local HOUSE_WIDTH = 44
local HOUSE_DEPTH = 30
local HOUSE_HEIGHT = 18
local WALL_THICKNESS = 2
local DOOR_GAP = 12
local OUTDOOR_THRESHOLD_Z = 20

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
    }, parent)

    local prompt = Instance.new('ProximityPrompt')
    prompt.ActionText = config.ActionText
    prompt.ObjectText = config.ObjectText
    prompt.HoldDuration = 0
    prompt.MaxActivationDistance = config.MaxActivationDistance or 10
    prompt.Parent = part

    return part, prompt
end

local function createTree(position, parent)
    createPart({
        Name = 'TreeTrunk',
        Size = Vector3.new(2.5, 16, 2.5),
        CFrame = CFrame.new(position + Vector3.new(0, 8, 0)),
        Color = Color3.fromRGB(96, 70, 48),
        Material = Enum.Material.Wood,
    }, parent)

    createPart({
        Name = 'TreeCanopy',
        Size = Vector3.new(10, 10, 10),
        CFrame = CFrame.new(position + Vector3.new(0, 18, 0)),
        Color = Color3.fromRGB(67, 112, 65),
        Material = Enum.Material.Grass,
        Shape = Enum.PartType.Ball,
    }, parent)
end

local function createRock(position, size, parent)
    createPart({
        Name = 'Rock',
        Size = size,
        CFrame = CFrame.new(position),
        Color = Color3.fromRGB(100, 104, 112),
        Material = Enum.Material.Slate,
        Shape = Enum.PartType.Ball,
    }, parent)
end

local function createCampHouse(worldFolder)
    local houseFolder = Instance.new('Folder')
    houseFolder.Name = 'CampHouse'
    houseFolder.Parent = worldFolder

    createPart({
        Name = 'CampFloor',
        Size = Vector3.new(HOUSE_WIDTH, 1, HOUSE_DEPTH),
        CFrame = CFrame.new(0, -0.5, 0),
        Color = Color3.fromRGB(86, 73, 61),
        Material = Enum.Material.WoodPlanks,
    }, houseFolder)

    createPart({
        Name = 'Foundation',
        Size = Vector3.new(HOUSE_WIDTH + 8, 2, HOUSE_DEPTH + 8),
        CFrame = CFrame.new(0, -1.5, 0),
        Color = Color3.fromRGB(63, 67, 74),
        Material = Enum.Material.Slate,
    }, houseFolder)

    createPart({
        Name = 'BackWall',
        Size = Vector3.new(HOUSE_WIDTH, HOUSE_HEIGHT, WALL_THICKNESS),
        CFrame = CFrame.new(0, HOUSE_HEIGHT / 2, -(HOUSE_DEPTH / 2)),
        Color = Color3.fromRGB(122, 103, 84),
        Material = Enum.Material.WoodPlanks,
    }, houseFolder)

    createPart({
        Name = 'LeftWall',
        Size = Vector3.new(WALL_THICKNESS, HOUSE_HEIGHT, HOUSE_DEPTH),
        CFrame = CFrame.new(-(HOUSE_WIDTH / 2), HOUSE_HEIGHT / 2, 0),
        Color = Color3.fromRGB(122, 103, 84),
        Material = Enum.Material.WoodPlanks,
    }, houseFolder)

    createPart({
        Name = 'RightWall',
        Size = Vector3.new(WALL_THICKNESS, HOUSE_HEIGHT, HOUSE_DEPTH),
        CFrame = CFrame.new(HOUSE_WIDTH / 2, HOUSE_HEIGHT / 2, 0),
        Color = Color3.fromRGB(122, 103, 84),
        Material = Enum.Material.WoodPlanks,
    }, houseFolder)

    local frontWallWidth = (HOUSE_WIDTH - DOOR_GAP) / 2
    createPart({
        Name = 'FrontWallLeft',
        Size = Vector3.new(frontWallWidth, HOUSE_HEIGHT, WALL_THICKNESS),
        CFrame = CFrame.new(
            -((DOOR_GAP / 2) + (frontWallWidth / 2)),
            HOUSE_HEIGHT / 2,
            HOUSE_DEPTH / 2
        ),
        Color = Color3.fromRGB(122, 103, 84),
        Material = Enum.Material.WoodPlanks,
    }, houseFolder)

    createPart({
        Name = 'FrontWallRight',
        Size = Vector3.new(frontWallWidth, HOUSE_HEIGHT, WALL_THICKNESS),
        CFrame = CFrame.new(
            (DOOR_GAP / 2) + (frontWallWidth / 2),
            HOUSE_HEIGHT / 2,
            HOUSE_DEPTH / 2
        ),
        Color = Color3.fromRGB(122, 103, 84),
        Material = Enum.Material.WoodPlanks,
    }, houseFolder)

    createPart({
        Name = 'Roof',
        Size = Vector3.new(HOUSE_WIDTH + 4, 2, HOUSE_DEPTH + 4),
        CFrame = CFrame.new(0, HOUSE_HEIGHT + 1, 0),
        Color = Color3.fromRGB(74, 52, 42),
        Material = Enum.Material.WoodPlanks,
    }, houseFolder)

    local doorLeft = createPart({
        Name = 'DoorLeft',
        Size = Vector3.new(DOOR_GAP / 2, HOUSE_HEIGHT - 2, 1.5),
        CFrame = CFrame.new(-(DOOR_GAP / 4), (HOUSE_HEIGHT - 2) / 2, HOUSE_DEPTH / 2),
        Color = Color3.fromRGB(91, 66, 45),
        Material = Enum.Material.Wood,
    }, houseFolder)

    local doorRight = createPart({
        Name = 'DoorRight',
        Size = Vector3.new(DOOR_GAP / 2, HOUSE_HEIGHT - 2, 1.5),
        CFrame = CFrame.new(DOOR_GAP / 4, (HOUSE_HEIGHT - 2) / 2, HOUSE_DEPTH / 2),
        Color = Color3.fromRGB(91, 66, 45),
        Material = Enum.Material.Wood,
    }, houseFolder)

    local _, gatePrompt = createPromptPart({
        Name = 'GateSwitch',
        Size = Vector3.new(3, 5, 3),
        CFrame = CFrame.new(0, 2.5, (HOUSE_DEPTH / 2) - 5),
        Color = Color3.fromRGB(93, 196, 176),
        Material = Enum.Material.Metal,
        ActionText = 'Open Gate',
        ObjectText = 'Camp Gate',
    }, houseFolder)

    local _, shopPrompt = createPromptPart({
        Name = 'ShopTerminal',
        Size = Vector3.new(4, 5, 4),
        CFrame = CFrame.new(-(HOUSE_WIDTH / 2) + 8, 2.5, -4),
        Color = Color3.fromRGB(77, 147, 196),
        Material = Enum.Material.Metal,
        ActionText = 'Inspect',
        ObjectText = 'Shop Terminal (Soon)',
    }, houseFolder)

    local _, loadoutPrompt = createPromptPart({
        Name = 'LoadoutBench',
        Size = Vector3.new(6, 3, 3),
        CFrame = CFrame.new((HOUSE_WIDTH / 2) - 9, 1.5, -2),
        Color = Color3.fromRGB(208, 176, 94),
        Material = Enum.Material.WoodPlanks,
        ActionText = 'Inspect',
        ObjectText = 'Loadout Bench (Soon)',
    }, houseFolder)

    createPart({
        Name = 'MeetingTable',
        Size = Vector3.new(10, 1, 5),
        CFrame = CFrame.new(0, 2.5, -4),
        Color = Color3.fromRGB(109, 84, 64),
        Material = Enum.Material.Wood,
    }, houseFolder)

    for _, offsetX in ipairs({ -8, 8 }) do
        createPart({
            Name = 'BenchSeat',
            Size = Vector3.new(8, 1, 2),
            CFrame = CFrame.new(offsetX, 1.5, 5),
            Color = Color3.fromRGB(104, 82, 63),
            Material = Enum.Material.Wood,
        }, houseFolder)
    end

    local function openGate()
        doorLeft.CFrame = CFrame.new(-(DOOR_GAP / 2) - 3, (HOUSE_HEIGHT - 2) / 2, HOUSE_DEPTH / 2)
        doorRight.CFrame = CFrame.new((DOOR_GAP / 2) + 3, (HOUSE_HEIGHT - 2) / 2, HOUSE_DEPTH / 2)
        gatePrompt.ActionText = 'Gate Open'
        doorLeft.CanCollide = false
        doorRight.CanCollide = false
    end

    return {
        ShopPrompt = shopPrompt,
        LoadoutPrompt = loadoutPrompt,
        GatePrompt = gatePrompt,
        OpenGate = openGate,
    }
end

local function createOutdoorArea(worldFolder)
    local outdoorFolder = Instance.new('Folder')
    outdoorFolder.Name = 'Wilderness'
    outdoorFolder.Parent = worldFolder

    createPart({
        Name = 'OutdoorGround',
        Size = Vector3.new(220, 2, 240),
        CFrame = CFrame.new(0, -1, 85),
        Color = Color3.fromRGB(83, 126, 78),
        Material = Enum.Material.Grass,
    }, outdoorFolder)

    createPart({
        Name = 'CampApproach',
        Size = Vector3.new(18, 1, 38),
        CFrame = CFrame.new(0, 0, 32),
        Color = Color3.fromRGB(122, 101, 75),
        Material = Enum.Material.Ground,
    }, outdoorFolder)

    createPart({
        Name = 'Trail',
        Size = Vector3.new(16, 1, 88),
        CFrame = CFrame.new(0, 0, 78),
        Color = Color3.fromRGB(114, 97, 69),
        Material = Enum.Material.Ground,
    }, outdoorFolder)

    for _, treePosition in ipairs({
        Vector3.new(-38, 0, 40),
        Vector3.new(38, 0, 48),
        Vector3.new(-52, 0, 78),
        Vector3.new(50, 0, 94),
        Vector3.new(-34, 0, 126),
        Vector3.new(44, 0, 132),
    }) do
        createTree(treePosition, outdoorFolder)
    end

    for _, rockConfig in ipairs({
        { Vector3.new(-22, 2, 58), Vector3.new(6, 4, 5) },
        { Vector3.new(28, 2, 74), Vector3.new(5, 4, 4) },
        { Vector3.new(-16, 3, 116), Vector3.new(8, 5, 6) },
    }) do
        createRock(rockConfig[1], rockConfig[2], outdoorFolder)
    end

    createPart({
        Name = 'CliffWall',
        Size = Vector3.new(120, 36, 8),
        CFrame = CFrame.new(0, 16, 156),
        Color = Color3.fromRGB(84, 89, 96),
        Material = Enum.Material.Slate,
    }, outdoorFolder)

    createPart({
        Name = 'MazeGateLeft',
        Size = Vector3.new(4, 18, 4),
        CFrame = CFrame.new(-8, 9, 132),
        Color = Color3.fromRGB(91, 95, 102),
        Material = Enum.Material.Slate,
    }, outdoorFolder)

    createPart({
        Name = 'MazeGateRight',
        Size = Vector3.new(4, 18, 4),
        CFrame = CFrame.new(8, 9, 132),
        Color = Color3.fromRGB(91, 95, 102),
        Material = Enum.Material.Slate,
    }, outdoorFolder)

    createPart({
        Name = 'MazeGateBeam',
        Size = Vector3.new(22, 4, 4),
        CFrame = CFrame.new(0, 18, 132),
        Color = Color3.fromRGB(91, 95, 102),
        Material = Enum.Material.Slate,
    }, outdoorFolder)

    local _, mazePrompt = createPromptPart({
        Name = 'MazeGateMarker',
        Size = Vector3.new(6, 1, 6),
        CFrame = CFrame.new(0, 0.5, 120),
        Color = Color3.fromRGB(154, 113, 214),
        Material = Enum.Material.Neon,
        ActionText = 'Inspect',
        ObjectText = 'Maze Run Gate (Soon)',
        MaxActivationDistance = 12,
    }, outdoorFolder)

    return {
        MazePrompt = mazePrompt,
    }
end

function RunWorldBuilder.build(_seed)
    local existing = Workspace:FindFirstChild('GeneratedWorld')
    if existing then
        existing:Destroy()
    end

    local worldFolder = Instance.new('Folder')
    worldFolder.Name = 'GeneratedWorld'
    worldFolder.Parent = Workspace

    local house = createCampHouse(worldFolder)
    local outdoors = createOutdoorArea(worldFolder)

    return {
        Root = worldFolder,
        SpawnCFrame = CFrame.new(0, 4, -6),
        OutdoorThresholdZ = OUTDOOR_THRESHOLD_Z,
        ShopPrompt = house.ShopPrompt,
        LoadoutPrompt = house.LoadoutPrompt,
        GatePrompt = house.GatePrompt,
        MazePrompt = outdoors.MazePrompt,
        OpenGate = house.OpenGate,
    }
end

return RunWorldBuilder
