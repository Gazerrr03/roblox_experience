local RoleAllocator = {}

function RoleAllocator.assign(players, roleDefinitions)
    table.sort(players, function(left, right)
        return left.UserId < right.UserId
    end)

    local assignments = {}

    for index, player in ipairs(players) do
        local roleDefinition = roleDefinitions[((index - 1) % #roleDefinitions) + 1]

        assignments[player.UserId] = {
            UserId = player.UserId,
            Name = player.DisplayName,
            RoleId = roleDefinition.Id,
            PublicRole = roleDefinition.PublicRole,
            PrivateRole = roleDefinition.PrivateRole,
            PermissionTags = table.clone(roleDefinition.PermissionTags),
        }
    end

    return assignments
end

return RoleAllocator
