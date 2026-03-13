return function()
    local ReplicatedStorage = game:GetService('ReplicatedStorage')
    local gameplay = require(ReplicatedStorage:WaitForChild('Packages'):WaitForChild('Gameplay'))
    local maze = gameplay.ProcGen.MazeBuilder.build(12345, {
        MainPathRooms = 4,
        MaxBranches = 2,
        RoomSpacing = 40,
    })

    assert(maze.Rooms[maze.CampRoomId] ~= nil, 'Maze should always have a camp room')
    assert(maze.Rooms[maze.ExtractionRoomId] ~= nil, 'Maze should always have an extraction room')
    assert(#maze.MainPath == 5, 'Main path should include camp plus requested room count')

    local extractionRoom = maze.Rooms[maze.ExtractionRoomId]
    assert(extractionRoom.Kind == 'Extraction', 'Extraction room should be tagged correctly')
end

