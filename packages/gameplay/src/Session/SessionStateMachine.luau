local TRANSITIONS = {
    Camp = {
        Expedition = true,
    },
    Expedition = {
        Extraction = true,
        Settlement = true,
    },
    Extraction = {
        Settlement = true,
    },
    Settlement = {
        Camp = true,
    },
}

local SessionStateMachine = {}
SessionStateMachine.__index = SessionStateMachine

function SessionStateMachine.new(initialState)
    return setmetatable({
        Current = initialState,
    }, SessionStateMachine)
end

function SessionStateMachine:canTransition(nextState)
    local allowedTransitions = TRANSITIONS[self.Current]
    return allowedTransitions ~= nil and allowedTransitions[nextState] == true
end

function SessionStateMachine:transition(nextState)
    if not self:canTransition(nextState) then
        error(string.format('Invalid session transition: %s -> %s', self.Current, nextState))
    end

    self.Current = nextState
    return self.Current
end

return SessionStateMachine
