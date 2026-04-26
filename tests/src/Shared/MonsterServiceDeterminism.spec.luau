return function()
    local ReplicatedStorage = game:GetService('ReplicatedStorage')
    local packages = ReplicatedStorage:WaitForChild('Packages')
    local gameplay = require(packages:WaitForChild('Gameplay'))
    local shared = require(packages:WaitForChild('Shared'))

    local compileMonsterForMaze = gameplay.Monsters.compileMonsterForMaze
    local MonsterService = shared.Runtime.MonsterService

    local compileOk, runtimeProfile = compileMonsterForMaze(gameplay.Config.Monsters[1])
    assert(
        compileOk == true,
        'Expected maze monster runtime profile to compile for determinism test'
    )

    local function createTrack()
        return {
            Play = function() end,
            Stop = function() end,
            AdjustSpeed = function() end,
        }
    end

    local function createMonsterModel()
        local monsterModel = Instance.new('Model')
        monsterModel.Name = 'DeterminismMonster'

        local rootPart = Instance.new('Part')
        rootPart.Name = 'HumanoidRootPart'
        rootPart.Size = Vector3.new(2, 2, 1)
        rootPart.Parent = monsterModel

        local head = Instance.new('Part')
        head.Name = 'Head'
        head.Size = Vector3.new(2, 1, 1)
        head.Parent = monsterModel

        local humanoid = Instance.new('Humanoid')
        humanoid.Parent = monsterModel

        return monsterModel
    end

    local function collectRandomRolls(logEntries)
        local rolls = {}
        for _, entry in ipairs(logEntries) do
            if entry.Event == 'RandomRoll' then
                table.insert(rolls, entry.Result)
            end
        end
        return rolls
    end

    local function serialize(values)
        local segments = {}
        for _, value in ipairs(values) do
            table.insert(segments, tostring(value))
        end
        return table.concat(segments, ',')
    end

    local function createInjectedRuntime(updateFn)
        return {
            Context = {
                PatrolIndex = 1,
            },
            Blackboard = {
                CurrentTarget = nil,
            },
            spawn = function() end,
            destroy = function() end,
            applyDamage = function()
                return 1
            end,
            reset = function(self, _patrolPoints, initialPatrolIndex)
                self.Context.PatrolIndex = initialPatrolIndex or 1
                self.Blackboard.CurrentTarget = nil
            end,
            update = function(self, dt)
                return updateFn(self, dt)
            end,
        }
    end

    local function runDeterminismSimulation(seed, frameDts)
        local service
        service = MonsterService.new(
            runtimeProfile,
            function()
                return true
            end,
            nil,
            nil,
            {
                AssetLoader = function()
                    return createMonsterModel()
                end,
                AutoUpdateOnHeartbeat = false,
                DecisionLogLimit = 256,
                EnemyFactory = function()
                    return createInjectedRuntime(function(_runtime, dt)
                        local currentPosition = service:_getCurrentPosition()
                        local roll = service:_nextRandomInteger(1, 100, 'DeterministicWander')
                        local step = (roll / 100) * dt
                        return {
                            AnimationName = 'Walk',
                            AnimationSpeed = 1,
                            NextPosition = currentPosition + Vector3.new(step, 0, 0),
                            ShouldPlayChaseLoop = false,
                            State = 'Idle',
                            TargetPlayer = nil,
                            TargetChanged = false,
                            StateChanged = false,
                            AttackQueued = false,
                            IsDead = false,
                        }
                    end)
                end,
                LoadAnimationTrack = function()
                    return createTrack()
                end,
                RandomSeed = seed,
            }
        )

        service:spawn({ Vector3.new(0, 0, 0) }, 1)
        for _, frameDt in ipairs(frameDts) do
            service:update(frameDt)
        end

        local finalPosition = service:_getCurrentPosition()
        local logEntries = service:getDecisionLogSnapshot()
        service:destroy()

        return finalPosition, logEntries
    end

    local totalSixTicksSplitA = { 0.2, 0.2, 0.2 }
    local totalSixTicksSplitB = { 0.05, 0.15, 0.07, 0.09, 0.24 }

    local positionA, logA = runDeterminismSimulation(987654, totalSixTicksSplitA)
    local positionB, logB = runDeterminismSimulation(987654, totalSixTicksSplitB)
    local rollsA = collectRandomRolls(logA)
    local rollsB = collectRandomRolls(logB)

    assert(
        positionA == positionB,
        'Fixed-step monster updates should produce identical output for equal total dt with same seed'
    )
    assert(
        serialize(rollsA) == serialize(rollsB),
        'Same seed should produce identical random roll sequence regardless of frame partitioning'
    )
    assert(#rollsA == 6, '0.6 seconds at 10Hz should produce exactly six logic random rolls')

    local _, logDifferentSeed = runDeterminismSimulation(123456, totalSixTicksSplitB)
    local rollsDifferentSeed = collectRandomRolls(logDifferentSeed)
    assert(
        serialize(rollsB) ~= serialize(rollsDifferentSeed),
        'Different seeds should produce different random roll sequence'
    )

    local eventNames = {}
    local stateSwitchService
    stateSwitchService = MonsterService.new(
        runtimeProfile,
        function()
            return true
        end,
        nil,
        nil,
        {
            AssetLoader = function()
                return createMonsterModel()
            end,
            AutoUpdateOnHeartbeat = false,
            DecisionLogSink = function(entry)
                eventNames[entry.Event] = true
            end,
            EnemyFactory = function()
                local tick = 0
                return createInjectedRuntime(function(runtime, _dt)
                    tick += 1
                    local target = if tick % 2 == 0 then { UserId = 404 } else nil
                    runtime.Blackboard.CurrentTarget = target
                    return {
                        AttackResult = if tick == 3 then 'Miss' else nil,
                        AnimationName = 'Walk',
                        AnimationSpeed = 1,
                        NextPosition = stateSwitchService:_getCurrentPosition(),
                        ShouldPlayChaseLoop = false,
                        State = if tick % 2 == 0 then 'Alert' else 'Idle',
                        TargetPlayer = target,
                        TargetChanged = false,
                        StateChanged = false,
                        AttackQueued = false,
                        IsDead = false,
                    }
                end)
            end,
            LoadAnimationTrack = function()
                return createTrack()
            end,
            RandomSeed = 333333,
        }
    )

    stateSwitchService:spawn({ Vector3.new(0, 0, 0) }, 1)
    stateSwitchService:update(0.3)
    stateSwitchService:destroy()

    assert(
        eventNames.StateTransition == true,
        'Decision log should include state transition events'
    )
    assert(eventNames.TargetSwitch == true, 'Decision log should include target switch events')
    assert(eventNames.AttackResult == true, 'Decision log should include attack result events')

    local zeroDtService
    zeroDtService = MonsterService.new(
        runtimeProfile,
        function()
            return true
        end,
        nil,
        nil,
        {
            AssetLoader = function()
                return createMonsterModel()
            end,
            AutoUpdateOnHeartbeat = false,
            DecisionLogLimit = 64,
            EnemyFactory = function()
                return createInjectedRuntime(function(_runtime, _dt)
                    zeroDtService:_nextRandomInteger(1, 5, 'ZeroDtGuard')
                    return {
                        AnimationName = 'Idle',
                        AnimationSpeed = 1,
                        NextPosition = zeroDtService:_getCurrentPosition(),
                        ShouldPlayChaseLoop = false,
                        State = 'Idle',
                        TargetPlayer = nil,
                        TargetChanged = false,
                        StateChanged = false,
                        AttackQueued = false,
                        IsDead = false,
                    }
                end)
            end,
            LoadAnimationTrack = function()
                return createTrack()
            end,
            RandomSeed = 555555,
        }
    )

    zeroDtService:spawn({ Vector3.new(0, 0, 0) }, 1)
    zeroDtService:update(0)
    local zeroDtLog = zeroDtService:getDecisionLogSnapshot()
    zeroDtService:destroy()

    local zeroDtRollCount = 0
    for _, entry in ipairs(zeroDtLog) do
        if entry.Event == 'RandomRoll' then
            zeroDtRollCount += 1
        end
    end
    assert(
        zeroDtRollCount == 0,
        'dt=0 should not advance deterministic logic ticks or random roll sequence'
    )
end
