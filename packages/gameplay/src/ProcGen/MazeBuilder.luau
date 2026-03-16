local MazeBuilder = {}

local HEX_DIRECTIONS = {
    { Q = 1, R = 0 },
    { Q = 1, R = -1 },
    { Q = 0, R = -1 },
    { Q = -1, R = 0 },
    { Q = -1, R = 1 },
    { Q = 0, R = 1 },
}

local BRANCH_DIRECTIONS = { 2, 3, 5, 6 }
local DEFAULT_DOOR_LEAF_CHANCE = 0.6
local DEFAULT_TARGET_AVG_DEGREE = 2.4
local PROB_AVOID_SIX_DOOR_HUB = 0.85
local PROB_ADD_CANDIDATE_EDGE = 0.7

local function oppositeDirection(directionIndex)
    return ((directionIndex + 2) % 6) + 1
end

local function axialKey(q, r)
    return string.format('%d:%d', q, r)
end

local function axialToWorld(q, r, roomSpacing)
    local sqrt3 = math.sqrt(3)
    local x = roomSpacing * (sqrt3 * q + (sqrt3 / 2) * r)
    local z = roomSpacing * ((3 / 2) * r)
    return Vector3.new(x, 0, z)
end

local function createRoom(roomId, kind, q, r, roomSpacing)
    return {
        Id = roomId,
        Kind = kind,
        Grid = {
            Q = q,
            R = r,
        },
        Position = axialToWorld(q, r, roomSpacing),
        DoorMask = 0,
        DoorCount = 0,
        DoorDirections = {},
        Neighbors = {},
        PrefabId = 'Hex_DeadEnd',
    }
end

local function setDoorDirection(room, directionIndex, neighborRoomId)
    if room.Neighbors[directionIndex] ~= nil then
        return false
    end

    room.Neighbors[directionIndex] = neighborRoomId
    room.DoorMask = bit32.bor(room.DoorMask, bit32.lshift(1, directionIndex - 1))
    room.DoorCount += 1
    table.insert(room.DoorDirections, directionIndex)
    return true
end

local function classifyRoomPrefab(room)
    local degree = room.DoorCount

    if degree <= 1 then
        return 'Hex_DeadEnd'
    end

    if degree == 2 then
        local firstDirection = room.DoorDirections[1]
        local secondDirection = room.DoorDirections[2]
        if oppositeDirection(firstDirection) == secondDirection then
            return 'Hex_Straight'
        end

        return 'Hex_Bend'
    end

    if degree == 3 then
        return 'Hex_T'
    end

    if degree == 4 then
        return 'Hex_Cross4'
    end

    if degree == 5 then
        return 'Hex_Cross5'
    end

    return 'Hex_Open6'
end

local function shuffleInPlace(list, random)
    for index = #list, 2, -1 do
        local swapIndex = random:NextInteger(1, index)
        list[index], list[swapIndex] = list[swapIndex], list[index]
    end
end

function MazeBuilder.build(seed, config)
    local mainPathRooms = math.max(2, config.MainPathRooms or 4)
    local maxBranches = math.max(0, config.MaxBranches or 0)
    local roomSpacing = config.RoomSpacing or 40
    local doorLeafChance = config.DoorLeafChance or DEFAULT_DOOR_LEAF_CHANCE
    local targetAverageDegree = config.TargetAverageDegree or DEFAULT_TARGET_AVG_DEGREE
    local random = Random.new(seed)

    local rooms = {}
    local roomsByAxialKey = {}
    local mainPath = {}
    local edgesByKey = {}
    local edgeCount = 0
    local roomIds = {}
    local branchCount = 0

    local function registerRoom(room)
        rooms[room.Id] = room
        roomsByAxialKey[axialKey(room.Grid.Q, room.Grid.R)] = room.Id
        table.insert(roomIds, room.Id)
    end

    local function addEdge(roomIdA, directionFromA, roomIdB)
        local roomA = rooms[roomIdA]
        local roomB = rooms[roomIdB]
        if not roomA or not roomB then
            return false
        end

        local directionFromB = oppositeDirection(directionFromA)
        local edgeKey = roomIdA < roomIdB and string.format('%s|%s', roomIdA, roomIdB)
            or string.format('%s|%s', roomIdB, roomIdA)
        if edgesByKey[edgeKey] then
            return false
        end

        setDoorDirection(roomA, directionFromA, roomIdB)
        setDoorDirection(roomB, directionFromB, roomIdA)

        edgesByKey[edgeKey] = {
            RoomA = roomIdA,
            RoomB = roomIdB,
            DirectionFromA = directionFromA,
            DirectionFromB = directionFromB,
        }
        edgeCount += 1
        return true
    end

    for index = 0, mainPathRooms do
        local roomId = string.format('Main_%d', index)
        local kind = 'Loot'
        if index == 0 then
            kind = 'Camp'
        elseif index == mainPathRooms then
            kind = 'Extraction'
        end

        local room = createRoom(roomId, kind, index, 0, roomSpacing)
        registerRoom(room)
        table.insert(mainPath, roomId)

        if index > 0 then
            addEdge(mainPath[index], 1, roomId)
        end
    end

    for branchIndex = 1, maxBranches do
        local anchorIndex = math.clamp(branchIndex, 1, math.max(1, mainPathRooms - 1))
        local anchorRoomId = mainPath[anchorIndex + 1]
        local anchorRoom = rooms[anchorRoomId]
        if not anchorRoom then
            continue
        end

        local candidateDirections = table.clone(BRANCH_DIRECTIONS)
        shuffleInPlace(candidateDirections, random)

        local branchRoom = nil
        local branchDirection = nil
        for _, directionIndex in ipairs(candidateDirections) do
            local direction = HEX_DIRECTIONS[directionIndex]
            local nextQ = anchorRoom.Grid.Q + direction.Q
            local nextR = anchorRoom.Grid.R + direction.R
            if not roomsByAxialKey[axialKey(nextQ, nextR)] then
                branchCount += 1
                branchRoom = createRoom(
                    string.format('Branch_%d', branchCount),
                    'Loot',
                    nextQ,
                    nextR,
                    roomSpacing
                )
                branchDirection = directionIndex
                break
            end
        end

        if branchRoom and branchDirection then
            registerRoom(branchRoom)
            addEdge(anchorRoomId, branchDirection, branchRoom.Id)
        end
    end

    local candidateEdges = {}
    for _, roomId in ipairs(roomIds) do
        local room = rooms[roomId]
        for directionIndex, direction in ipairs(HEX_DIRECTIONS) do
            local neighborQ = room.Grid.Q + direction.Q
            local neighborR = room.Grid.R + direction.R
            local neighborRoomId = roomsByAxialKey[axialKey(neighborQ, neighborR)]
            if neighborRoomId and roomId < neighborRoomId then
                local edgeKey = string.format('%s|%s', roomId, neighborRoomId)
                if not edgesByKey[edgeKey] then
                    table.insert(candidateEdges, {
                        RoomA = roomId,
                        RoomB = neighborRoomId,
                        DirectionFromA = directionIndex,
                    })
                end
            end
        end
    end

    shuffleInPlace(candidateEdges, random)

    local function currentAverageDegree()
        return (#roomIds > 0) and ((2 * edgeCount) / #roomIds) or 0
    end

    for _, candidate in ipairs(candidateEdges) do
        if currentAverageDegree() >= targetAverageDegree then
            break
        end

        local roomA = rooms[candidate.RoomA]
        local roomB = rooms[candidate.RoomB]
        if
            (candidate.RoomA == mainPath[1] or candidate.RoomA == mainPath[#mainPath])
            and roomA.DoorCount <= 1
        then
            continue
        end
        if
            (candidate.RoomB == mainPath[1] or candidate.RoomB == mainPath[#mainPath])
            and roomB.DoorCount <= 1
        then
            continue
        end
        if roomA.DoorCount >= 6 or roomB.DoorCount >= 6 then
            continue
        end

        if roomA.DoorCount >= 5 and random:NextNumber() < PROB_AVOID_SIX_DOOR_HUB then
            continue
        end
        if roomB.DoorCount >= 5 and random:NextNumber() < PROB_AVOID_SIX_DOOR_HUB then
            continue
        end

        if random:NextNumber() <= PROB_ADD_CANDIDATE_EDGE then
            addEdge(candidate.RoomA, candidate.DirectionFromA, candidate.RoomB)
        end
    end

    local doorways = {}
    local doorwayKeys = {}
    for edgeKey in pairs(edgesByKey) do
        table.insert(doorwayKeys, edgeKey)
    end
    table.sort(doorwayKeys)

    for _, edgeKey in ipairs(doorwayKeys) do
        local edge = edgesByKey[edgeKey]
        local hasDoorLeaves = random:NextNumber() < doorLeafChance
        doorways[edgeKey] = {
            Id = edgeKey,
            RoomA = edge.RoomA,
            RoomB = edge.RoomB,
            DirectionFromA = edge.DirectionFromA,
            DirectionFromB = edge.DirectionFromB,
            HasDoorLeaves = hasDoorLeaves,
        }
    end

    for _, room in pairs(rooms) do
        table.sort(room.DoorDirections)
        room.PrefabId = classifyRoomPrefab(room)
    end

    return {
        Seed = seed,
        Rooms = rooms,
        Doorways = doorways,
        MainPath = mainPath,
        CampRoomId = mainPath[1],
        ExtractionRoomId = mainPath[#mainPath],
    }
end

return MazeBuilder
