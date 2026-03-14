local MazeBuilder = {}

local function createRoom(roomId, kind, position)
    return {
        Id = roomId,
        Kind = kind,
        Position = position,
    }
end

function MazeBuilder.build(seed, config)
    local mainPathRooms = config.MainPathRooms or 4
    local maxBranches = config.MaxBranches or 0
    local roomSpacing = config.RoomSpacing or 40
    local random = Random.new(seed)

    local rooms = {}
    local mainPath = {}

    for index = 0, mainPathRooms do
        local roomId = string.format('Main_%d', index)
        local kind = 'Loot'

        if index == 0 then
            kind = 'Camp'
        elseif index == mainPathRooms then
            kind = 'Extraction'
        end

        local room = createRoom(roomId, kind, Vector3.new(index * roomSpacing, 0, 0))
        rooms[roomId] = room
        table.insert(mainPath, roomId)
    end

    for branchIndex = 1, maxBranches do
        local anchorIndex = math.clamp(branchIndex, 1, math.max(1, mainPathRooms - 1))
        local branchRoomId = string.format('Branch_%d', branchIndex)
        local branchDirection = random:NextInteger(0, 1) == 0 and -1 or 1
        local branchPosition =
            Vector3.new(anchorIndex * roomSpacing, 0, branchDirection * roomSpacing)

        rooms[branchRoomId] = createRoom(branchRoomId, 'Loot', branchPosition)
    end

    return {
        Seed = seed,
        Rooms = rooms,
        MainPath = mainPath,
        CampRoomId = mainPath[1],
        ExtractionRoomId = mainPath[#mainPath],
    }
end

return MazeBuilder
