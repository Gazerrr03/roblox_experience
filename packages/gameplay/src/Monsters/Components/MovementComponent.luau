local MonsterBehaviorCatalog = require(script.Parent.Parent.MonsterBehaviorCatalog)
local MonsterLogic = require(script.Parent.Parent.MonsterLogic)

local MovementComponent = {}
MovementComponent.__index = MovementComponent

function MovementComponent.new()
    return setmetatable({}, MovementComponent)
end

function MovementComponent:init(_blackboard) end

function MovementComponent:update(blackboard, dt)
    local currentPosition = blackboard.Context.CurrentPosition
    if typeof(currentPosition) ~= 'Vector3' then
        blackboard.Transient.NextPosition = nil
        blackboard.Transient.DesiredAnimation = 'Idle'
        blackboard.Transient.DesiredAnimationSpeed = 1
        blackboard.Transient.ShouldPlayChaseLoop = false
        return
    end

    local behaviors = blackboard.Context.Behaviors or {}
    local hasTarget = blackboard.Transient.HasTarget == true
    local targetPosition = blackboard.Transient.TargetPosition
    local nextPosition = nil
    local shouldAdvancePatrol = false

    if
        hasTarget
        and behaviors[MonsterBehaviorCatalog.Behavior.Chase]
        and typeof(targetPosition) == 'Vector3'
    then
        nextPosition =
            MonsterLogic.stepToward(currentPosition, targetPosition, blackboard.Context.Speed, dt)
    elseif
        behaviors[MonsterBehaviorCatalog.Behavior.Patrol]
        and typeof(blackboard.Context.PatrolTargetPosition) == 'Vector3'
    then
        local patrolTarget = blackboard.Context.PatrolTargetPosition
        nextPosition = MonsterLogic.stepToward(
            currentPosition,
            patrolTarget,
            blackboard.Context.Speed * blackboard.Context.PatrolSpeedMultiplier,
            dt
        )

        if
            (nextPosition - patrolTarget).Magnitude <= (blackboard.Context.PatrolReachDistance or 2)
        then
            shouldAdvancePatrol = true
        end
    end

    local travelOffset = if nextPosition then nextPosition - currentPosition else Vector3.zero
    local isMoving = travelOffset.Magnitude > 0

    blackboard.Transient.NextPosition = nextPosition
    blackboard.Transient.ShouldAdvancePatrol = shouldAdvancePatrol
    blackboard.Transient.TravelOffset = travelOffset
    blackboard.Transient.DesiredAnimation = if hasTarget and isMoving
        then 'Run'
        elseif isMoving then 'Walk'
        else 'Idle'
    blackboard.Transient.DesiredAnimationSpeed = if hasTarget and isMoving then 1.15 else 1
    blackboard.Transient.ShouldPlayChaseLoop = hasTarget and isMoving
end

function MovementComponent:destroy(_blackboard) end

return MovementComponent
