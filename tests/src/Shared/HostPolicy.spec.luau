return function()
    local ReplicatedStorage = game:GetService('ReplicatedStorage')
    local Packages = ReplicatedStorage:WaitForChild('Packages')
    local Shared = require(Packages:WaitForChild('Shared'))
    local HostPolicy = Shared.Util.HostPolicy

    -- Test: empty roster → nil host
    local host1 = HostPolicy.assignHost({}, nil)
    assert(host1 == nil, 'Empty roster should produce nil host')

    -- Test: single player becomes host
    local host2 = HostPolicy.assignHost({ 100 }, nil)
    assert(host2 == 100, 'Single player should become host')

    -- Test: existing valid host is preserved
    local host3 = HostPolicy.assignHost({ 100, 200 }, 100)
    assert(host3 == 100, 'Valid existing host should be preserved')

    -- Test: invalid host → next player in waiting order wins
    local host4 = HostPolicy.assignHost({ 100, 200 }, 999)
    assert(host4 == 100, 'Invalid host should reassign to the first waiting player')

    -- Test: host leaving → next still-present waiting player becomes host
    local host5 = HostPolicy.assignHost({ 200, 300 }, 100)
    assert(host5 == 200, 'Host not in roster should reassign to the next waiting player')

    -- Test: isValidHost
    assert(HostPolicy.isValidHost(100, { 100 }) == true, 'Valid host should return true')
    assert(HostPolicy.isValidHost(999, { 100 }) == false, 'Invalid host should return false')
    assert(HostPolicy.isValidHost(nil, { 100 }) == false, 'Nil host should return false')
    assert(HostPolicy.isValidHost(100, {}) == false, 'Host not in empty roster should return false')

    print('[HostPolicy.spec] All tests passed')
end
