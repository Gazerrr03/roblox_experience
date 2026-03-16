local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Packages = ReplicatedStorage:WaitForChild('Packages')
local SharedPackage = Packages:WaitForChild('Shared')
local Gameplay = require(Packages:WaitForChild('Gameplay'))

local Items = Gameplay.Config.Items
local MazeBuilder = Gameplay.ProcGen.MazeBuilder
local HexMazeWorldRenderer =
    require(SharedPackage:WaitForChild('Runtime'):WaitForChild('HexMazeWorldRenderer'))

local MazeWorldBuilder = {}

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

function MazeWorldBuilder.build(seed, config, options)
    local layout = MazeBuilder.build(seed, config)
    local originOffset = (options and options.OriginOffset) or Vector3.zero

    local rendered = HexMazeWorldRenderer.build({
        WorldName = 'GeneratedMazeWorld',
        Layout = layout,
        OriginOffset = originOffset,
        RoomApothem = config.RoomApothem,
        IncludeRoomMarker = true,
        RoomMarkerTransparency = 0.5,
    })

    local worldFolder = rendered.Root
    local roomCenters = rendered.RoomCenters
    local patrolPoints = {}
    local lootPrompts = {}

    local itemIndex = 1
    for _, roomId in ipairs(rendered.RoomIds) do
        local room = rendered.RoomById[roomId]
        local roomCenter = roomCenters[roomId]

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
        Doorways = rendered.Doorways,
        ToggleDoor = rendered.ToggleDoor,
        FindRoomByPosition = rendered.FindRoomByPosition,
        CanTraverseBetweenPositions = rendered.CanTraverseBetweenPositions,
    }
end

return MazeWorldBuilder
