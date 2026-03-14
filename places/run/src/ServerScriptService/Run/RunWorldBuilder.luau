local Workspace = game:GetService('Workspace')

local RunWorldBuilder = {}

local function createFloor(name, position, size, color, parent)
    local part = Instance.new('Part')
    part.Name = name
    part.Anchored = true
    part.Size = size
    part.Position = position
    part.Material = Enum.Material.Slate
    part.Color = color
    part.Parent = parent
    return part
end

local function createPromptPart(name, position, color, actionText, objectText, parent)
    local part = Instance.new('Part')
    part.Name = name
    part.Anchored = true
    part.Size = Vector3.new(8, 3, 8)
    part.Position = position
    part.Material = Enum.Material.Metal
    part.Color = color
    part.Parent = parent

    local prompt = Instance.new('ProximityPrompt')
    prompt.ActionText = actionText
    prompt.ObjectText = objectText
    prompt.HoldDuration = 0
    prompt.MaxActivationDistance = 10
    prompt.Parent = part

    return part, prompt
end

local function createRoomMarkers(roomCenter, roomSize, parent)
    local corners = {
        Vector3.new(roomSize.X / 2, roomSize.Y / 2, roomSize.Z / 2),
        Vector3.new(roomSize.X / 2, roomSize.Y / 2, -roomSize.Z / 2),
        Vector3.new(-roomSize.X / 2, roomSize.Y / 2, roomSize.Z / 2),
        Vector3.new(-roomSize.X / 2, roomSize.Y / 2, -roomSize.Z / 2),
    }

    for index, offset in ipairs(corners) do
        local marker = Instance.new('Part')
        marker.Name = string.format('Marker_%d', index)
        marker.Anchored = true
        marker.Material = Enum.Material.Basalt
        marker.Color = Color3.fromRGB(49, 56, 66)
        marker.Size = Vector3.new(2, roomSize.Y, 2)
        marker.Position = roomCenter + offset
        marker.Parent = parent
    end
end

function RunWorldBuilder.build(layout, itemDefinitions, procGenConfig)
    local existing = Workspace:FindFirstChild('GeneratedWorld')
    if existing then
        existing:Destroy()
    end

    local worldFolder = Instance.new('Folder')
    worldFolder.Name = 'GeneratedWorld'
    worldFolder.Parent = Workspace

    local roomSize = procGenConfig.RoomSize
    local campRoom = layout.Rooms[layout.CampRoomId]
    local extractionRoom = layout.Rooms[layout.ExtractionRoomId]

    local _campFloor = createFloor(
        'CampFloor',
        campRoom.Position + Vector3.new(0, -0.5, 0),
        Vector3.new(roomSize.X + 16, 1, roomSize.Z + 16),
        Color3.fromRGB(50, 91, 75),
        worldFolder
    )

    local _campConsole, campPrompt = createPromptPart(
        'CampConsole',
        campRoom.Position + Vector3.new(0, 2, -10),
        Color3.fromRGB(93, 196, 176),
        'Deploy',
        'Camp Console',
        worldFolder
    )

    local _extractionPad, extractionPrompt = createPromptPart(
        'ExtractionPad',
        extractionRoom.Position + Vector3.new(0, 2, 0),
        Color3.fromRGB(233, 176, 67),
        'Deposit Loot',
        'Extraction Lift',
        worldFolder
    )

    local patrolPoints = {}
    local itemEntries = {}
    local random = Random.new(layout.Seed)

    for _, room in pairs(layout.Rooms) do
        local roomFolder = Instance.new('Folder')
        roomFolder.Name = room.Id
        roomFolder.Parent = worldFolder

        local color = room.Kind == 'Extraction' and Color3.fromRGB(84, 117, 158)
            or room.Kind == 'Camp' and Color3.fromRGB(50, 91, 75)
            or Color3.fromRGB(68, 73, 84)

        createFloor(
            room.Id .. '_Floor',
            room.Position + Vector3.new(0, -0.5, 0),
            roomSize,
            color,
            roomFolder
        )
        createRoomMarkers(room.Position, roomSize, roomFolder)
        table.insert(patrolPoints, room.Position)

        if room.Kind == 'Loot' then
            local itemCount = random:NextInteger(1, 2)

            for index = 1, itemCount do
                local itemDef = itemDefinitions[random:NextInteger(1, #itemDefinitions)]
                local itemPart = Instance.new('Part')
                itemPart.Name = string.format('%s_%d', itemDef.Id, index)
                itemPart.Anchored = true
                itemPart.CanCollide = false
                itemPart.Material = Enum.Material.SmoothPlastic
                itemPart.Color = itemDef.Color
                itemPart.Size = Vector3.new(2.4, 2.4, 2.4)
                itemPart.Position = room.Position
                    + Vector3.new(random:NextNumber(-9, 9), 1.5, random:NextNumber(-9, 9))
                itemPart.Parent = roomFolder

                local prompt = Instance.new('ProximityPrompt')
                prompt.ActionText = 'Pick Up'
                prompt.ObjectText = itemDef.Name
                prompt.HoldDuration = 0
                prompt.Parent = itemPart

                table.insert(itemEntries, {
                    Prompt = prompt,
                    ItemDef = itemDef,
                    Part = itemPart,
                })
            end
        end
    end

    return {
        Root = worldFolder,
        CampPrompt = campPrompt,
        ExtractionPrompt = extractionPrompt,
        ItemEntries = itemEntries,
        PatrolPoints = patrolPoints,
        SpawnCFrame = CFrame.new(campRoom.Position + Vector3.new(0, 5, 8)),
        CampCenter = campRoom.Position,
    }
end

return RunWorldBuilder
