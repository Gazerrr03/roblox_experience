return function()
    local ReplicatedStorage = game:GetService('ReplicatedStorage')
    local mazeModules = ReplicatedStorage:WaitForChild('PlaceModules'):WaitForChild('Maze')
    local MazeSessionService = require(mazeModules:WaitForChild('MazeSessionService'))

    local spawnedRecords = {}
    local monsterServiceFactory = function(runtimeProfile)
        local record = {
            RuntimeProfileId = runtimeProfile.Id,
            Spawned = false,
            Destroyed = false,
        }
        table.insert(spawnedRecords, record)

        return {
            spawn = function(_, patrolPoints, initialPatrolIndex)
                record.Spawned = true
                record.PatrolPointCount = #patrolPoints
                record.InitialPatrolIndex = initialPatrolIndex
            end,
            destroy = function()
                record.Destroyed = true
            end,
        }
    end

    local service = MazeSessionService.new({
        MonsterServiceFactory = monsterServiceFactory,
    })

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

    local function buildPayload(index)
        return {
            OwnerUserId = 100 + index,
            Seed = 8000 + index,
            RuntimeProfile = {
                Id = string.format('ugc-%d', index),
                Name = string.format('UGC-%d', index),
                Presentation = {
                    ModelAssetId = 4446576906,
                    RigType = 'R6',
                    AnimationMode = 'defaultR6',
                    ChaseLoopSoundAssetId = 9118823108,
                },
                Speed = 14,
                SightRange = 36,
                PatrolSpeedMultiplier = 0.45,
                SpawnOffset = Vector3.new(0, 4, 0),
                Behaviors = {
                    SenseNearestTarget = true,
                    Chase = true,
                },
                Effects = {},
            },
        }
    end

    for index = 1, 6 do
        service:_queuePendingUgcMonsterPayload(buildPayload(index))
    end

    service:_spawnQueuedUgcMonsters()

    assert(
        #service.UgcMonsterServices == 5,
        'Maze UGC monster spawn should enforce the global cap of five monsters'
    )
    assert(
        #service.PendingUgcMonsterPayloads == 0,
        'Queued UGC payloads should be consumed after spawn evaluation'
    )

    for _, entry in ipairs(service.UgcMonsterServices) do
        assert(
            entry.SpawnRoomId == 'D' or entry.SpawnRoomId == 'E',
            'UGC monsters should spawn outside camp and adjacent rooms'
        )
    end

    service:_destroyUgcMonsters()
    for _, record in ipairs(spawnedRecords) do
        if record.RuntimeProfileId ~= 'scrap-wisp' then
            assert(record.Destroyed == true, 'Spawned UGC monster services should be destroyable')
        end
    end
end
