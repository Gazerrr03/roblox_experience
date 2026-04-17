local EnemyStateMachine = {}
EnemyStateMachine.__index = EnemyStateMachine

local STATE = table.freeze({
    Idle = 'Idle',
    Suspect = 'Suspect',
    Alert = 'Alert',
    Search = 'Search',
})

function EnemyStateMachine.new(initialState)
    return setmetatable({
        Current = initialState or STATE.Idle,
        LostTargetTicks = 0,
    }, EnemyStateMachine)
end

function EnemyStateMachine:getState()
    return self.Current
end

function EnemyStateMachine:update(blackboard)
    local hasTarget = blackboard.Transient.HasTarget == true

    if hasTarget then
        self.Current = STATE.Alert
        self.LostTargetTicks = 0
        blackboard:setState(self.Current)
        return self.Current
    end

    if self.Current == STATE.Alert then
        self.Current = STATE.Search
        self.LostTargetTicks = 1
        blackboard:setState(self.Current)
        return self.Current
    end

    if self.Current == STATE.Search then
        self.LostTargetTicks += 1
        if self.LostTargetTicks >= 2 then
            self.Current = STATE.Idle
        end
        blackboard:setState(self.Current)
        return self.Current
    end

    self.Current = STATE.Idle
    blackboard:setState(self.Current)
    return self.Current
end

EnemyStateMachine.State = STATE

return EnemyStateMachine
