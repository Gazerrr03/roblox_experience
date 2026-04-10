local EnemyStateMachine = require(script.Parent.EnemyStateMachine)

local MovementComponent = {}
MovementComponent.__index = MovementComponent

function MovementComponent.new(options)
    local runtimeOptions = options or {}

    return setmetatable({
        StepToward = runtimeOptions.StepToward,
        GetCurrentPosition = runtimeOptions.GetCurrentPosition,
        SpawnOffset = runtimeOptions.SpawnOffset,
        Speed = runtimeOptions.Speed,
        PatrolSpeedMultiplier = runtimeOptions.PatrolSpeedMultiplier,
        EnableChase = runtimeOptions.EnableChase,
        EnablePatrol = runtimeOptions.EnablePatrol,
        ArrivalThreshold = runtimeOptions.ArrivalThreshold or 2,
    }, MovementComponent)
end

function MovementComponent:update(context, blackboard, state, dt)
    local currentPosition = self.GetCurrentPosition()
    local nextPosition
    local animationName = 'Idle'
    local animationSpeed = 1
    local shouldPlayChaseLoop = false

    if
        state == EnemyStateMachine.State.Alert
        and blackboard.CurrentTarget ~= nil
        and self.EnableChase
    then
        nextPosition = self.StepToward(
            currentPosition,
            blackboard.TargetPositions[blackboard.CurrentTarget],
            self.Speed,
            dt
        )
        animationName = 'Run'
        animationSpeed = 1.15
        shouldPlayChaseLoop = true
    elseif state == EnemyStateMachine.State.Search and blackboard.LastSeenPosition ~= nil then
        nextPosition = self.StepToward(currentPosition, blackboard.LastSeenPosition, self.Speed, dt)
        animationName = 'Walk'
    elseif self.EnablePatrol and #context.PatrolPoints > 0 then
        local patrolTarget = context.PatrolPoints[context.PatrolIndex] + self.SpawnOffset
        nextPosition = self.StepToward(
            currentPosition,
            patrolTarget,
            self.Speed * self.PatrolSpeedMultiplier,
            dt
        )
        animationName = 'Walk'

        if (nextPosition - patrolTarget).Magnitude <= 2 then
            context.PatrolIndex = (context.PatrolIndex % #context.PatrolPoints) + 1
        end
    end

    return {
        NextPosition = nextPosition,
        AnimationName = animationName,
        AnimationSpeed = animationSpeed,
        ShouldPlayChaseLoop = shouldPlayChaseLoop,
    }
end

return MovementComponent
