return function()
    local ReplicatedStorage = game:GetService('ReplicatedStorage')
    local gameplay = require(ReplicatedStorage:WaitForChild('Packages'):WaitForChild('Gameplay'))
    local allocator = gameplay.Roles.RoleAllocator
    local roleDefinitions = gameplay.Config.Roles

    local players = {
        { UserId = 30, DisplayName = 'Charlie' },
        { UserId = 10, DisplayName = 'Alpha' },
        { UserId = 40, DisplayName = 'Delta' },
        { UserId = 20, DisplayName = 'Bravo' },
        { UserId = 50, DisplayName = 'Echo' },
    }

    local assignments = allocator.assign(players, roleDefinitions)

    assert(
        assignments[10].RoleId == roleDefinitions[1].Id,
        'Lowest user id should receive the first role'
    )
    assert(
        assignments[20].RoleId == roleDefinitions[2].Id,
        'Assignments should follow ascending user ids'
    )
    assert(
        assignments[30].RoleId == roleDefinitions[3].Id,
        'Assignments should continue through the role list'
    )
    assert(
        assignments[40].RoleId == roleDefinitions[4].Id,
        'Assignments should reach the final configured role'
    )
    assert(
        assignments[50].RoleId == roleDefinitions[1].Id,
        'Assignments should wrap when players exceed role count'
    )
    assert(assignments[10].Name == 'Alpha', 'Assignments should preserve player display names')

    assignments[10].PermissionTags[1] = 'MutatedTag'
    assert(
        roleDefinitions[1].PermissionTags[1] ~= 'MutatedTag',
        'Assignments should clone permission tags instead of mutating config'
    )
end
