return function()
    local ReplicatedStorage = game:GetService('ReplicatedStorage')
    local shared = require(ReplicatedStorage:WaitForChild('Packages'):WaitForChild('Shared'))

    local roster = {
        [10] = {
            UserId = 10,
            Name = 'Alpha',
            PublicRole = 'Crew',
            PrivateRole = 'Lead',
            PermissionTags = { 'StartRun' },
        },
        [20] = {
            UserId = 20,
            Name = 'Bravo',
            PublicRole = 'Crew',
            PrivateRole = 'Runner',
            PermissionTags = { 'DepositLoot' },
        },
    }

    local filtered = shared.Util.Visibility.filterRoster(roster, 10)
    assert(filtered[10].PrivateRole == 'Lead', 'Recipient should keep self private role')
    assert(filtered[20].PrivateRole == nil, 'Other private roles should be hidden')
end
