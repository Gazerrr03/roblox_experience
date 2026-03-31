local EXPECTED_PREFAB_COUNTS_20 = {
    T1 = 4,
    T2 = 5,
    T3 = 2,
    T4 = 2,
    T5 = 3,
    T6 = 2,
    T7 = 1,
    T8 = 1,
}

return function()
    local ReplicatedStorage = game:GetService('ReplicatedStorage')
    local gameplay = require(ReplicatedStorage:WaitForChild('Packages'):WaitForChild('Gameplay'))
    local config = {
        RoomCount = 20,
        ExitMin = 2,
        ExitMax = 4,
        RoomSpacing = 40,
        DoorLeafChance = 0.6,
    }

    local maze = gameplay.ProcGen.MazeBuilder.build(12345, config)
    local secondMaze = gameplay.ProcGen.MazeBuilder.build(12345, config)

    assert(maze.Rooms[maze.CampRoomId] ~= nil, 'Maze should always have a camp room')
    assert(maze.Rooms[maze.ExtractionRoomId] ~= nil, 'Maze should always have an extraction room')
    assert(maze.CampRoomId ~= maze.ExtractionRoomId, 'Camp and extraction rooms should differ')

    local roomCount = 0
    local deadEnds = 0
    local openSixRooms = 0
    local prefabCounts = {}
    local cavePocketCount = 0

    for roomId, room in pairs(maze.Rooms) do
        roomCount += 1
        assert(room.DoorCount > 0, string.format('Room %s should never have zero doors', roomId))
        assert(
            room.DoorMask > 0,
            string.format('Room %s should always expose door mask bits', roomId)
        )
        assert(
            type(room.PrefabTypeId) == 'string' and string.sub(room.PrefabTypeId, 1, 1) == 'T',
            string.format('Room %s should map to T1-T8 prefab taxonomy', roomId)
        )
        assert(
            type(room.ArchetypeId) == 'string',
            string.format('Room %s should expose an archetype id', roomId)
        )
        assert(
            type(room.AuthoringAssetId) == 'string',
            string.format('Room %s should expose an authoring asset id', roomId)
        )

        prefabCounts[room.PrefabTypeId] = (prefabCounts[room.PrefabTypeId] or 0) + 1
        if room.ArchetypeId == 'CavePocket' then
            cavePocketCount += 1
        end

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

    assert(roomCount == config.RoomCount, 'Maze should honor configured room count')
    assert(deadEnds >= 1, 'Maze should preserve at least one dead-end room')
    assert(cavePocketCount >= 1, 'Maze should expose at least one cave-like room archetype')
    assert(
        openSixRooms <= math.max(1, math.floor(roomCount * 0.15)),
        'Six-door hub rooms should stay low frequency'
    )

    local prefabTypeIds = {}
    for prefabTypeId in pairs(EXPECTED_PREFAB_COUNTS_20) do
        table.insert(prefabTypeIds, prefabTypeId)
    end
    table.sort(prefabTypeIds)

    for _, prefabTypeId in ipairs(prefabTypeIds) do
        local expectedCount = EXPECTED_PREFAB_COUNTS_20[prefabTypeId]
        local actualCount = prefabCounts[prefabTypeId] or 0
        assert(
            actualCount == expectedCount,
            string.format(
                '%s count mismatch: expected %d, got %d',
                prefabTypeId,
                expectedCount,
                actualCount
            )
        )
    end

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

    local externalDoorways = maze.ExternalDoorways or {}
    local startExits = 0
    local regularExits = 0
    local seenExternalKeys = {}

    for _, external in ipairs(externalDoorways) do
        local room = maze.Rooms[external.RoomId]
        assert(room ~= nil, 'External doorway should reference an existing room')

        local key = string.format('%s:%d', external.RoomId, external.Direction)
        assert(not seenExternalKeys[key], 'External doorway entries should not duplicate')
        seenExternalKeys[key] = true

        if external.Kind == 'Start' then
            startExits += 1
            assert(
                external.RoomId == maze.CampRoomId,
                'Start external doorway should always belong to the camp room'
            )
            assert(
                room.StartExternalDirection == external.Direction,
                'Camp room start external direction should match exported external doorway'
            )
        else
            regularExits += 1
        end

        assert(
            room.Neighbors[external.Direction] == nil,
            'External doorway direction should not be connected to another room'
        )
    end

    assert(startExits == 1, 'Maze should expose exactly one start external doorway')
    assert(
        regularExits >= config.ExitMin and regularExits <= config.ExitMax,
        'Maze should keep regular external exits inside configured range'
    )

    assert(
        type(maze.MainPath) == 'table' and #maze.MainPath >= 2,
        'Maze should provide camp->extraction path'
    )
    assert(maze.MainPath[1] == maze.CampRoomId, 'Main path should start at camp room')
    assert(
        maze.MainPath[#maze.MainPath] == maze.ExtractionRoomId,
        'Main path should terminate at extraction room'
    )

    for doorwayId, doorway in pairs(maze.Doorways) do
        local secondDoorway = secondMaze.Doorways[doorwayId]
        assert(secondDoorway ~= nil, 'Maze doorway keys should be deterministic for same seed')
        assert(
            doorway.HasDoorLeaves == secondDoorway.HasDoorLeaves,
            'Door leaf randomization should be deterministic for same seed'
        )
    end

    for roomId, room in pairs(maze.Rooms) do
        local secondRoom = secondMaze.Rooms[roomId]
        assert(secondRoom ~= nil, 'Room IDs should be deterministic for same seed')
        assert(
            room.PrefabTypeId == secondRoom.PrefabTypeId,
            'Prefab assignment should be deterministic for same seed'
        )
        assert(
            room.DoorMask == secondRoom.DoorMask,
            'Door mask should be deterministic for same seed'
        )
        assert(
            room.ArchetypeId == secondRoom.ArchetypeId,
            'Room archetype selection should be deterministic for same seed'
        )
    end
end
