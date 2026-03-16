return function()
    local ReplicatedStorage = game:GetService('ReplicatedStorage')
    local gameplay = require(ReplicatedStorage:WaitForChild('Packages'):WaitForChild('Gameplay'))
    local config = {
        MainPathRooms = 4,
        MaxBranches = 2,
        RoomSpacing = 40,
        DoorLeafChance = 0.6,
    }
    local maze = gameplay.ProcGen.MazeBuilder.build(12345, config)
    local secondMaze = gameplay.ProcGen.MazeBuilder.build(12345, config)

    assert(maze.Rooms[maze.CampRoomId] ~= nil, 'Maze should always have a camp room')
    assert(maze.Rooms[maze.ExtractionRoomId] ~= nil, 'Maze should always have an extraction room')
    assert(#maze.MainPath == 5, 'Main path should include camp plus requested room count')

    local extractionRoom = maze.Rooms[maze.ExtractionRoomId]
    assert(extractionRoom.Kind == 'Extraction', 'Extraction room should be tagged correctly')

    local roomCount = 0
    local deadEnds = 0
    local openSixRooms = 0
    for roomId, room in pairs(maze.Rooms) do
        roomCount += 1
        assert(room.DoorCount > 0, string.format('Room %s should never have zero doors', roomId))
        assert(
            room.DoorMask > 0,
            string.format('Room %s should always expose door mask bits', roomId)
        )

        if room.DoorCount == 1 then
            deadEnds += 1
        elseif room.DoorCount == 6 then
            openSixRooms += 1
        end

        for directionIndex, neighborRoomId in pairs(room.Neighbors) do
            local oppositeDirection = ((directionIndex + 2) % 6) + 1
            local neighborRoom = maze.Rooms[neighborRoomId]
            assert(
                neighborRoom and neighborRoom.Neighbors[oppositeDirection] == roomId,
                string.format('Door symmetry should hold between %s and %s', roomId, neighborRoomId)
            )
        end

        if room.DoorCount ~= 5 then
            assert(
                type(room.PrefabTypeId) == 'string' and string.sub(room.PrefabTypeId, 1, 1) == 'T',
                string.format('Room %s should map to T-prefab classification', roomId)
            )
        end
    end

    assert(deadEnds >= 1, 'Maze should preserve at least one dead-end room')
    assert(
        openSixRooms <= math.max(1, math.floor(roomCount * 0.15)),
        'Six-door hub rooms should stay low frequency'
    )

    local doorwayCount = 0
    local doorwayLeaves = 0
    for doorwayId, doorway in pairs(maze.Doorways) do
        doorwayCount += 1
        if doorway.HasDoorLeaves then
            doorwayLeaves += 1
        end

        local roomA = maze.Rooms[doorway.RoomA]
        local roomB = maze.Rooms[doorway.RoomB]
        assert(roomA and roomB, string.format('Doorway %s should point to valid rooms', doorwayId))
        assert(
            roomA.Neighbors[doorway.DirectionFromA] == doorway.RoomB,
            string.format('Doorway %s should align with room A neighbor map', doorwayId)
        )
        assert(
            roomB.Neighbors[doorway.DirectionFromB] == doorway.RoomA,
            string.format('Doorway %s should align with room B neighbor map', doorwayId)
        )
    end

    assert(doorwayCount > 0, 'Maze should expose at least one doorway')
    assert(doorwayLeaves > 0, 'Maze should spawn at least some door leaves')
    assert(doorwayLeaves < doorwayCount, 'Maze should keep some doorway openings without leaves')

    for doorwayId, doorway in pairs(maze.Doorways) do
        local secondDoorway = secondMaze.Doorways[doorwayId]
        assert(secondDoorway ~= nil, 'Maze doorway keys should be deterministic for same seed')
        assert(
            doorway.HasDoorLeaves == secondDoorway.HasDoorLeaves,
            'Door leaf randomization should be deterministic for same seed'
        )
    end
end
