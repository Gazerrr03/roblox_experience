local MovementComponent = {}
MovementComponent.__index = MovementComponent

local DEFAULT_WALK_SPEED = 16
local DEFAULT_SPRINT_SPEED = 24
local DEFAULT_JUMP_VELOCITY = 50

local function getComponentConfig(blackboard, componentName)
    local context = if type(blackboard) == 'table' and type(blackboard.Context) == 'table'
        then blackboard.Context
        else {}
    local componentConfig = if type(context.ComponentConfig) == 'table' then context.ComponentConfig else {}
    local config = componentConfig[componentName]

    if type(config) == 'table' then
        return config
    end

    return {}
end

function MovementComponent.new()
    return setmetatable({}, MovementComponent)
end

function MovementComponent:init(blackboard)
    local config = getComponentConfig(blackboard, 'Movement')

    self.MaxWalkSpeed = config.MaxWalkSpeed or DEFAULT_WALK_SPEED
    self.MaxSprintSpeed = config.MaxSprintSpeed or DEFAULT_SPRINT_SPEED
    self.JumpVelocity = config.JumpVelocity or DEFAULT_JUMP_VELOCITY

    self.IsMoving = false
    self.IsJumping = false
end

function MovementComponent:update(blackboard, dt)
    local inputState = blackboard.Context.InputState or {}
    local isSprinting = blackboard.Transient.IsSprinting == true
    local isDead = blackboard.Transient.IsDead == true
    local currentPosition = blackboard.Context.CurrentPosition
    local targetPosition = inputState.TargetPosition

    if isDead then
        blackboard.Transient.NextPosition = nil
        blackboard.Transient.DesiredAnimation = 'Idle'
        blackboard.Transient.IsMoving = false
        blackboard.Transient.IsJumping = false
        return
    end

    local nextPosition = nil
    local isMoving = false

    if targetPosition and typeof(targetPosition) == 'Vector3' and currentPosition then
        local moveSpeed = if isSprinting then self.MaxSprintSpeed else self.MaxWalkSpeed
        local direction = (targetPosition - currentPosition)
        local distance = direction.Magnitude

        if distance > 0.1 then
            isMoving = true
            local stepSize = math.min(moveSpeed * dt, distance)
            nextPosition = currentPosition + (direction.Unit * stepSize)
        end
    end

    self.IsMoving = isMoving

    blackboard.Transient.NextPosition = nextPosition
    blackboard.Transient.DesiredAnimation = if isSprinting and isMoving
        then 'Run'
        elseif isMoving then 'Walk'
        else 'Idle'
    blackboard.Transient.IsMoving = isMoving
    blackboard.Transient.IsJumping = self.IsJumping
end

function MovementComponent:destroy(_blackboard) end

return MovementComponent
