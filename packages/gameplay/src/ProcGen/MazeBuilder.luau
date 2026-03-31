local MazeBuilder = {}

local HexRoomPrefabs = require(script.Parent.HexRoomPrefabs)
local MazePassageTemplates = require(script.Parent.MazePassageTemplates)
local MazeRoomArchetypes = require(script.Parent.MazeRoomArchetypes)
local MazeRoomTemplates = require(script.Parent.MazeRoomTemplates)

local HEX_DIRECTIONS = {
    { Q = 1, R = 0 },
    { Q = 1, R = -1 },
    { Q = 0, R = -1 },
    { Q = -1, R = 0 },
    { Q = -1, R = 1 },
    { Q = 0, R = 1 },
}

local OPPOSITE_DIRECTIONS = { 4, 5, 6, 1, 2, 3 }

local START_TYPE_IDS = { 'T5', 'T6', 'T7' }
local BASE_RATIO_COUNTS = {
    T1 = 4,
    T2 = 5,
    T3 = 2,
    T4 = 2,
    T5 = 3,
    T6 = 2,
    T7 = 1,
    T8 = 1,
}
local RATIO_TYPE_ORDER = { 'T1', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'T8' }

local DEFAULT_ROOM_COUNT = 20
local DEFAULT_DOOR_LEAF_CHANCE = 0.6
local DEFAULT_MAX_ATTEMPTS = 200

local function rotateDirection(directionIndex, steps)
    return ((directionIndex - 1 + steps) % 6) + 1
end

local function rotateDirections(directions, steps)
    local rotated = table.create(#directions)
    for index, directionIndex in ipairs(directions) do
        rotated[index] = rotateDirection(directionIndex, steps)
    end
    table.sort(rotated)
    return rotated
end

local PREFAB_VARIANTS_BY_TYPE = {}
for _, typeId in ipairs(RATIO_TYPE_ORDER) do
    local variants = {}
    local seenMasks = {}
    local definition = HexRoomPrefabs.getDefinition(typeId)
    if definition then
        for steps = 0, 5 do
            local openDirections = rotateDirections(definition.OpenDirections, steps)
            local doorMask = HexRoomPrefabs.computeDoorMask(openDirections)
            if not seenMasks[doorMask] then
                seenMasks[doorMask] = true
                table.insert(
                    variants,
                    table.freeze({
                        RotationSteps = steps,
                        OpenDirections = table.freeze(openDirections),
                        DoorMask = doorMask,
                    })
                )
            end
        end
    end
    PREFAB_VARIANTS_BY_TYPE[typeId] = table.freeze(variants)
end

local function oppositeDirection(directionIndex)
    return OPPOSITE_DIRECTIONS[directionIndex]
end

local function axialKey(q, r)
    return bit32.bor(bit32.lshift(bit32.band(q, 0xFFFF), 16), bit32.band(r, 0xFFFF))
end

local function axialToWorld(q, r, roomSpacing)
    local sqrt3 = math.sqrt(3)
    local x = roomSpacing * (sqrt3 * q + (sqrt3 / 2) * r)
    local z = roomSpacing * ((3 / 2) * r)
    return Vector3.new(x, 0, z)
end

local function buildDirectionSet(directions)
    local directionSet = {}
    for _, directionIndex in ipairs(directions) do
        directionSet[directionIndex] = true
    end
    return directionSet
end

local function countEntries(map)
    local count = 0
    for _ in pairs(map or {}) do
        count += 1
    end
    return count
end

local function cloneSortedArray(values)
    local cloned = table.clone(values or {})
    table.sort(cloned)
    return cloned
end

local function buildSet(values)
    local lookup = {}
    for _, value in ipairs(values or {}) do
        lookup[value] = true
    end
    return lookup
end

local function sortedRoomIds(rooms)
    local roomIds = {}
    for roomId in pairs(rooms) do
        table.insert(roomIds, roomId)
    end
    table.sort(roomIds)
    return roomIds
end

local function sortedDoorwayIds(doorways)
    local doorwayIds = {}
    for doorwayId in pairs(doorways or {}) do
        table.insert(doorwayIds, doorwayId)
    end
    table.sort(doorwayIds)
    return doorwayIds
end

local function collectSortedNeighborRoomIds(room)
    local neighborRoomIds = {}
    for _, neighborRoomId in pairs(room.Neighbors or {}) do
        table.insert(neighborRoomIds, neighborRoomId)
    end
    table.sort(neighborRoomIds)
    return neighborRoomIds
end

local function createRoom(
    roomId,
    q,
    r,
    roomSpacing,
    typeId,
    rotationSteps,
    openDirections,
    doorMaskOverride
)
    local definition = HexRoomPrefabs.getDefinition(typeId)
    local doorMask = doorMaskOverride or HexRoomPrefabs.computeDoorMask(openDirections)

    return {
        Id = roomId,
        Kind = 'Loot',
        Grid = {
            Q = q,
            R = r,
        },
        Position = axialToWorld(q, r, roomSpacing),
        DoorMask = doorMask,
        DoorCount = #openDirections,
        DoorDirections = table.clone(openDirections),
        OpenDirections = table.clone(openDirections),
        Neighbors = {},
        ExitDirections = {},
        PrefabId = definition and definition.PrefabId or string.format('Hex_%s', typeId),
        PrefabTypeId = typeId,
        PrefabRotationSteps = rotationSteps,
    }
end

local function makeFrontierKey(roomId, directionIndex)
    return string.format('%s:%d', roomId, directionIndex)
end

local function addFrontier(frontier, frontierIndexByKey, roomId, directionIndex)
    local key = makeFrontierKey(roomId, directionIndex)
    if frontierIndexByKey[key] then
        return
    end

    table.insert(frontier, {
        RoomId = roomId,
        Direction = directionIndex,
    })
    frontierIndexByKey[key] = #frontier
end

local function removeFrontier(frontier, frontierIndexByKey, roomId, directionIndex)
    local key = makeFrontierKey(roomId, directionIndex)
    local index = frontierIndexByKey[key]
    if not index then
        return
    end

    local lastIndex = #frontier
    local swapped = frontier[lastIndex]
    frontier[index] = swapped
    frontier[lastIndex] = nil
    frontierIndexByKey[key] = nil

    if swapped and index <= #frontier then
        frontierIndexByKey[makeFrontierKey(swapped.RoomId, swapped.Direction)] = index
    end
end

local function popRandomFrontier(frontier, frontierIndexByKey, random)
    if #frontier == 0 then
        return nil
    end

    local index = random:NextInteger(1, #frontier)
    local entry = frontier[index]
    removeFrontier(frontier, frontierIndexByKey, entry.RoomId, entry.Direction)
    return entry
end

local function buildPrefabQuotas(roomCount)
    local baseTotal = 0
    for _, typeId in ipairs(RATIO_TYPE_ORDER) do
        baseTotal += BASE_RATIO_COUNTS[typeId]
    end

    local quotas = {}
    local remainders = {}
    local assigned = 0

    for _, typeId in ipairs(RATIO_TYPE_ORDER) do
        local scaled = (roomCount * BASE_RATIO_COUNTS[typeId]) / baseTotal
        local baseCount = math.floor(scaled)
        quotas[typeId] = baseCount
        assigned += baseCount

        table.insert(remainders, {
            TypeId = typeId,
            Value = scaled - baseCount,
            Weight = BASE_RATIO_COUNTS[typeId],
        })
    end

    table.sort(remainders, function(left, right)
        if left.Value ~= right.Value then
            return left.Value > right.Value
        end

        if left.Weight ~= right.Weight then
            return left.Weight > right.Weight
        end

        return left.TypeId < right.TypeId
    end)

    local remaining = roomCount - assigned
    local remainderIndex = 1
    while remaining > 0 do
        local remainder = remainders[remainderIndex]
        quotas[remainder.TypeId] += 1
        remaining -= 1

        remainderIndex += 1
        if remainderIndex > #remainders then
            remainderIndex = 1
        end
    end

    local hasStartType = false
    for _, typeId in ipairs(START_TYPE_IDS) do
        if quotas[typeId] > 0 then
            hasStartType = true
            break
        end
    end

    if not hasStartType then
        for _, donorTypeId in ipairs(RATIO_TYPE_ORDER) do
            if quotas[donorTypeId] > 1 then
                quotas[donorTypeId] -= 1
                quotas[START_TYPE_IDS[1]] += 1
                hasStartType = true
                break
            end
        end
    end

    if not hasStartType then
        error('MazeBuilder could not allocate a valid start-room prefab quota', 0)
    end

    return quotas
end

local function pickWeightedType(random, quotas, typeIds)
    local totalWeight = 0
    for _, typeId in ipairs(typeIds) do
        totalWeight += math.max(0, quotas[typeId] or 0)
    end

    if totalWeight <= 0 then
        return nil
    end

    local roll = random:NextNumber(0, totalWeight)
    local running = 0
    for _, typeId in ipairs(typeIds) do
        running += math.max(0, quotas[typeId] or 0)
        if roll <= running then
            return typeId
        end
    end

    return typeIds[#typeIds]
end

local function canPlaceVariant(rooms, roomsByAxialKey, blockedAxialKeys, q, r, openMask)
    local positionKey = axialKey(q, r)
    if roomsByAxialKey[positionKey] or blockedAxialKeys[positionKey] then
        return false
    end

    for directionIndex, direction in ipairs(HEX_DIRECTIONS) do
        local neighborQ = q + direction.Q
        local neighborR = r + direction.R
        local neighborRoomId = roomsByAxialKey[axialKey(neighborQ, neighborR)]
        if not neighborRoomId then
            continue
        end

        local neighbor = rooms[neighborRoomId]
        local opposite = OPPOSITE_DIRECTIONS[directionIndex]
        local selfHasDoor = bit32.band(openMask, HexRoomPrefabs.DirectionBitmasks[directionIndex])
            ~= 0
        local neighborHasDoor = bit32.band(
            neighbor.DoorMask,
            HexRoomPrefabs.DirectionBitmasks[opposite]
        ) ~= 0

        if selfHasDoor ~= neighborHasDoor then
            return false
        end

        if selfHasDoor and neighbor.Neighbors[opposite] ~= nil then
            return false
        end
    end

    return true
end

local function enumeratePlacementCandidates(
    random,
    quotas,
    rooms,
    roomsByAxialKey,
    blockedAxialKeys,
    targetQ,
    targetR,
    requiredDirection
)
    local candidates = {}
    local requiredMask = HexRoomPrefabs.DirectionBitmasks[requiredDirection]

    for _, typeId in ipairs(RATIO_TYPE_ORDER) do
        local quota = quotas[typeId] or 0
        if quota <= 0 then
            continue
        end

        for _, variant in ipairs(PREFAB_VARIANTS_BY_TYPE[typeId]) do
            if bit32.band(variant.DoorMask, requiredMask) == 0 then
                continue
            end

            if
                canPlaceVariant(
                    rooms,
                    roomsByAxialKey,
                    blockedAxialKeys,
                    targetQ,
                    targetR,
                    variant.DoorMask
                )
            then
                table.insert(candidates, {
                    TypeId = typeId,
                    RotationSteps = variant.RotationSteps,
                    OpenDirections = variant.OpenDirections,
                    DoorMask = variant.DoorMask,
                    Weight = quota,
                })
            end
        end
    end

    if #candidates == 0 then
        return nil
    end

    local totalWeight = 0
    for _, candidate in ipairs(candidates) do
        totalWeight += candidate.Weight
    end

    local roll = random:NextNumber(0, totalWeight)
    local running = 0
    for _, candidate in ipairs(candidates) do
        running += candidate.Weight
        if roll <= running then
            return candidate
        end
    end

    return candidates[#candidates]
end

local function computeDistances(rooms, startRoomId)
    local distances = {
        [startRoomId] = 0,
    }
    local queue = { startRoomId }
    local queueIndex = 1

    while queueIndex <= #queue do
        local roomId = queue[queueIndex]
        queueIndex += 1

        local room = rooms[roomId]
        local distance = distances[roomId]

        for _, neighborRoomId in ipairs(collectSortedNeighborRoomIds(room)) do
            if distances[neighborRoomId] == nil then
                distances[neighborRoomId] = distance + 1
                table.insert(queue, neighborRoomId)
            end
        end
    end

    return distances
end

local function selectExtractionRoom(rooms, campRoomId)
    local distances = computeDistances(rooms, campRoomId)
    local selectedRoomId = campRoomId
    local selectedDistance = -1

    for roomId, distance in pairs(distances) do
        if
            distance > selectedDistance
            or (distance == selectedDistance and roomId < selectedRoomId)
        then
            selectedDistance = distance
            selectedRoomId = roomId
        end
    end

    return selectedRoomId
end

local function buildMainPath(rooms, startRoomId, targetRoomId)
    local parents = {}
    local visited = {
        [startRoomId] = true,
    }
    local queue = { startRoomId }
    local queueIndex = 1

    while queueIndex <= #queue do
        local roomId = queue[queueIndex]
        queueIndex += 1

        if roomId == targetRoomId then
            break
        end

        local room = rooms[roomId]
        for _, neighborRoomId in ipairs(collectSortedNeighborRoomIds(room)) do
            if not visited[neighborRoomId] then
                visited[neighborRoomId] = true
                parents[neighborRoomId] = roomId
                table.insert(queue, neighborRoomId)
            end
        end
    end

    local path = {}
    local cursor = targetRoomId
    while cursor do
        table.insert(path, 1, cursor)
        if cursor == startRoomId then
            break
        end
        cursor = parents[cursor]
    end

    if path[1] ~= startRoomId then
        return { startRoomId, targetRoomId }
    end

    return path
end

local function finalizeRoomConnectivity(rooms)
    for _, room in pairs(rooms) do
        local connectedDirections = {}
        for directionIndex in pairs(room.Neighbors or {}) do
            table.insert(connectedDirections, directionIndex)
        end
        table.sort(connectedDirections)

        room.OpenDirections = table.clone(connectedDirections)
        room.DoorDirections = table.clone(connectedDirections)
        room.OpenDirectionSet = buildDirectionSet(connectedDirections)
        room.DoorCount = #connectedDirections
        room.DoorMask = HexRoomPrefabs.computeDoorMask(connectedDirections)
        room.ExitDirections = {}
        room.StartExternalDirection = nil
    end
end

local function validateRoomConnections(rooms)
    for roomId, room in pairs(rooms) do
        local exitDirectionMask = 0
        for _, directionIndex in ipairs(room.ExitDirections or {}) do
            exitDirectionMask =
                bit32.bor(exitDirectionMask, HexRoomPrefabs.DirectionBitmasks[directionIndex])
        end

        for directionIndex, neighborRoomId in pairs(room.Neighbors) do
            if bit32.band(room.DoorMask, HexRoomPrefabs.DirectionBitmasks[directionIndex]) == 0 then
                return false, string.format('NeighborOnClosedEdge(%s:%d)', roomId, directionIndex)
            end

            local neighbor = rooms[neighborRoomId]
            if not neighbor then
                return false,
                    string.format('MissingNeighborRoom(%s:%s)', roomId, tostring(neighborRoomId))
            end

            local opposite = OPPOSITE_DIRECTIONS[directionIndex]
            if neighbor.Neighbors[opposite] ~= roomId then
                return false, string.format('NonMirrorNeighbor(%s:%s)', roomId, neighborRoomId)
            end
            if bit32.band(neighbor.DoorMask, HexRoomPrefabs.DirectionBitmasks[opposite]) == 0 then
                return false,
                    string.format('NeighborClosedMirrorEdge(%s:%s)', roomId, neighborRoomId)
            end
        end

        for _, directionIndex in ipairs(room.OpenDirections) do
            local neighborRoomId = room.Neighbors[directionIndex]
            if
                neighborRoomId == nil
                and bit32.band(
                        exitDirectionMask,
                        HexRoomPrefabs.DirectionBitmasks[directionIndex]
                    )
                    == 0
            then
                return false, string.format('UnclassifiedOpenEdge(%s:%d)', roomId, directionIndex)
            end
        end

        for directionIndex = 1, 6 do
            local directionBit = HexRoomPrefabs.DirectionBitmasks[directionIndex]
            if bit32.band(exitDirectionMask, directionBit) ~= 0 then
                if room.Neighbors[directionIndex] ~= nil then
                    return false,
                        string.format('ExitCollidesWithNeighbor(%s:%d)', roomId, directionIndex)
                end
                if bit32.band(room.DoorMask, directionBit) == 0 then
                    return false, string.format('ExitOnClosedEdge(%s:%d)', roomId, directionIndex)
                end
            end
        end
    end

    return true, nil
end

local function buildLoopMetadata(rooms, doorways, campRoomId)
    local visited = {
        [campRoomId] = true,
    }
    local queue = { campRoomId }
    local queueIndex = 1
    local treeEdges = {}

    while queueIndex <= #queue do
        local roomId = queue[queueIndex]
        queueIndex += 1
        local room = rooms[roomId]

        for _, neighborRoomId in ipairs(collectSortedNeighborRoomIds(room)) do
            if not visited[neighborRoomId] then
                visited[neighborRoomId] = true
                treeEdges[string.format(
                    '%s|%s',
                    roomId < neighborRoomId and roomId or neighborRoomId,
                    roomId < neighborRoomId and neighborRoomId or roomId
                )] =
                    true
                table.insert(queue, neighborRoomId)
            end
        end
    end

    local loopDoorwayIds = {}
    local loopDoorwaySet = {}
    local loopRoomSet = {}

    for _, doorwayId in ipairs(sortedDoorwayIds(doorways)) do
        if not treeEdges[doorwayId] then
            table.insert(loopDoorwayIds, doorwayId)
            loopDoorwaySet[doorwayId] = true
            local doorway = doorways[doorwayId]
            loopRoomSet[doorway.RoomA] = true
            loopRoomSet[doorway.RoomB] = true
        end
    end

    return {
        LoopCount = #loopDoorwayIds,
        LoopDoorwayIds = loopDoorwayIds,
        LoopDoorwaySet = loopDoorwaySet,
        LoopRoomSet = loopRoomSet,
    }
end

local function selectScoredRoomId(roomIds, rooms, excludedRoomIds, predicate, scoreFn)
    local bestRoomId = nil
    local bestScore = nil

    for _, roomId in ipairs(roomIds) do
        if excludedRoomIds[roomId] ~= true then
            local room = rooms[roomId]
            if predicate(roomId, room) then
                local score = scoreFn(roomId, room)
                if
                    bestScore == nil
                    or score > bestScore
                    or (score == bestScore and roomId < bestRoomId)
                then
                    bestRoomId = roomId
                    bestScore = score
                end
            end
        end
    end

    return bestRoomId
end

local function applyArchetype(room)
    local archetype = MazeRoomArchetypes.classifyRoom(room)
    room.ArchetypeId = archetype.Id
    room.AuthoringAssetId = archetype.AuthoringAssetId
    room.SupportsExternalShellModel = archetype.SupportsExternalShellModel == true
    room.VisualLanguage = archetype.VisualLanguage
end

local function assignRoomTemplates(rooms, campRoomId, extractionRoomId, mainPath, loopMetadata)
    local roomIds = sortedRoomIds(rooms)
    local distances = computeDistances(rooms, campRoomId)
    local mainPathSet = buildSet(mainPath)
    local maxDistance = 0
    for _, distance in pairs(distances) do
        maxDistance = math.max(maxDistance, distance)
    end

    local assignedRoomIds = {}

    local function assign(roomId, templateId)
        if roomId == nil then
            return
        end
        MazeRoomTemplates.applyTemplate(rooms[roomId], templateId)
        applyArchetype(rooms[roomId])
        assignedRoomIds[roomId] = true
    end

    assign(campRoomId, 'EntrySafe')
    assign(extractionRoomId, 'ExtractionReturn')

    local midDepth = maxDistance / 2
    local landmarkRoomId = selectScoredRoomId(
        roomIds,
        rooms,
        assignedRoomIds,
        function(roomId, room)
            return room.Kind == 'Loot'
                and distances[roomId] >= 2
                and countEntries(room.Neighbors) >= 2
        end,
        function(roomId, room)
            local distanceScore = math.max(0, 10 - math.abs(distances[roomId] - midDepth) * 2)
            local loopBonus = loopMetadata.LoopRoomSet[roomId] and 8 or 0
            local pathBonus = mainPathSet[roomId] and 6 or 0
            return (countEntries(room.Neighbors) * 10) + distanceScore + loopBonus + pathBonus
        end
    )
    assign(landmarkRoomId, 'LandmarkFacility')

    local highValueRiskRoomId = selectScoredRoomId(
        roomIds,
        rooms,
        assignedRoomIds,
        function(roomId, room)
            return room.Kind == 'Loot' and distances[roomId] >= 2
        end,
        function(roomId, room)
            local deadEndBonus = room.DoorCount == 1 and 25 or 0
            local offMainPathBonus = mainPathSet[roomId] and 0 or 10
            return (distances[roomId] * 15) + deadEndBonus + offMainPathBonus - room.DoorCount
        end
    )
    assign(highValueRiskRoomId, 'HighValueRisk')

    local bulkheadRoomId = selectScoredRoomId(
        roomIds,
        rooms,
        assignedRoomIds,
        function(roomId, room)
            return room.Kind == 'Loot'
                and mainPathSet[roomId]
                and distances[roomId] >= 1
                and distances[roomId] < maxDistance
                and countEntries(room.Neighbors) >= 2
        end,
        function(roomId, room)
            local targetDepth = math.max(1, math.floor(maxDistance * 0.45))
            local depthScore = math.max(0, 18 - math.abs(distances[roomId] - targetDepth) * 6)
            local degreeScore = room.DoorCount == 2 and 14 or (room.DoorCount == 3 and 10 or 4)
            return depthScore + degreeScore
        end
    )
    assign(bulkheadRoomId, 'BulkheadGate')

    local shortcutRoomId = selectScoredRoomId(
        roomIds,
        rooms,
        assignedRoomIds,
        function(roomId, room)
            return room.Kind == 'Loot'
                and (loopMetadata.LoopRoomSet[roomId] or countEntries(room.Neighbors) >= 3)
                and distances[roomId] >= 2
        end,
        function(roomId, room)
            local loopBonus = loopMetadata.LoopRoomSet[roomId] and 20 or 0
            local offMainPathBonus = mainPathSet[roomId] and 0 or 12
            return loopBonus
                + offMainPathBonus
                + (countEntries(room.Neighbors) * 4)
                + distances[roomId]
        end
    )
    assign(shortcutRoomId, 'ShortcutLoop')

    local remainingLootRoomIds = {}
    for _, roomId in ipairs(roomIds) do
        if assignedRoomIds[roomId] ~= true and rooms[roomId].Kind == 'Loot' then
            table.insert(remainingLootRoomIds, roomId)
        end
    end

    table.sort(remainingLootRoomIds, function(left, right)
        local leftRoom = rooms[left]
        local rightRoom = rooms[right]
        local leftScore = (mainPathSet[left] and 20 or 0)
            + (countEntries(leftRoom.Neighbors) * 4)
            - distances[left]
        local rightScore = (mainPathSet[right] and 20 or 0)
            + (countEntries(rightRoom.Neighbors) * 4)
            - distances[right]
        if leftScore ~= rightScore then
            return leftScore > rightScore
        end
        return left < right
    end)

    local transitTarget = 0
    if #remainingLootRoomIds > 1 then
        transitTarget = math.max(
            1,
            math.min(math.floor(#remainingLootRoomIds * 0.35), #remainingLootRoomIds - 1)
        )
    end

    for index, roomId in ipairs(remainingLootRoomIds) do
        if index <= transitTarget then
            assign(roomId, 'TransitHall')
        else
            assign(roomId, 'SearchCluster')
        end
    end

    for _, roomId in ipairs(roomIds) do
        if rooms[roomId].RoomTemplateId == nil then
            local fallbackTemplateId = if roomId == campRoomId
                then 'EntrySafe'
                elseif roomId == extractionRoomId then 'ExtractionReturn'
                else 'SearchCluster'
            assign(roomId, fallbackTemplateId)
        end

        rooms[roomId].EndpointDefs = MazeRoomTemplates.buildEndpointDefs(rooms[roomId])
    end

    return {
        Distances = distances,
        LandmarkRoomId = landmarkRoomId,
        HighValueRiskRoomId = highValueRiskRoomId,
        BulkheadRoomId = bulkheadRoomId,
        ShortcutRoomId = shortcutRoomId,
    }
end

local function indexEndpointDefsByDirection(room)
    local endpointsByDirection = {}
    for _, endpointDef in ipairs(room.EndpointDefs or {}) do
        endpointsByDirection[endpointDef.Direction] = endpointDef
    end
    return endpointsByDirection
end

local function enrichDoorwayMetadata(rooms, doorways, loopMetadata)
    for doorwayId, doorway in pairs(doorways) do
        local roomA = rooms[doorway.RoomA]
        local roomB = rooms[doorway.RoomB]
        local endpointDefsA = indexEndpointDefsByDirection(roomA)
        local endpointDefsB = indexEndpointDefsByDirection(roomB)
        local passageDefinition = MazePassageTemplates.resolveDoorwayArchetype(
            roomA,
            roomB,
            loopMetadata.LoopDoorwaySet[doorwayId] == true
        )
        doorway.PassageArchetypeId = passageDefinition.Id
        doorway.EndpointTypeA = endpointDefsA[doorway.DirectionFromA]
                and endpointDefsA[doorway.DirectionFromA].EndpointType
            or MazePassageTemplates.EndpointType.Hall
        doorway.EndpointTypeB = endpointDefsB[doorway.DirectionFromB]
                and endpointDefsB[doorway.DirectionFromB].EndpointType
            or MazePassageTemplates.EndpointType.Hall
        doorway.RoomCategoryA = roomA.RoomCategory
        doorway.RoomCategoryB = roomB.RoomCategory
        doorway.IsLoopDoorway = loopMetadata.LoopDoorwaySet[doorwayId] == true
    end
end

local function buildMacroGraph(roomIds, rooms, mainPath, loopMetadata, assignmentMetadata)
    local branchRoomIds = {}
    local mainPathSet = buildSet(mainPath)
    for _, roomId in ipairs(roomIds) do
        if mainPathSet[roomId] ~= true then
            table.insert(branchRoomIds, roomId)
        end
    end

    local anchorRoomIds = {}
    for _, roomId in ipairs({
        mainPath[1],
        assignmentMetadata.LandmarkRoomId,
        assignmentMetadata.HighValueRiskRoomId,
        mainPath[#mainPath],
    }) do
        if roomId ~= nil and not table.find(anchorRoomIds, roomId) then
            table.insert(anchorRoomIds, roomId)
        end
    end

    local loopRoomIds = {}
    for roomId in pairs(loopMetadata.LoopRoomSet) do
        table.insert(loopRoomIds, roomId)
    end
    table.sort(loopRoomIds)

    local landmarkRoomIds = {}
    for _, roomId in ipairs(roomIds) do
        if (rooms[roomId].LandmarkWeight or 0) >= 3 then
            table.insert(landmarkRoomIds, roomId)
        end
    end

    return {
        Style = 'AnchoredLoopingFacility',
        AnchorRoomIds = anchorRoomIds,
        LandmarkRoomIds = landmarkRoomIds,
        ShortcutRoomIds = assignmentMetadata.ShortcutRoomId and {
            assignmentMetadata.ShortcutRoomId,
        } or {},
        MainPathRoomIds = cloneSortedArray(mainPath),
        BranchRoomIds = branchRoomIds,
        LoopDoorwayIds = cloneSortedArray(loopMetadata.LoopDoorwayIds),
        LoopRoomIds = loopRoomIds,
        LoopCount = loopMetadata.LoopCount,
        DepthByRoomId = assignmentMetadata.Distances,
    }
end

local function buildPlacedRooms(roomIds, rooms)
    local placedRooms = {}
    for _, roomId in ipairs(roomIds) do
        local room = rooms[roomId]
        table.insert(placedRooms, {
            Id = roomId,
            Category = room.RoomCategory,
            RoomTemplateId = room.RoomTemplateId,
            RiskTier = room.RiskTier,
            LandmarkWeight = room.LandmarkWeight,
            SearchProfile = room.SearchProfile,
            Position = room.Position,
        })
    end
    return placedRooms
end

local function buildPlacedPassages(doorways, externalDoorways)
    local placedDoorways = {}
    for _, doorwayId in ipairs(sortedDoorwayIds(doorways)) do
        local doorway = doorways[doorwayId]
        table.insert(placedDoorways, {
            Id = doorwayId,
            Kind = 'Doorway',
            RoomA = doorway.RoomA,
            RoomB = doorway.RoomB,
            DirectionFromA = doorway.DirectionFromA,
            DirectionFromB = doorway.DirectionFromB,
            PassageArchetypeId = doorway.PassageArchetypeId,
            EndpointTypeA = doorway.EndpointTypeA,
            EndpointTypeB = doorway.EndpointTypeB,
            IsLoopDoorway = doorway.IsLoopDoorway,
        })
    end

    local placedExits = {}
    for _, externalDoorway in ipairs(externalDoorways or {}) do
        table.insert(placedExits, {
            Id = string.format('%s_%d', externalDoorway.RoomId, externalDoorway.Direction),
            Kind = externalDoorway.Kind,
            RoomId = externalDoorway.RoomId,
            Direction = externalDoorway.Direction,
            PassageArchetypeId = externalDoorway.PassageArchetypeId,
            EndpointType = externalDoorway.EndpointType,
        })
    end

    return {
        Doorways = placedDoorways,
        Exits = placedExits,
    }
end

local function buildSearchDistribution(roomIds, rooms)
    local roomIdsByTemplate = {}
    for _, templateId in ipairs(MazeRoomTemplates.getOrderedTemplateIds()) do
        roomIdsByTemplate[templateId] = {}
    end

    local riskRoomIds = {}
    for _, roomId in ipairs(roomIds) do
        local room = rooms[roomId]
        table.insert(roomIdsByTemplate[room.RoomTemplateId], roomId)
        if (room.RiskTier or 0) >= 3 then
            table.insert(riskRoomIds, roomId)
        end
    end

    return {
        RoomIdsByTemplate = roomIdsByTemplate,
        HighRiskRoomIds = riskRoomIds,
    }
end

local function buildLandmarkNodes(roomIds, rooms)
    local nodes = {}
    for _, roomId in ipairs(roomIds) do
        local room = rooms[roomId]
        if (room.LandmarkWeight or 0) >= 3 then
            table.insert(nodes, {
                RoomId = roomId,
                RoomTemplateId = room.RoomTemplateId,
                LandmarkWeight = room.LandmarkWeight,
                Position = room.Position,
            })
        end
    end
    return nodes
end

local function buildAttempt(seed, config)
    local roomCount = math.max(3, config.RoomCount or DEFAULT_ROOM_COUNT)
    local roomSpacing = config.RoomSpacing or 40
    local doorLeafChance = config.DoorLeafChance or DEFAULT_DOOR_LEAF_CHANCE
    local random = Random.new(seed)

    local rooms = {}
    local roomsByAxialKey = {}
    local blockedAxialKeys = {}
    local roomIds = {}
    local edgesByKey = {}
    local frontier = {}
    local frontierIndexByKey = {}

    local function registerRoom(room)
        rooms[room.Id] = room
        roomsByAxialKey[axialKey(room.Grid.Q, room.Grid.R)] = room.Id
        table.insert(roomIds, room.Id)
    end

    local function connectRooms(roomA, directionFromA, roomB)
        local directionFromB = oppositeDirection(directionFromA)

        if
            roomA.Neighbors[directionFromA] == roomB.Id
            and roomB.Neighbors[directionFromB] == roomA.Id
        then
            return
        end

        roomA.Neighbors[directionFromA] = roomB.Id
        roomB.Neighbors[directionFromB] = roomA.Id

        local edgeRoomA, edgeRoomB = roomA, roomB
        local edgeDirectionFromA, edgeDirectionFromB = directionFromA, directionFromB
        if roomA.Id > roomB.Id then
            edgeRoomA, edgeRoomB = roomB, roomA
            edgeDirectionFromA, edgeDirectionFromB = directionFromB, directionFromA
        end

        local edgeKey = string.format('%s|%s', edgeRoomA.Id, edgeRoomB.Id)
        edgesByKey[edgeKey] = {
            RoomA = edgeRoomA.Id,
            RoomB = edgeRoomB.Id,
            DirectionFromA = edgeDirectionFromA,
            DirectionFromB = edgeDirectionFromB,
        }

        removeFrontier(frontier, frontierIndexByKey, roomA.Id, directionFromA)
        removeFrontier(frontier, frontierIndexByKey, roomB.Id, directionFromB)
    end

    local quotas = buildPrefabQuotas(roomCount)

    local startTypeId = pickWeightedType(random, quotas, START_TYPE_IDS)
    if not startTypeId then
        error('MazeBuilder failed to pick a start room prefab', 0)
    end

    local startDefinition = HexRoomPrefabs.getDefinition(startTypeId)
    local startRotation = random:NextInteger(0, 5)
    local startDirections = rotateDirections(startDefinition.OpenDirections, startRotation)
    local startDoorMask = HexRoomPrefabs.computeDoorMask(startDirections)
    local startRoom = createRoom(
        'Room_001',
        0,
        0,
        roomSpacing,
        startTypeId,
        startRotation,
        startDirections,
        startDoorMask
    )
    startRoom.Kind = 'Camp'
    registerRoom(startRoom)
    quotas[startTypeId] -= 1

    local startExitDirection = startDirections[random:NextInteger(1, #startDirections)]
    startRoom.StartExternalDirection = startExitDirection

    do
        local direction = HEX_DIRECTIONS[startExitDirection]
        blockedAxialKeys[axialKey(direction.Q, direction.R)] = true
    end

    for _, directionIndex in ipairs(startDirections) do
        if directionIndex ~= startExitDirection then
            addFrontier(frontier, frontierIndexByKey, startRoom.Id, directionIndex)
        end
    end

    while #roomIds < roomCount do
        local frontierEntry = popRandomFrontier(frontier, frontierIndexByKey, random)
        if not frontierEntry then
            return nil, 'InsufficientExpansionFrontier'
        end

        local sourceRoom = rooms[frontierEntry.RoomId]
        if not sourceRoom then
            continue
        end

        if sourceRoom.Neighbors[frontierEntry.Direction] ~= nil then
            continue
        end

        local direction = HEX_DIRECTIONS[frontierEntry.Direction]
        local targetQ = sourceRoom.Grid.Q + direction.Q
        local targetR = sourceRoom.Grid.R + direction.R
        local targetKey = axialKey(targetQ, targetR)
        local opposite = oppositeDirection(frontierEntry.Direction)

        local existingRoomId = roomsByAxialKey[targetKey]
        if existingRoomId then
            local existingRoom = rooms[existingRoomId]
            if
                existingRoom
                and bit32.band(existingRoom.DoorMask, HexRoomPrefabs.DirectionBitmasks[opposite]) ~= 0
                and existingRoom.Neighbors[opposite] == nil
            then
                connectRooms(sourceRoom, frontierEntry.Direction, existingRoom)
            end
            continue
        end

        local candidate = enumeratePlacementCandidates(
            random,
            quotas,
            rooms,
            roomsByAxialKey,
            blockedAxialKeys,
            targetQ,
            targetR,
            opposite
        )

        if not candidate then
            continue
        end

        local roomId = string.format('Room_%03d', #roomIds + 1)
        local newRoom = createRoom(
            roomId,
            targetQ,
            targetR,
            roomSpacing,
            candidate.TypeId,
            candidate.RotationSteps,
            candidate.OpenDirections,
            candidate.DoorMask
        )
        registerRoom(newRoom)
        quotas[candidate.TypeId] -= 1

        connectRooms(sourceRoom, frontierEntry.Direction, newRoom)

        for _, directionIndex in ipairs(newRoom.OpenDirections) do
            local neighborDirection = HEX_DIRECTIONS[directionIndex]
            local neighborQ = newRoom.Grid.Q + neighborDirection.Q
            local neighborR = newRoom.Grid.R + neighborDirection.R
            local neighborRoomId = roomsByAxialKey[axialKey(neighborQ, neighborR)]

            if neighborRoomId then
                local neighborRoom = rooms[neighborRoomId]
                local oppositeDirectionIndex = OPPOSITE_DIRECTIONS[directionIndex]
                if
                    neighborRoom
                    and bit32.band(
                        neighborRoom.DoorMask,
                        HexRoomPrefabs.DirectionBitmasks[oppositeDirectionIndex]
                    ) ~= 0
                    and neighborRoom.Neighbors[oppositeDirectionIndex] == nil
                    and newRoom.Neighbors[directionIndex] == nil
                then
                    connectRooms(newRoom, directionIndex, neighborRoom)
                end
            elseif newRoom.Neighbors[directionIndex] == nil then
                addFrontier(frontier, frontierIndexByKey, newRoom.Id, directionIndex)
            end
        end
    end

    for _, room in pairs(rooms) do
        room.Kind = 'Loot'
    end

    local campRoomId = startRoom.Id
    local extractionRoomId = selectExtractionRoom(rooms, campRoomId)
    rooms[campRoomId].Kind = 'Camp'
    rooms[extractionRoomId].Kind = 'Extraction'
    finalizeRoomConnectivity(rooms)

    local doorwayKeys = {}
    for edgeKey in pairs(edgesByKey) do
        table.insert(doorwayKeys, edgeKey)
    end
    table.sort(doorwayKeys)

    local doorways = {}
    for _, edgeKey in ipairs(doorwayKeys) do
        local edge = edgesByKey[edgeKey]
        doorways[edgeKey] = {
            Id = edgeKey,
            RoomA = edge.RoomA,
            RoomB = edge.RoomB,
            DirectionFromA = edge.DirectionFromA,
            DirectionFromB = edge.DirectionFromB,
            HasDoorLeaves = random:NextNumber() < doorLeafChance,
        }
    end

    local externalDoorways = {}

    local valid, reason = validateRoomConnections(rooms)
    if not valid then
        return nil, reason
    end

    local mainPath = buildMainPath(rooms, campRoomId, extractionRoomId)
    local loopMetadata = buildLoopMetadata(rooms, doorways, campRoomId)
    if loopMetadata.LoopCount < 1 then
        return nil, 'LoopingFacilityRequired'
    end

    local assignmentMetadata =
        assignRoomTemplates(rooms, campRoomId, extractionRoomId, mainPath, loopMetadata)

    enrichDoorwayMetadata(rooms, doorways, loopMetadata)
    local orderedRoomIds = sortedRoomIds(rooms)
    local macroGraph =
        buildMacroGraph(orderedRoomIds, rooms, mainPath, loopMetadata, assignmentMetadata)

    return {
        Seed = seed,
        Rooms = rooms,
        Doorways = doorways,
        MainPath = mainPath,
        CampRoomId = campRoomId,
        ExtractionRoomId = extractionRoomId,
        ExternalDoorways = externalDoorways,
        MacroGraph = macroGraph,
        PlacedRooms = buildPlacedRooms(orderedRoomIds, rooms),
        PlacedPassages = buildPlacedPassages(doorways, externalDoorways),
        SearchDistribution = buildSearchDistribution(orderedRoomIds, rooms),
        LandmarkNodes = buildLandmarkNodes(orderedRoomIds, rooms),
    }
end

function MazeBuilder.build(seed, config)
    config = config or {}

    local maxAttempts = math.max(1, config.MaxGenerationAttempts or DEFAULT_MAX_ATTEMPTS)
    for attempt = 1, maxAttempts do
        local attemptSeed = seed + ((attempt - 1) * 131)
        local maze, reason = buildAttempt(attemptSeed, config)
        if maze then
            return maze
        end

        if attempt == maxAttempts then
            error(
                string.format(
                    'MazeBuilder failed after %d attempts (%s)',
                    maxAttempts,
                    tostring(reason)
                ),
                0
            )
        end
    end
end

return MazeBuilder
