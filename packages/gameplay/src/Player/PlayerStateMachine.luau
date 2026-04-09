local PlayerStateMachine = {}
PlayerStateMachine.__index = PlayerStateMachine

local STATE = table.freeze({
    Idle = 'Idle',
    Walking = 'Walking',
    Sprinting = 'Sprinting',
    Jumping = 'Jumping',
    Dead = 'Dead',
})

function PlayerStateMachine.new(initialState)
    return setmetatable({
        Current = initialState or STATE.Idle,
    }, PlayerStateMachine)
end

function PlayerStateMachine:getState()
    return self.Current
end

function PlayerStateMachine:update(blackboard)
    local isDead = blackboard.Transient.IsDead == true
    local isSprinting = blackboard.Transient.IsSprinting == true
    local isMoving = blackboard.Transient.IsMoving == true
    local isJumping = blackboard.Transient.IsJumping == true

    if isDead then
        self.Current = STATE.Dead
        blackboard:setState(self.Current)
        return self.Current
    end

    if isJumping then
        self.Current = STATE.Jumping
        blackboard:setState(self.Current)
        return self.Current
    end

    if isSprinting and isMoving then
        self.Current = STATE.Sprinting
        blackboard:setState(self.Current)
        return self.Current
    end

    if isMoving then
        self.Current = STATE.Walking
        blackboard:setState(self.Current)
        return self.Current
    end

    self.Current = STATE.Idle
    blackboard:setState(self.Current)
    return self.Current
end

PlayerStateMachine.State = STATE

return PlayerStateMachine
