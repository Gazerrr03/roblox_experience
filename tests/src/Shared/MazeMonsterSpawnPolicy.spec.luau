return function()
    local ReplicatedStorage = game:GetService('ReplicatedStorage')
    local gameplay = require(ReplicatedStorage:WaitForChild('Packages'):WaitForChild('Gameplay'))
    local policy = gameplay.Monsters.MazeMonsterSpawnPolicy

    local roomById = {
        A = {
            Neighbors = {
                [1] = 'B',
                [2] = 'C',
            },
        },
        B = {
            Neighbors = {
                [4] = 'A',
            },
        },
        C = {
            Neighbors = {
                [5] = 'A',
            },
        },
        D = {
            Neighbors = {
                [1] = 'B',
            },
        },
    }

    local excludedRoomIds = policy.buildInitialSpawnExcludedRoomIds(roomById, 'A')
    assert(excludedRoomIds.A == true, 'Camp room should be excluded from the monster spawn buffer')
    assert(
        excludedRoomIds.B == true and excludedRoomIds.C == true,
        'Rooms adjacent to camp should be excluded from the monster spawn buffer'
    )
    assert(
        excludedRoomIds.D ~= true,
        'Rooms beyond the immediate entrance buffer should remain eligible'
    )

    local initialPatrolIndex, spawnRoomId = policy.selectInitialPatrolIndex(
        { 'A', 'B', 'C', 'D' },
        {
            A = {
                PatrolAnchors = {},
            },
            B = {
                PatrolAnchors = { 'B-anchor' },
            },
            C = {
                PatrolAnchors = { 'C-anchor' },
            },
            D = {
                PatrolAnchors = { 'D-anchor' },
            },
        },
        roomById,
        'A'
    )

    assert(
        initialPatrolIndex == 3,
        'Initial patrol index should skip camp-adjacent anchors and pick the first safe room'
    )
    assert(
        spawnRoomId == 'D',
        'Initial monster spawn should resolve to a room outside the entrance safety buffer'
    )
end
