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

    service.World = {
        RoomIds = { 'A', 'B', 'C', 'D', 'E' },
        CampRoomId = 'A',
        RoomById = {
            A = {
                Neighbors = { 'B', 'C' },
            },
            B = {
                Neighbors = { 'A' },
            },
            C = {
                Neighbors = { 'A' },
            },
            D = {
                Neighbors = { 'B' },
            },
            E = {
                Neighbors = { 'C' },
            },
        },
        RoomAffordances = {
            A = { PatrolAnchors = { Vector3.new(0, 0, 0) } },
            B = { PatrolAnchors = { Vector3.new(10, 0, 0) } },
            C = { PatrolAnchors = { Vector3.new(20, 0, 0) } },
            D = { PatrolAnchors = { Vector3.new(30, 0, 0) } },
            E = { PatrolAnchors = { Vector3.new(40, 0, 0) } },
        },
        PatrolPoints = {
            Vector3.new(0, 0, 0),
            Vector3.new(10, 0, 0),
            Vector3.new(20, 0, 0),
            Vector3.new(30, 0, 0),
            Vector3.new(40, 0, 0),
        },
        CanTraverseBetweenPositions = function()
            return true
        end,
    }

    service:_queuePendingUgcMonsterPayload({
        OwnerUserId = 777,
        Seed = 222333,
        RuntimeProfile = {
            Behaviors = {
                Chase = true,
                SenseNearestTarget = true,
            },
            Effects = {},
            Id = 'ugc-determinism-seed',
            Name = 'UGC Determinism Seed',
            PatrolSpeedMultiplier = 0.45,
            Presentation = {
                AnimationMode = 'defaultR6',
                ChaseLoopSoundAssetId = 9118823108,
                ModelAssetId = 4446576906,
                RigType = 'R6',
            },
            SightRange = 36,
            SpawnOffset = Vector3.new(0, 4, 0),
            Speed = 14,
            CombatHitPoints = 2,
        },
    })
    service:_spawnQueuedUgcMonsters()

    assert(
        #factoryCalls >= 2 and factoryCalls[2].RandomSeed == 222333,
        'UGC monster service should receive payload seed for deterministic behavior'
    )

    service:_destroyUgcMonsters()
end
