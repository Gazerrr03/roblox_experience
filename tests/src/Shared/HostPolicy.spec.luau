return function()
    local ReplicatedStorage = game:GetService('ReplicatedStorage')
    local Packages = ReplicatedStorage:WaitForChild('Packages')
    local Shared = require(Packages:WaitForChild('Shared'))
    local HostPolicy = Shared.Util.HostPolicy

    -- Helper to make fake player-like objects
    local function makePlayer(userId)
        return { UserId = userId }
    end

    -- Test: empty roster → nil host
    local host1 = HostPolicy.assignHost({}, nil)
    assert(host1 == nil, 'Empty roster should produce nil host')

    -- Test: single player becomes host
    local p1 = makePlayer(100)
    local host2 = HostPolicy.assignHost({ p1 }, nil)
    assert(host2 == 100, 'Single player should become host')

    -- Test: existing valid host is preserved
    local p2 = makePlayer(200)
    local host3 = HostPolicy.assignHost({ p1, p2 }, 100)
    assert(host3 == 100, 'Valid existing host should be preserved')

    -- Test: invalid host → lowest userId wins
    local host4 = HostPolicy.assignHost({ p1, p2 }, 999)
    assert(host4 == 100, 'Invalid host should reassign to lowest userId')

    -- Test: host leaving → next lowest userId becomes host
    local p3 = makePlayer(50)
    local p4 = makePlayer(150)
    local host5 = HostPolicy.assignHost({ p3, p4 }, 100) -- 100 not in list, should pick 50
    assert(host5 == 50, 'Host not in roster should reassign to lowest userId')

    -- Test: isValidHost
    assert(HostPolicy.isValidHost(100, { p1 }) == true, 'Valid host should return true')
    assert(HostPolicy.isValidHost(999, { p1 }) == false, 'Invalid host should return false')
    assert(HostPolicy.isValidHost(nil, { p1 }) == false, 'Nil host should return false')
    assert(HostPolicy.isValidHost(100, {}) == false, 'Host not in empty roster should return false')

    print('[HostPolicy.spec] All tests passed')
end
