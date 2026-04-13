local EnemyStateMachine = {}
EnemyStateMachine.__index = EnemyStateMachine

EnemyStateMachine.State = table.freeze({
    Idle = 'Idle',
    Suspect = 'Suspect',
    Alert = 'Alert',
    Search = 'Search',
})

function EnemyStateMachine.new()
    return setmetatable({
        Current = EnemyStateMachine.State.Idle,
        Previous = nil,
    }, EnemyStateMachine)
end

function EnemyStateMachine:update(blackboard, now)
    local nextState = EnemyStateMachine.State.Idle

    if blackboard.CurrentTarget ~= nil then
        nextState = EnemyStateMachine.State.Alert
    elseif blackboard:canUseLastSeen(now) then
        nextState = EnemyStateMachine.State.Search
    end

    local changed = nextState ~= self.Current
    if changed then
        self.Previous = self.Current
        self.Current = nextState
    end

    blackboard.PerceptionState = nextState
    return changed, nextState
end

return EnemyStateMachine
