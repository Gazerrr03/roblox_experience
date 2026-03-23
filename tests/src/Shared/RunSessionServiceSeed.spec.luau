return function()
    local ReplicatedStorage = game:GetService('ReplicatedStorage')
    local runModules = ReplicatedStorage:WaitForChild('PlaceModules'):WaitForChild('Run')
    local shared = require(ReplicatedStorage:WaitForChild('Packages'):WaitForChild('Shared'))
    local RunSessionService = require(runModules:WaitForChild('RunSessionService'))

    local function createFakeRandom(values)
        local fakeRandom = {
            Values = values,
            Index = 0,
        }

        function fakeRandom:NextInteger(minimum, maximum)
            self.Index += 1
            local value = self.Values[self.Index]

            assert(type(value) == 'number', 'Fake random should provide a numeric value')
            assert(
                value >= minimum and value <= maximum,
                'Fake random values should stay inside the requested bounds'
            )

            return value
        end

        return fakeRandom
    end

    local directRunService = RunSessionService.new()
    directRunService.SessionSeedRandom = createFakeRandom({ 234567, 345678 })

    directRunService:_ensureAuthoritativeSessionSeed()

    assert(
        directRunService.SessionData.Seed == 234567,
        'Direct run startup should issue a new authoritative seed when no incoming seed exists'
    )
    assert(
        directRunService.HasAuthoritativeSessionSeed == true,
        'Issuing a direct-run seed should mark the run session as authoritative'
    )

    directRunService:_ensureAuthoritativeSessionSeed()

    assert(
        directRunService.SessionData.Seed == 234567,
        'The same run session should keep its original authoritative seed on repeated checks'
    )
    assert(
        directRunService.SessionSeedRandom.Index == 1,
        'Repeated startup checks should not consume a second random seed after authority is established'
    )

    local incomingSeedService = RunSessionService.new()
    incomingSeedService:_applySessionConfig({
        Seed = 456789,
    })
    incomingSeedService.SessionSeedRandom = createFakeRandom({ 567890 })

    incomingSeedService:_ensureAuthoritativeSessionSeed()

    assert(
        incomingSeedService.SessionData.Seed == 456789,
        'Incoming session seeds should stay authoritative during startup hydration'
    )
    assert(
        incomingSeedService.SessionSeedRandom.Index == 0,
        'A run session with an incoming authoritative seed should not consume the direct-run fallback random source'
    )

    assert(
        incomingSeedService.SessionData.Seed ~= shared.Config.SessionConfig.DefaultSeed,
        'Authoritative startup seeds should not fall back to the shared default seed'
    )
end
