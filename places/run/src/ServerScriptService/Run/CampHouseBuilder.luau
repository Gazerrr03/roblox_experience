local HOUSE_WIDTH = 44
local HOUSE_DEPTH = 30
local HOUSE_HEIGHT = 18
local WALL_THICKNESS = 2
local DOOR_GAP = 12

local CampHouseBuilder = {}

function CampHouseBuilder.build(worldFolder, createPart, createPromptPart)
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
        ObjectText = 'Temple Gate',
    }, houseFolder)

    local _, shopPrompt = createPromptPart({
        Name = 'ShopTerminal',
        Size = Vector3.new(4, 5, 4),
        CFrame = CFrame.new(-(HOUSE_WIDTH / 2) + 8, 2.5, -4),
        Color = Color3.fromRGB(77, 147, 196),
        Material = Enum.Material.Metal,
        ActionText = 'Inspect',
        ObjectText = 'Temple Shop (Soon)',
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

    local _, sellPrompt = createPromptPart({
        Name = 'SalvageTerminal',
        Size = Vector3.new(4, 5, 4),
        CFrame = CFrame.new((HOUSE_WIDTH / 2) - 9, 2.5, 6),
        Color = Color3.fromRGB(196, 121, 77),
        Material = Enum.Material.Metal,
        ActionText = 'Exchange',
        ObjectText = 'Salvage Exchange',
    }, houseFolder)

    local _, objectivePrompt = createPromptPart({
        Name = 'ObjectiveBoard',
        Size = Vector3.new(6, 4, 1.5),
        CFrame = CFrame.new(0, 5, -(HOUSE_DEPTH / 2) + 2),
        Color = Color3.fromRGB(67, 112, 65),
        Material = Enum.Material.WoodPlanks,
        ActionText = 'Review',
        ObjectText = 'Book of Sand Board',
        MaxActivationDistance = 12,
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
        SellPrompt = sellPrompt,
        ObjectivePrompt = objectivePrompt,
        LoadoutPrompt = loadoutPrompt,
        GatePrompt = gatePrompt,
        OpenGate = openGate,
    }
end

return CampHouseBuilder
