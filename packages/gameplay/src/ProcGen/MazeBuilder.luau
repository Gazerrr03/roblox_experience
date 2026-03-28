local MazeBuilder = {}

local HexRoomPrefabs = require(script.Parent.HexRoomPrefabs)
local MazeRoomArchetypes = require(script.Parent.MazeRoomArchetypes)

local HEX_DIRECTIONS = {
    { Q = 1, R = 0 },
    { Q = 1, R = -1 },
    { Q = 0, R = -1 },
    { Q = -1, R = 0 },
    { Q = -1, R = 1 },
    { Q = 0, R = 1 },
}

local OPPOSITE_DIRECTIONS = { 4, 5, 6, 1, 2, 3 }
local DIRECTION_BITMASKS = { 1, 2, 4, 8, 16, 32 }

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
local DEFAULT_EXIT_MIN = 2
local DEFAULT_EXIT_MAX = 4
local DEFAULT_DOOR_LEAF_CHANCE = 0.6
local DEFAULT_MAX_ATTEMPTS = 200

local function oppositeDirection(directionIndex)
    return OPPOSITE_DIRECTIONS[directionIndex]
end

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

local function axialKey(q, r)
    return bit32.bor(bit32.lshift(q, 16), bit32.band(r, 0xFFFF))
end

local function axialToWorld(q, r, roomSpacing)
    local sqrt3 = math.sqrt(3)
    local x = roomSpacing * (sqrt3 * q + (sqrt3 / 2) * r)
    local z = roomSpacing * ((3 / 2) * r)
    return Vector3.new(x, 0, z)
end

local function createRoom(roomId, q, r, roomSpacing, typeId, rotationSteps, openDirections)
    local definition = HexRoomPrefabs.getDefinition(typeId)
    local doorMask = HexRoomPrefabs.computeDoorMask(openDirections)

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

local function canPlaceVariant(rooms, roomsByAxialKey, blockedAxialKeys, q, r, openDirections)
    local positionKey = axialKey(q, r)
    if roomsByAxialKey[positionKey] or blockedAxialKeys[positionKey] then
        return false
    end

    local openMask = HexRoomPrefabs.computeDoorMask(openDirections)
    for directionIndex, direction in ipairs(HEX_DIRECTIONS) do
        local neighborQ = q + direction.Q
        local neighborR = r + direction.R
        local neighborRoomId = roomsByAxialKey[axialKey(neighborQ, neighborR)]
        if not neighborRoomId then
            continue
        end

        local neighbor = rooms[neighborRoomId]
        local opposite = OPPOSITE_DIRECTIONS[directionIndex]
        local selfHasDoor = bit32.band(openMask, DIRECTION_BITMASKS[directionIndex]) ~= 0
        local neighborHasDoor = bit32.band(neighbor.DoorMask, DIRECTION_BITMASKS[opposite]) ~= 0

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

    for _, typeId in ipairs(RATIO_TYPE_ORDER) do
        if (quotas[typeId] or 0) <= 0 then
            continue
        end

        local definition = HexRoomPrefabs.getDefinition(typeId)
        if not definition then
            continue
        end

        for rotationSteps = 0, 5 do
            local openDirections = rotateDirections(definition.OpenDirections, rotationSteps)
            if not table.find(openDirections, requiredDirection) then
                continue
            end

            if
                canPlaceVariant(
                    rooms,
                    roomsByAxialKey,
                    blockedAxialKeys,
                    targetQ,
                    targetR,
                    openDirections
                )
            then
                table.insert(candidates, {
                    TypeId = typeId,
                    RotationSteps = rotationSteps,
                    OpenDirections = openDirections,
                    Weight = quotas[typeId],
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

local function collectExternalStubs(rooms)
    local stubs = {}

    for roomId, room in pairs(rooms) do
        for _, directionIndex in ipairs(room.OpenDirections) do
            if room.Neighbors[directionIndex] == nil then
                table.insert(stubs, {
                    RoomId = roomId,
                    Direction = directionIndex,
                })
            end
        end
    end

    return stubs
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

        for _, neighborRoomId in pairs(room.Neighbors) do
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
        for _, neighborRoomId in pairs(room.Neighbors) do
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

local function addExitDirection(room, directionIndex)
    if table.find(room.ExitDirections, directionIndex) then
        return
    end

    table.insert(room.ExitDirections, directionIndex)
    table.sort(room.ExitDirections)
end

local function assignRoomArchetypes(rooms)
    for _, room in pairs(rooms) do
        local archetype = MazeRoomArchetypes.classifyRoom(room)
        room.ArchetypeId = archetype.Id
        room.AuthoringAssetId = archetype.AuthoringAssetId
        room.SupportsExternalShellModel = archetype.SupportsExternalShellModel == true
        room.VisualLanguage = archetype.VisualLanguage
    end
end

local function validateRoomConnections(rooms)
    for roomId, room in pairs(rooms) do
        local exitDirectionMask = 0
        for _, directionIndex in ipairs(room.ExitDirections or {}) do
            exitDirectionMask = bit32.bor(exitDirectionMask, DIRECTION_BITMASKS[directionIndex])
        end

        for directionIndex, neighborRoomId in pairs(room.Neighbors) do
            if bit32.band(room.DoorMask, DIRECTION_BITMASKS[directionIndex]) == 0 then
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
            if bit32.band(neighbor.DoorMask, DIRECTION_BITMASKS[opposite]) == 0 then
                return false,
                    string.format('NeighborClosedMirrorEdge(%s:%s)', roomId, neighborRoomId)
            end
        end

        for _, directionIndex in ipairs(room.OpenDirections) do
            local neighborRoomId = room.Neighbors[directionIndex]
            if
                neighborRoomId == nil
                and bit32.band(exitDirectionMask, DIRECTION_BITMASKS[directionIndex]) == 0
            then
                return false, string.format('UnclassifiedOpenEdge(%s:%d)', roomId, directionIndex)
            end
        end

        for directionIndex = 1, 6 do
            local directionBit = DIRECTION_BITMASKS[directionIndex]
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

local function buildAttempt(seed, config)
    local roomCount = math.max(3, config.RoomCount or DEFAULT_ROOM_COUNT)
    local roomSpacing = config.RoomSpacing or 40
    local doorLeafChance = config.DoorLeafChance or DEFAULT_DOOR_LEAF_CHANCE
    local exitMin = math.max(0, config.ExitMin or DEFAULT_EXIT_MIN)
    local exitMax = math.max(exitMin, config.ExitMax or DEFAULT_EXIT_MAX)
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
    local startRoom =
        createRoom('Room_001', 0, 0, roomSpacing, startTypeId, startRotation, startDirections)
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
                and bit32.band(existingRoom.DoorMask, DIRECTION_BITMASKS[opposite]) ~= 0
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
            candidate.OpenDirections
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
                    and bit32.band(neighborRoom.DoorMask, DIRECTION_BITMASKS[oppositeDirectionIndex])
                        ~= 0
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

    local allExternalStubs = collectExternalStubs(rooms)
    local selectedExitStubs = {}

    for _, stub in ipairs(allExternalStubs) do
        if not (stub.RoomId == startRoom.Id and stub.Direction == startExitDirection) then
            table.insert(selectedExitStubs, stub)
        end
    end

    if #selectedExitStubs < exitMin or #selectedExitStubs > exitMax then
        return nil, string.format('ExitCountOutOfRange(%d)', #selectedExitStubs)
    end

    for _, room in pairs(rooms) do
        room.Kind = 'Loot'
        room.ExitDirections = {}
    end

    addExitDirection(startRoom, startExitDirection)

    for _, exitStub in ipairs(selectedExitStubs) do
        local room = rooms[exitStub.RoomId]
        if room then
            addExitDirection(room, exitStub.Direction)
        end
    end

    local campRoomId = startRoom.Id
    local extractionRoomId = selectExtractionRoom(rooms, campRoomId)
    rooms[campRoomId].Kind = 'Camp'
    rooms[extractionRoomId].Kind = 'Extraction'
    assignRoomArchetypes(rooms)

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

    local externalDoorways = {
        {
            RoomId = campRoomId,
            Direction = startExitDirection,
            Kind = 'Start',
        },
    }

    for _, exitStub in ipairs(selectedExitStubs) do
        table.insert(externalDoorways, {
            RoomId = exitStub.RoomId,
            Direction = exitStub.Direction,
            Kind = 'Exit',
        })
    end

    table.sort(externalDoorways, function(left, right)
        if left.RoomId ~= right.RoomId then
            return left.RoomId < right.RoomId
        end
        return left.Direction < right.Direction
    end)

    local valid, reason = validateRoomConnections(rooms)
    if not valid then
        return nil, reason
    end

    return {
        Seed = seed,
        Rooms = rooms,
        Doorways = doorways,
        MainPath = buildMainPath(rooms, campRoomId, extractionRoomId),
        CampRoomId = campRoomId,
        ExtractionRoomId = extractionRoomId,
        ExternalDoorways = externalDoorways,
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
