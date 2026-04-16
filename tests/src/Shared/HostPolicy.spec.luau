return function()
    local ReplicatedStorage = game:GetService('ReplicatedStorage')
    local shared = require(ReplicatedStorage:WaitForChild('Packages'):WaitForChild('Shared'))
    local HostPolicy = shared.Util.HostPolicy

    assert(HostPolicy.assignHost({}, nil) == nil, 'Empty waiting roster should not produce a host')
    assert(
        HostPolicy.assignHost({ 200 }, nil) == 200,
        'The first waiting player should become host'
    )
    assert(
        HostPolicy.assignHost({ 200, 100 }, 200) == 200,
        'The current host should stay host while still present'
    )
    assert(
        HostPolicy.assignHost({ 100, 300 }, 200) == 100,
        'When the host leaves, the next waiting player should be promoted'
    )
    assert(
        HostPolicy.isValidHost(100, { 200, 100 }) == true,
        'A host should be valid while present in the waiting roster'
    )
    assert(
        HostPolicy.isValidHost(100, { 200, 300 }) == false,
        'A host should be invalid once removed from the waiting roster'
    )
end
