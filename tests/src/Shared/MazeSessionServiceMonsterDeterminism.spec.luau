return function()
    local ReplicatedStorage = game:GetService('ReplicatedStorage')
    local mazeModules = ReplicatedStorage:WaitForChild('PlaceModules'):WaitForChild('Maze')
    local MazeSessionService = require(mazeModules:WaitForChild('MazeSessionService'))

    local factoryCalls = {}
    local monsterServiceFactory = function(runtimeProfile, _, _, _, runtimeOptions)
        local record = {
            RandomSeed = runtimeOptions and runtimeOptions.RandomSeed,
            RuntimeProfileId = runtimeProfile.Id,
            SeedUpdates = {},
        }
        table.insert(factoryCalls, record)

        return {
            spawn = function() end,
            destroy = function() end,
            setDeterministicSeed = function(_, seed)
                table.insert(record.SeedUpdates, seed)
            end,
        }
    end

    local service = MazeSessionService.new({
        MonsterServiceFactory = monsterServiceFactory,
    })

    assert(#factoryCalls == 1, 'Maze startup should construct one baseline monster service')
    assert(
        factoryCalls[1].RandomSeed == service.SessionData.Seed,
        'Baseline monster service should receive the current maze session seed'
    )

    service.SessionData.Seed = 876543
    service:_syncMonsterDeterminismSeed()

    assert(
        factoryCalls[1].SeedUpdates[1] == 876543,
        'Maze seed sync should propagate authoritative seed to monster determinism seed'
    )
end
