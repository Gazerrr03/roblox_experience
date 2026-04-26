local EnemyBlackboard = require(script.Parent.EnemyBlackboard)
local EnemyStateMachine = require(script.Parent.EnemyStateMachine)
local PerceptionComponent = require(script.Parent.PerceptionComponent)
local MovementComponent = require(script.Parent.MovementComponent)
local AttackComponent = require(script.Parent.AttackComponent)
local HealthComponent = require(script.Parent.HealthComponent)

local EnemyRuntime = {}
EnemyRuntime.__index = EnemyRuntime

function EnemyRuntime.new(options)
    local runtimeOptions = options or {}

    local blackboard = EnemyBlackboard.new({
        MemoryDurationSeconds = runtimeOptions.MemoryDurationSeconds,
    })

    return setmetatable({
        Blackboard = blackboard,
        StateMachine = EnemyStateMachine.new(),
        Perception = PerceptionComponent.new(runtimeOptions.Perception),
        Movement = MovementComponent.new(runtimeOptions.Movement),
        Attack = AttackComponent.new(runtimeOptions.Attack),
        Health = HealthComponent.new(runtimeOptions.Health),
        Context = {
            PatrolPoints = {},
            PatrolIndex = 1,
        },
        Clock = runtimeOptions.Clock or os.clock,
    }, EnemyRuntime)
end

function EnemyRuntime:reset(patrolPoints, initialPatrolIndex)
    self.Context.PatrolPoints = patrolPoints or {}
    self.Context.PatrolIndex = initialPatrolIndex or 1
    self.Blackboard.CurrentTarget = nil
    self.Blackboard.PreviousTarget = nil
    self.Blackboard.TargetPositions = {}
    self.Blackboard.Awareness = 0
    self.Blackboard.PerceptionState = EnemyStateMachine.State.Idle
    self.Blackboard.LastSeenPosition = nil
    self.Blackboard.LastSeenAt = nil
    self.StateMachine.Current = EnemyStateMachine.State.Idle
    self.StateMachine.Previous = nil
end

function EnemyRuntime:destroy() end

function EnemyRuntime:applyDamage(damage, source)
    self.Health:applyDamage(damage, source)
end

function EnemyRuntime:update(dt)
    if not self.Health:isAlive() then
        return {
            NextPosition = nil,
            AnimationName = 'Idle',
            AnimationSpeed = 1,
            ShouldPlayChaseLoop = false,
            TargetChanged = false,
            StateChanged = false,
            AttackQueued = false,
            PerceptionState = self.Blackboard.PerceptionState,
        }
    end

    local targetChanged = self.Perception:update(self.Blackboard)
    local stateChanged, state = self.StateMachine:update(self.Blackboard, self.Clock())

    local movementDecision = self.Movement:update(self.Context, self.Blackboard, state, dt)

    local currentPosition = self.Movement.GetCurrentPosition()
    local attackQueued = self.Attack:tryQueueAttack(currentPosition, self.Blackboard)

    return {
        NextPosition = movementDecision.NextPosition,
        AnimationName = movementDecision.AnimationName,
        DesiredAnimation = movementDecision.AnimationName,
        AnimationSpeed = movementDecision.AnimationSpeed,
        DesiredAnimationSpeed = movementDecision.AnimationSpeed,
        ShouldPlayChaseLoop = movementDecision.ShouldPlayChaseLoop,
        TargetChanged = targetChanged,
        StateChanged = stateChanged,
        AttackQueued = attackQueued,
        PerceptionState = state,
        State = state,
        TargetPlayer = self.Blackboard.CurrentTarget,
    }
end

return EnemyRuntime
