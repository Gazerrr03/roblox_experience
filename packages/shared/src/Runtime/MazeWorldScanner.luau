--[[
    MazeWorldScanner
    运行时扫描 Workspace 中的静态房间实例，建立供 MazeSessionService 使用的数据结构。

    Authoring guide:
    - `Workspace/MazeStaticWorld` is the authored root for the maze place.
    - Each room is a Model tagged `RoomType/<TypeId>`.
    - Supported room metadata lives on Attributes such as `IsCamp`, `IsExtraction`,
      `DifficultyTier`, `MonsterBudget`, `LootBudget`, `DetectionRadius`,
      `RoomTemplateId`, and `RoomCategory`.
    - Supported authored child parts include `SpawnPoint_*`, `LootSocket_*`,
      `LootPrompt`, `Doorway_*`, and `ExtractionMarker`.
]]

local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Workspace = game:GetService('Workspace')

local Packages = ReplicatedStorage:WaitForChild('Packages')
local Gameplay = require(Packages:WaitForChild('Gameplay'))

local MazeWorldScanner = {}
MazeWorldScanner.__index = MazeWorldScanner

local DEFAULT_SCAN_ROOT = Workspace
local STATIC_WORLD_ROOT_NAME = 'MazeStaticWorld'
local DEFAULT_ROOM_KIND = 'Loot'
local DEFAULT_RETURN_ACTION_TEXT = 'Return'
local DEFAULT_RETURN_OBJECT_TEXT = 'Run Entrance'

local SCAN_CONFIG = {
    RoomTagPrefix = 'RoomType/',
    HasMonsterSpawnerTag = 'HasMonsterSpawner',
    HasLootSocketTag = 'HasLootSocket',
    DoorwayTagPrefix = 'Doorway/',
    SceneryFolderName = 'Scenery',
    SceneryAttribute = 'IsScenery',
}

local DEFAULT_ATTRIBUTES = {
    RoomType = 'Unknown',
    DifficultyTier = 1,
    MonsterBudget = 0,
    LootBudget = 0,
    IsCamp = false,
    IsExtraction = false,
    IsScenery = false,
}

local function readAttribute(instance, name, default)
    local value = instance:GetAttribute(name)
    return value ~= nil and value or default
end

local function hasTag(instance, tag)
    if instance:HasTag(tag) then
        return true
    end

    return readAttribute(instance, tag, false) == true
end

local function sortByName(instances)
    table.sort(instances, function(left, right)
        return left.Name < right.Name
    end)
    return instances
end

local function isSceneryInstance(instance)
    if readAttribute(instance, SCAN_CONFIG.SceneryAttribute, false) == true then
        return true
    end

    local parent = instance.Parent
    if parent and parent.Name == SCAN_CONFIG.SceneryFolderName and parent:IsA('Folder') then
        return true
    end

    return false
end

local function isRoomInstance(instance)
    if type(readAttribute(instance, 'RoomType', nil)) == 'string' then
        return true
    end

    for tag in instance:GetTags() do
        if
            string.sub(tag, 1, string.len(SCAN_CONFIG.RoomTagPrefix)) == SCAN_CONFIG.RoomTagPrefix
        then
            return true
        end
    end

    return false
end

local function extractRoomType(instance)
    local roomTypeAttribute = readAttribute(instance, 'RoomType', nil)
    if type(roomTypeAttribute) == 'string' and roomTypeAttribute ~= '' then
        return roomTypeAttribute
    end

    for tag in instance:GetTags() do
        if
            string.sub(tag, 1, string.len(SCAN_CONFIG.RoomTagPrefix)) == SCAN_CONFIG.RoomTagPrefix
        then
            return string.sub(tag, string.len(SCAN_CONFIG.RoomTagPrefix) + 1)
        end
    end

    return 'Unknown'
end

local function getPrimaryPosition(instance)
    if instance:IsA('Model') then
        return instance:GetPivot().Position
    end

    if instance:IsA('BasePart') then
        return instance.Position
    end

    return Vector3.zero
end

local function getBoundingRadius(instance)
    if instance:IsA('Model') then
        local _, size = instance:GetBoundingBox()
        return math.max(size.X, size.Z) * 0.5
    end

    if instance:IsA('BasePart') then
        return math.max(instance.Size.X, instance.Size.Z) * 0.5
    end

    return 18
end

local function collectNamedPoints(roomInstance, pattern, defaultDirection)
    local entries = {}

    for _, child in ipairs(sortByName(roomInstance:GetChildren())) do
        if string.find(child.Name, pattern) and child:IsA('BasePart') then
            table.insert(entries, {
                Name = child.Name,
                Position = child.Position,
                Direction = child:GetAttribute('Direction') or defaultDirection or 'Unknown',
            })
        end
    end

    return entries
end

local function collectSpawnPoints(roomInstance)
    return collectNamedPoints(roomInstance, 'SpawnPoint', 'Unknown')
end

local function collectLootSockets(roomInstance)
    return collectNamedPoints(roomInstance, 'LootSocket', 'Unknown')
end

local function collectDoorways(roomInstance)
    return collectNamedPoints(roomInstance, 'Doorway', 'Unknown')
end

local function pickRoomKind(instance)
    if readAttribute(instance, 'IsCamp', DEFAULT_ATTRIBUTES.IsCamp) == true then
        return 'Camp'
    end

    if readAttribute(instance, 'IsExtraction', DEFAULT_ATTRIBUTES.IsExtraction) == true then
        return 'Extraction'
    end

    return readAttribute(instance, 'RoomKind', DEFAULT_ROOM_KIND)
end

local function buildAffordance(instance)
    local roomKind = pickRoomKind(instance)

    return {
        RoomId = instance.Name,
        RoomType = extractRoomType(instance),
        RoomKind = roomKind,
        SpawnSockets = collectLootSockets(instance),
        PatrolAnchors = collectSpawnPoints(instance),
        SightBreakers = {},
        DoorControlPoints = collectDoorways(instance),
        ThreatTags = { string.format('RoomKind:%s', roomKind) },
        HasMonsterSpawner = hasTag(instance, SCAN_CONFIG.HasMonsterSpawnerTag),
        HasLootSocket = hasTag(instance, SCAN_CONFIG.HasLootSocketTag),
        TraversalMask = {
            NeighborRoomIds = {},
            DoorwayIds = {},
            ExitDirections = {},
        },
    }
end

local function buildRoomData(instance)
    local roomType = extractRoomType(instance)

    return {
        Id = instance.Name,
        Type = roomType,
        Kind = pickRoomKind(instance),
        Position = getPrimaryPosition(instance),
        DetectionRadius = readAttribute(instance, 'DetectionRadius', getBoundingRadius(instance)),
        DifficultyTier = readAttribute(
            instance,
            'DifficultyTier',
            DEFAULT_ATTRIBUTES.DifficultyTier
        ),
        MonsterBudget = readAttribute(instance, 'MonsterBudget', DEFAULT_ATTRIBUTES.MonsterBudget),
        LootBudget = readAttribute(instance, 'LootBudget', DEFAULT_ATTRIBUTES.LootBudget),
        IsCamp = readAttribute(instance, 'IsCamp', DEFAULT_ATTRIBUTES.IsCamp),
        IsExtraction = readAttribute(instance, 'IsExtraction', DEFAULT_ATTRIBUTES.IsExtraction),
        RoomTemplateId = readAttribute(instance, 'RoomTemplateId', roomType),
        RoomCategory = readAttribute(instance, 'RoomCategory', roomType),
        SearchProfile = {
            Mode = readAttribute(instance, 'SearchProfileMode', 'authored'),
        },
        RiskTier = readAttribute(instance, 'RiskTier', DEFAULT_ATTRIBUTES.DifficultyTier),
        LandmarkWeight = readAttribute(instance, 'LandmarkWeight', 1),
        Neighbors = {},
    }
end

local function scanRecursive(root, results, visited)
    if not root or visited[root] then
        return
    end
    visited[root] = true

    if root:IsA('Folder') and root.Name == SCAN_CONFIG.SceneryFolderName then
        return
    end

    if isSceneryInstance(root) then
        return
    end

    if isRoomInstance(root) then
        table.insert(results.rooms, root)
        return
    end

    for _, child in ipairs(sortByName(root:GetChildren())) do
        scanRecursive(child, results, visited)
    end
end

local function getNearestRoomId(roomIds, roomById, position)
    local bestRoomId = nil
    local bestDistance = math.huge

    for _, roomId in ipairs(roomIds) do
        local room = roomById[roomId]
        if room then
            local distance = (room.Position - position).Magnitude
            if distance < bestDistance then
                bestDistance = distance
                bestRoomId = roomId
            end
        end
    end

    return bestRoomId, bestDistance
end

local function findPromptOnPart(part)
    if not part or not part:IsA('BasePart') then
        return nil
    end

    return part:FindFirstChildOfClass('ProximityPrompt')
end

function MazeWorldScanner.Scan(scanRoot)
    local root = scanRoot or DEFAULT_SCAN_ROOT
    local results = {
        rooms = {},
    }
    local visited = {}

    for _, child in ipairs(sortByName(root:GetChildren())) do
        scanRecursive(child, results, visited)
    end

    sortByName(results.rooms)

    local roomById = {}
    local roomAffordances = {}
    local campRoomId = nil

    for _, roomInstance in ipairs(results.rooms) do
        local roomData = buildRoomData(roomInstance)
        local affordance = buildAffordance(roomInstance)

        roomById[roomInstance.Name] = roomData
        roomAffordances[roomInstance.Name] = affordance

        if roomData.IsCamp then
            campRoomId = roomInstance.Name
        end
    end

    local sortedIds = {}
    for roomId in pairs(roomById) do
        table.insert(sortedIds, roomId)
    end
    table.sort(sortedIds)

    for _, idA in ipairs(sortedIds) do
        local roomA = roomById[idA]
        for _, idB in ipairs(sortedIds) do
            local roomB = roomById[idB]
            if idA ~= idB then
                local distance = (roomB.Position - roomA.Position).Magnitude
                if distance < 50 then
                    table.insert(roomA.Neighbors, idB)
                    table.insert(roomAffordances[idA].TraversalMask.NeighborRoomIds, idB)
                end
            end
        end

        table.sort(roomA.Neighbors)
        table.sort(roomAffordances[idA].TraversalMask.NeighborRoomIds)
    end

    return {
        rooms = results.rooms,
        roomById = roomById,
        roomAffordances = roomAffordances,
        campRoomId = campRoomId,
    }
end

function MazeWorldScanner.ScanAsync(scanRoot)
    return MazeWorldScanner.Scan(scanRoot)
end

function MazeWorldScanner.GetRoomById(scanResult, roomId)
    return scanResult.roomById and scanResult.roomById[roomId]
end

function MazeWorldScanner.GetRoomIds(scanResult)
    local ids = {}
    if scanResult.roomById then
        for id in pairs(scanResult.roomById) do
            table.insert(ids, id)
        end
        table.sort(ids)
    end
    return ids
end

function MazeWorldScanner.GetEligibleMonsterRooms(scanResult)
    local eligible = {}
    if scanResult.roomAffordances then
        for roomId, affordance in pairs(scanResult.roomAffordances) do
            if affordance.HasMonsterSpawner then
                table.insert(eligible, roomId)
            end
        end
        table.sort(eligible)
    end
    return eligible
end

function MazeWorldScanner.GetRoomsByDifficultyTier(scanResult, tier)
    local rooms = {}
    if scanResult.roomById then
        for id, room in pairs(scanResult.roomById) do
            if room.DifficultyTier == tier then
                table.insert(rooms, id)
            end
        end
        table.sort(rooms)
    end
    return rooms
end

function MazeWorldScanner.IsSceneryInstance(instance)
    return isSceneryInstance(instance)
end

function MazeWorldScanner.GetRoomTypeFromInstance(instance)
    return extractRoomType(instance)
end

function MazeWorldScanner.ToWorldFormat(scanResult)
    local roomIds = MazeWorldScanner.GetRoomIds(scanResult)

    return {
        RoomIds = roomIds,
        RoomById = scanResult.roomById,
        RoomAffordances = scanResult.roomAffordances,
        CampRoomId = scanResult.campRoomId,
        PatrolPoints = {},
        InitialMonsterPatrolIndex = nil,
    }
end

function MazeWorldScanner.BuildStaticWorld(scanRoot)
    local root = scanRoot or Workspace:FindFirstChild(STATIC_WORLD_ROOT_NAME)
    if root == nil then
        return nil
    end

    local scanResult = MazeWorldScanner.Scan(root)
    local world = MazeWorldScanner.ToWorldFormat(scanResult)
    local items = Gameplay.Config.Items
    local itemIndex = 1

    local returnHoldPadPart = root:FindFirstChild('ReturnHoldPad', true)
    if not (returnHoldPadPart and returnHoldPadPart:IsA('BasePart')) then
        error(
            string.format('%s is missing required part "ReturnHoldPad".', STATIC_WORLD_ROOT_NAME),
            0
        )
    end

    local returnHoldPrompt = findPromptOnPart(returnHoldPadPart)
    if returnHoldPrompt == nil then
        error(
            string.format('%s ReturnHoldPad is missing a ProximityPrompt.', STATIC_WORLD_ROOT_NAME),
            0
        )
    end

    returnHoldPrompt.ActionText = returnHoldPrompt.ActionText ~= '' and returnHoldPrompt.ActionText
        or DEFAULT_RETURN_ACTION_TEXT
    returnHoldPrompt.ObjectText = returnHoldPrompt.ObjectText ~= '' and returnHoldPrompt.ObjectText
        or DEFAULT_RETURN_OBJECT_TEXT

    local spawnMarker = root:FindFirstChild('SpawnMarker', true)
    local spawnCFrame = spawnMarker and spawnMarker:IsA('BasePart') and spawnMarker.CFrame
        or returnHoldPadPart.CFrame

    local roomCenters = {}
    local lootNodes = {}
    local extractionNodes = {}
    local patrolPoints = {}
    local doorwayState = {}
    local roomInstancesById = {}

    for _, roomInstance in ipairs(scanResult.rooms or {}) do
        roomInstancesById[roomInstance.Name] = roomInstance
        roomCenters[roomInstance.Name] = getPrimaryPosition(roomInstance)
    end

    for _, roomId in ipairs(world.RoomIds) do
        local room = world.RoomById[roomId]
        local affordance = world.RoomAffordances[roomId]
        local roomInstance = roomInstancesById[roomId]

        affordance.RoomCenter = room.Position
        affordance.RoomTemplateId = room.RoomTemplateId
        affordance.RoomCategory = room.RoomCategory
        affordance.SearchProfile = room.SearchProfile
        affordance.RiskTier = room.RiskTier
        affordance.LandmarkWeight = room.LandmarkWeight

        if #affordance.SpawnSockets == 0 then
            table.insert(affordance.SpawnSockets, {
                Id = string.format('%s_Spawn_1', roomId),
                Kind = 'RoomCenter',
                Position = room.Position + Vector3.new(0, 1.5, 0),
            })
        else
            for index, spawnSocket in ipairs(affordance.SpawnSockets) do
                spawnSocket.Id = spawnSocket.Name or string.format('%s_Spawn_%d', roomId, index)
                spawnSocket.Kind = 'LootSocket'
            end
        end

        if room.MonsterBudget > 0 or affordance.HasMonsterSpawner then
            for _, patrolAnchor in ipairs(affordance.PatrolAnchors) do
                table.insert(patrolPoints, patrolAnchor.Position)
            end
        end

        local extractionPart = roomInstance
            and roomInstance:FindFirstChild('ExtractionMarker', true)
        local extractionPrompt = findPromptOnPart(extractionPart)
        if extractionPart and extractionPrompt then
            extractionPrompt.ActionText = extractionPrompt.ActionText ~= ''
                    and extractionPrompt.ActionText
                or DEFAULT_RETURN_ACTION_TEXT
            extractionPrompt.ObjectText = extractionPrompt.ObjectText ~= ''
                    and extractionPrompt.ObjectText
                or DEFAULT_RETURN_OBJECT_TEXT

            local extractionNodeId = extractionPart:GetAttribute('ExtractionNodeId')
                or string.format('%s_Extraction', roomId)
            extractionNodes[extractionNodeId] = {
                Id = extractionNodeId,
                Prompt = extractionPrompt,
                Position = extractionPart.Position,
            }
        end

        if room.Kind == 'Loot' then
            local lootSocket = affordance.SpawnSockets[1]
            local itemDef = items[itemIndex]
            itemIndex = (itemIndex % #items) + 1

            local lootPart = roomInstance and roomInstance:FindFirstChild('LootPrompt', true)
            if lootPart == nil and roomInstance then
                lootPart = roomInstance:FindFirstChild('LootSocket_1', true)
            end

            local lootPrompt = findPromptOnPart(lootPart)
            if lootPrompt ~= nil then
                lootPrompt.ActionText = lootPrompt.ActionText ~= '' and lootPrompt.ActionText
                    or 'Collect'
                lootPrompt.ObjectText = lootPrompt.ObjectText ~= '' and lootPrompt.ObjectText
                    or itemDef.Name

                lootNodes[roomId] = {
                    ItemDef = itemDef,
                    RoomTemplateId = room.RoomTemplateId,
                    SearchProfile = room.SearchProfile,
                    Prompt = lootPrompt,
                    Position = lootSocket.Position,
                    Collected = false,
                }
            end
        end

        for _, controlPoint in ipairs(affordance.DoorControlPoints) do
            local doorwayId = roomId .. ':' .. controlPoint.Name
            local doorwayPart = roomInstance and roomInstance:FindFirstChild(controlPoint.Name)
            local doorwayPrompt = findPromptOnPart(doorwayPart)
            table.insert(affordance.TraversalMask.DoorwayIds, doorwayId)

            if doorwayPart and doorwayPart:IsA('BasePart') then
                doorwayState[doorwayId] = {
                    Id = doorwayId,
                    Prompt = doorwayPrompt,
                    Position = doorwayPart.Position,
                    IsOpen = false,
                    Part = doorwayPart,
                    ClosedTransparency = doorwayPart.Transparency,
                }
            end
        end

        table.sort(affordance.TraversalMask.DoorwayIds)
    end

    local function findRoomByPosition(position)
        local nearestRoomId, nearestDistance =
            getNearestRoomId(world.RoomIds, world.RoomById, position)
        if nearestRoomId == nil then
            return nil
        end

        local room = world.RoomById[nearestRoomId]
        if nearestDistance > (room.DetectionRadius or 18) then
            return nil
        end

        return room, nearestDistance
    end

    local function toggleDoor(doorwayId)
        local doorway = doorwayState[doorwayId]
        if doorway == nil then
            return false
        end

        doorway.IsOpen = not doorway.IsOpen
        doorway.Part.CanCollide = not doorway.IsOpen
        doorway.Part.Transparency = doorway.IsOpen and 0.65 or doorway.ClosedTransparency

        if doorway.Prompt ~= nil then
            doorway.Prompt.ActionText = doorway.IsOpen and 'Close' or 'Open'
        end

        return true
    end

    world.Root = root
    world.RoomInstancesById = roomInstancesById
    world.RoomCenters = roomCenters
    world.SpawnCFrame = spawnCFrame
    world.ReturnHoldCFrame = returnHoldPadPart.CFrame + Vector3.new(0, 3, 0)
    world.ReturnHoldPad = {
        Prompt = returnHoldPrompt,
        Position = returnHoldPadPart.Position,
    }
    world.ExtractionNodes = extractionNodes
    world.LootNodes = lootNodes
    world.Doorways = doorwayState
    world.PatrolPoints = patrolPoints
    world.InitialMonsterPatrolIndex = #patrolPoints > 0 and 1 or nil
    world.InitialMonsterSpawnRoomId = #world.RoomIds > 0
            and world.RoomIds[math.min(2, #world.RoomIds)]
        or nil
    world.FindRoomByPosition = findRoomByPosition
    world.ToggleDoor = toggleDoor
    world.CanTraverseBetweenPositions = function()
        return true
    end

    return world
end

return MazeWorldScanner
