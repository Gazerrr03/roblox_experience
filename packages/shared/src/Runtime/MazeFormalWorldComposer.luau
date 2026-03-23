local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Packages = ReplicatedStorage:WaitForChild('Packages')
local Gameplay = require(Packages:WaitForChild('Gameplay'))

local Items = Gameplay.Config.Items
local MazeMonsterSpawnPolicy = Gameplay.Monsters.MazeMonsterSpawnPolicy
local MazeInteractionPartFactory = require(script.Parent.MazeInteractionPartFactory)
local MazeModuleAssetContract = require(script.Parent.MazeModuleAssetContract)
local MazeWorldShellBuilder = require(script.Parent.MazeWorldShellBuilder)

local MazeFormalWorldComposer = {}
local LOOT_SOCKET_HEIGHT = 1.5

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

local function buildThreatTags(roomKind)
    return {
        string.format('RoomKind:%s', roomKind),
    }
end

local function cloneSortedNumbers(values)
    local cloned = table.clone(values or {})
    table.sort(cloned)
    return cloned
end

local function buildSortedNeighborRoomIds(room)
    local neighborRoomIds = {}
    for _, neighborRoomId in pairs(room.Neighbors or {}) do
        table.insert(neighborRoomIds, neighborRoomId)
    end
    table.sort(neighborRoomIds)
    return neighborRoomIds
end

local function buildRoomAffordance(shell, roomId)
    local room = shell.RoomById[roomId]
    local roomCenter = shell.RoomCenters[roomId]

    local affordance = {
        RoomId = roomId,
        RoomKind = room.Kind,
        RoomCenter = roomCenter,
        SpawnSockets = {
            {
                Id = string.format('%s_Spawn_1', roomId),
                Kind = 'RoomCenter',
                Position = roomCenter + Vector3.new(0, LOOT_SOCKET_HEIGHT, 0),
            },
        },
        PatrolAnchors = {},
        SightBreakers = {},
        DoorControlPoints = {},
        ThreatTags = buildThreatTags(room.Kind),
        TraversalMask = {
            NeighborRoomIds = buildSortedNeighborRoomIds(room),
            DoorwayIds = {},
            ExitDirections = cloneSortedNumbers(room.ExitDirections),
        },
    }

    if room.Kind == 'Loot' then
        table.insert(affordance.PatrolAnchors, roomCenter)
    end

    return affordance
end

local function appendDoorwayAffordances(roomAffordances, doorwayId, doorway)
    local roomIds = {
        doorway.RoomA,
        doorway.RoomB,
    }
    local neighborRoomIds = {
        [doorway.RoomA] = doorway.RoomB,
        [doorway.RoomB] = doorway.RoomA,
    }

    for _, roomId in ipairs(roomIds) do
        local affordance = roomAffordances[roomId]
        if affordance then
            table.insert(affordance.TraversalMask.DoorwayIds, doorwayId)

            if doorway.Prompt then
                table.insert(affordance.DoorControlPoints, {
                    DoorwayId = doorwayId,
                    NeighborRoomId = neighborRoomIds[roomId],
                    Position = doorway.Prompt.Parent.Position,
                })
            end
        end
    end
end

local function finalizeAffordances(roomAffordances)
    for _, affordance in pairs(roomAffordances) do
        table.sort(affordance.TraversalMask.DoorwayIds)
        table.sort(affordance.DoorControlPoints, function(left, right)
            return left.DoorwayId < right.DoorwayId
        end)
    end
end

local function collectPatrolPointsFromAffordances(roomIds, roomAffordances)
    local patrolPoints = {}

    for _, roomId in ipairs(roomIds) do
        local affordance = roomAffordances[roomId]
        if affordance then
            for _, patrolAnchor in ipairs(affordance.PatrolAnchors) do
                table.insert(patrolPoints, patrolAnchor)
            end
        end
    end

    return patrolPoints
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

    local roomAffordances = {}
    local lootNodes = {}
    local itemIndex = 1

    for _, roomId in ipairs(shell.RoomIds) do
        local affordance = buildRoomAffordance(shell, roomId)
        local room = shell.RoomById[roomId]
        local lootPosition = affordance.SpawnSockets[1].Position
        roomAffordances[roomId] = affordance

        if room.Kind == 'Loot' then
            local itemDef = Items[itemIndex]
            itemIndex = (itemIndex % #Items) + 1

            local _, prompt = MazeInteractionPartFactory.createPromptPart({
                Name = string.format('Loot_%s', roomId),
                Size = Vector3.new(3, 3, 3),
                CFrame = CFrame.new(lootPosition),
                Color = itemDef.Color,
                Material = Enum.Material.Neon,
                ActionText = 'Collect',
                ObjectText = itemDef.Name,
                CanCollide = false,
            }, shell.Root)

            lootNodes[roomId] = {
                ItemDef = itemDef,
                Prompt = prompt,
                Position = lootPosition,
                Collected = false,
            }
        end
    end

    local returnHoldPad = MazeInteractionPartFactory.createPart({
        Name = 'ReturnHoldPad',
        Size = Vector3.new(8, 1, 8),
        CFrame = CFrame.new(shell.CampCenter + Vector3.new(0, 0.5, -10)),
        Color = Color3.fromRGB(77, 147, 196),
        Material = Enum.Material.Neon,
        Transparency = 0.2,
        CanCollide = false,
    }, shell.Root)

    local extractionNodeId = 'PrimaryExtraction'
    local _, extractionPrompt = MazeInteractionPartFactory.createPromptPart({
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

    local doorwayIds = {}
    for doorwayId in pairs(shell.Doorways or {}) do
        table.insert(doorwayIds, doorwayId)
    end
    table.sort(doorwayIds)

    for _, doorwayId in ipairs(doorwayIds) do
        appendDoorwayAffordances(roomAffordances, doorwayId, shell.Doorways[doorwayId])
    end

    finalizeAffordances(roomAffordances)

    local initialMonsterPatrolIndex, initialMonsterSpawnRoomId =
        MazeMonsterSpawnPolicy.selectInitialPatrolIndex(
            shell.RoomIds,
            roomAffordances,
            shell.RoomById,
            shell.CampRoomId
        )

    shell.LootNodes = lootNodes
    shell.RoomAffordances = roomAffordances
    shell.PatrolPoints = collectPatrolPointsFromAffordances(shell.RoomIds, roomAffordances)
    shell.InitialMonsterPatrolIndex = initialMonsterPatrolIndex
        or (#shell.PatrolPoints > 0 and 1 or nil)
    shell.InitialMonsterSpawnRoomId = initialMonsterSpawnRoomId
    shell.ReturnHoldPad = returnHoldPad
    shell.ExtractionNodes = extractionNodes

    return shell
end

return MazeFormalWorldComposer
