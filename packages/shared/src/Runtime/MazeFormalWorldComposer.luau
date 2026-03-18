local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Packages = ReplicatedStorage:WaitForChild('Packages')
local Gameplay = require(Packages:WaitForChild('Gameplay'))

local Items = Gameplay.Config.Items
local MazeModuleAssetContract = require(script.Parent.MazeModuleAssetContract)
local MazeWorldShellBuilder = require(script.Parent.MazeWorldShellBuilder)

local MazeFormalWorldComposer = {}

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
    if config.Shape then
        part.Shape = config.Shape
    end
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

local function validateModuleAssetsIfConfigured(options)
    if options == nil then
        return nil
    end

    if options.ModuleAssetsRoot ~= nil then
        return MazeModuleAssetContract.validateRoot(options.ModuleAssetsRoot)
    end

    if options.RequireModuleAssets == true then
        error(
            'Formal maze world requested Studio module assets, but no asset root was supplied.',
            0
        )
    end

    return nil
end

function MazeFormalWorldComposer.build(seed, config, options)
    local resolvedOptions = options or {}
    validateModuleAssetsIfConfigured(resolvedOptions)

    local shell = MazeWorldShellBuilder.build(seed, config, {
        WorldName = resolvedOptions.WorldName or 'GeneratedMazeWorld',
        Parent = resolvedOptions.Parent,
        OriginOffset = resolvedOptions.OriginOffset or Vector3.zero,
        IncludeRoomMarkers = resolvedOptions.IncludeRoomMarkers ~= false,
        RoomMarkerTransparency = resolvedOptions.RoomMarkerTransparency or 0.5,
        RoomKindColors = resolvedOptions.RoomKindColors,
        DetectionBuffer = resolvedOptions.DetectionBuffer,
    })

    local patrolPoints = {}
    local lootNodes = {}
    local itemIndex = 1

    for _, roomId in ipairs(shell.RoomIds) do
        local room = shell.RoomById[roomId]
        local roomCenter = shell.RoomCenters[roomId]

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
            }, shell.Root)

            lootNodes[roomId] = {
                ItemDef = itemDef,
                Prompt = prompt,
                Position = roomCenter,
                Collected = false,
            }
            table.insert(patrolPoints, roomCenter)
        end
    end

    local returnHoldPad = createPart({
        Name = 'ReturnHoldPad',
        Size = Vector3.new(8, 1, 8),
        CFrame = CFrame.new(shell.CampCenter + Vector3.new(0, 0.5, -10)),
        Color = Color3.fromRGB(77, 147, 196),
        Material = Enum.Material.Neon,
        Transparency = 0.2,
        CanCollide = false,
    }, shell.Root)

    local extractionNodeId = 'PrimaryExtraction'
    local _, extractionPrompt = createPromptPart({
        Name = 'ExtractionMarker',
        Size = Vector3.new(6, 1, 6),
        CFrame = CFrame.new(shell.ExtractionCenter + Vector3.new(0, 0.5, 0)),
        Color = Color3.fromRGB(214, 170, 94),
        Material = Enum.Material.Neon,
        ActionText = 'Extract',
        ObjectText = resolvedOptions.ExtractionObjectText or 'Maze Exit',
        CanCollide = false,
        MaxActivationDistance = resolvedOptions.ExtractionMaxActivationDistance or 12,
    }, shell.Root)

    local extractionNodes = {
        [extractionNodeId] = {
            Id = extractionNodeId,
            Prompt = extractionPrompt,
            Position = shell.ExtractionCenter,
        },
    }

    shell.LootNodes = lootNodes
    shell.PatrolPoints = patrolPoints
    shell.ReturnHoldPad = returnHoldPad
    shell.ExtractionNodes = extractionNodes

    return shell
end

return MazeFormalWorldComposer
