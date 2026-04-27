return function()
    local ReplicatedStorage = game:GetService('ReplicatedStorage')
    local packages = ReplicatedStorage:WaitForChild('Packages')
    local shared = require(packages:WaitForChild('Shared'))

    local enemyRuntimeModule = shared.Runtime.MonsterRuntime.EnemyRuntime

    local currentPosition = Vector3.new(0, 0, 0)
    local players = {}
    local clockValue = 100

    local runtime = enemyRuntimeModule.new({
        MemoryDurationSeconds = 0,
        Perception = {
            GetPlayers = function()
                return players
            end,
            CanTargetPlayer = function()
                return true
            end,
            GetCurrentPosition = function()
                return currentPosition
            end,
            PickNearestTarget = function(origin, positions, sightRange)
                local closest = nil
                local closestDistance = sightRange
                for player, position in pairs(positions) do
                    local distance = (position - origin).Magnitude
                    if distance <= closestDistance then
                        closest = player
                        closestDistance = distance
                    end
                end
                return closest
            end,
            SightRange = 36,
            EnableSenseNearestTarget = true,
            GetNow = function()
                return clockValue
            end,
        },
        Movement = {
            StepToward = function(origin, target, speed, dt)
                local offset = target - origin
                local distance = offset.Magnitude
                if distance == 0 then
                    return origin
                end
                local step = math.min(speed * dt, distance)
                return origin + offset.Unit * step
            end,
            GetCurrentPosition = function()
                return currentPosition
            end,
            SpawnOffset = Vector3.new(0, 4, 0),
            Speed = 14,
            PatrolSpeedMultiplier = 0.45,
            EnableChase = true,
            EnablePatrol = false,
        },
    })

    runtime:reset({ Vector3.new(0, 0, 0) }, 1)

    local idleDecision = runtime:update(0.5)
    assert(idleDecision.PerceptionState == 'Idle', 'No target should keep enemy in idle state')
    assert(idleDecision.NextPosition == nil, 'Idle decision should not move the enemy')

    local player = {
        Character = {
            FindFirstChild = function(_, childName)
                if childName ~= 'HumanoidRootPart' then
                    return nil
                end
                return {
                    Position = Vector3.new(10, 0, 0),
                }
            end,
        },
    }
    players = { player }

    local chaseDecision = runtime:update(0.5)
    assert(chaseDecision.StateChanged == true, 'Acquiring target should cause state transition')
    assert(chaseDecision.PerceptionState == 'Alert', 'Target detection should enter alert state')
    assert(chaseDecision.NextPosition ~= nil, 'Alert state should produce chase movement')
    assert(chaseDecision.AnimationName == 'Run', 'Alert movement should use run animation')

    currentPosition = chaseDecision.NextPosition
    players = {}
    clockValue += 1

    local lostDecision = runtime:update(0.5)
    assert(lostDecision.PerceptionState == 'Idle', 'Memory disabled should return directly to idle')
    assert(lostDecision.NextPosition == nil, 'Idle after losing target should stop movement')

    local remainingHealth = runtime:applyDamage(1, 'spec')
    assert(remainingHealth == 0, 'Applying lethal damage should reduce runtime health to zero')

    local deathDecision = runtime:update(0.1)
    assert(deathDecision.IsDead == true, 'Dead runtime should report IsDead')
    assert(
        deathDecision.DeathEvent and deathDecision.DeathEvent.KilledBy == 'spec',
        'Dead runtime should report the recorded death source'
    )

    runtime:reset({ Vector3.new(0, 0, 0) }, 1)
    local resetDecision = runtime:update(0.1)
    assert(resetDecision.IsDead == false, 'Reset should restore runtime health')

    runtime:destroy()
    assert(runtime.Blackboard == nil, 'Destroy should release runtime blackboard state')
    assert(runtime.Health == nil, 'Destroy should release runtime component references')
end
