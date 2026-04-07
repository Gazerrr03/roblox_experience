return function()
    local ReplicatedStorage = game:GetService('ReplicatedStorage')
    local mazeModules = ReplicatedStorage:WaitForChild('PlaceModules'):WaitForChild('Maze')
    local shared = require(ReplicatedStorage:WaitForChild('Packages'):WaitForChild('Shared'))
    local MazeSessionService = require(mazeModules:WaitForChild('MazeSessionService'))

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

    local directMazeService = MazeSessionService.new()
    directMazeService.SessionSeedRandom = createFakeRandom({ 234567, 345678 })

    directMazeService:_ensureAuthoritativeSessionSeed()

    assert(
        directMazeService.SessionData.Seed == 234567,
        'Direct maze startup should issue a non-default authoritative seed when no teleport seed exists'
    )
    assert(
        directMazeService.HasAuthoritativeSessionSeed == true,
        'Issuing a direct maze seed should mark the maze session as authoritative'
    )

    directMazeService:_ensureAuthoritativeSessionSeed()

    assert(
        directMazeService.SessionData.Seed == 234567,
        'Repeated authoritative checks should keep the original maze seed'
    )
    assert(
        directMazeService.SessionSeedRandom.Index == 1,
        'Repeated checks should not consume an extra random seed after authority is established'
    )

    local incomingSeedService = MazeSessionService.new()
    incomingSeedService:_mergeTeleportData({
        SessionConfig = {
            Seed = 456789,
        },
        CampSession = {
            SessionId = 'maze-seed-spec',
            CampAccessCode = 'maze-seed-spec',
            MazeAccessCode = 'maze-seed-spec',
            MazeStatus = 'active',
            PlayersInMaze = {},
            ReturnedPlayerSummaries = {},
        },
    }, false)
    incomingSeedService.SessionSeedRandom = createFakeRandom({ 567890 })

    incomingSeedService:_ensureAuthoritativeSessionSeed()

    assert(
        incomingSeedService.SessionData.Seed == 456789,
        'Incoming teleport seed should remain authoritative during maze startup checks'
    )
    assert(
        incomingSeedService.SessionSeedRandom.Index == 0,
        'An incoming authoritative maze seed should not consume the fallback random source'
    )

    assert(
        incomingSeedService.SessionData.Seed ~= shared.Config.SessionConfig.DefaultSeed,
        'Authoritative maze startup should not keep the shared default seed'
    )
end
