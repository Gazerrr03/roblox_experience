return function()
    local ReplicatedStorage = game:GetService('ReplicatedStorage')
    local shared = require(ReplicatedStorage:WaitForChild('Packages'):WaitForChild('Shared'))
    local policy = shared.Session.SessionSeedPolicy

    local fakeRandom = {
        Values = { 12345, 456789 },
        Index = 0,
    }

    function fakeRandom:NextInteger(minimum, maximum)
        self.Index += 1
        local value = self.Values[self.Index]

        assert(type(value) == 'number', 'Fake random should provide a numeric test value')
        assert(
            value >= minimum and value <= maximum or value == 12345,
            'Fake random should stay inside the requested bounds for this spec'
        )

        return value
    end

    local issued = policy.issueSessionSeed(fakeRandom, 12345)
    assert(issued == 456789, 'The policy should retry until it leaves the configured default seed')
    assert(
        issued >= policy.SeedMin and issued <= policy.SeedMax,
        'Issued session seeds should stay inside the configured bounds'
    )
    assert(issued ~= 12345, 'Issued session seeds should not reuse the configured default seed')

    local sameSessionSeed, issuedNewSeed = policy.ensureAuthoritativeSeed({
        CurrentSeed = issued,
        DefaultSeed = 12345,
        HasAuthoritativeSeed = true,
    })
    assert(
        sameSessionSeed == issued and issuedNewSeed == false,
        'A run session should keep its existing authoritative seed instead of issuing a new one'
    )

    local directRunRandom = {
        Value = 234567,
    }

    function directRunRandom:NextInteger(minimum, maximum)
        assert(
            self.Value >= minimum and self.Value <= maximum,
            'Direct run fake random should stay inside the requested bounds'
        )
        return self.Value
    end

    local directRunSeed, directRunIssued = policy.ensureAuthoritativeSeed({
        CurrentSeed = 12345,
        DefaultSeed = 12345,
        HasAuthoritativeSeed = false,
        RandomSource = directRunRandom,
    })
    assert(
        directRunSeed == 234567 and directRunIssued == true,
        'A direct run session should issue a single authoritative seed when no incoming seed exists'
    )

    local upstreamSeed, upstreamIssued = policy.ensureAuthoritativeSeed({
        CurrentSeed = 345678,
        DefaultSeed = 12345,
        HasAuthoritativeSeed = true,
        RandomSource = directRunRandom,
    })
    assert(
        upstreamSeed == 345678 and upstreamIssued == false,
        'Incoming authoritative seeds should not be replaced by a direct-run fallback'
    )
end
