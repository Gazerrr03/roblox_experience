local MODE = table.freeze({
    Walk = 'Walk',
    Sprint = 'Sprint',
})

local ControlState = {}
ControlState.__index = ControlState

ControlState.Mode = MODE

function ControlState.new()
    return setmetatable({
        Mode = MODE.Walk,
        SprintRequested = false,
        SprintEnabled = true,
        CrouchEnabled = false,
    }, ControlState)
end

function ControlState:getSummary()
    return {
        Mode = self.Mode,
        SprintRequested = self.SprintRequested,
        SprintEnabled = self.SprintEnabled,
        CrouchEnabled = self.CrouchEnabled,
    }
end

function ControlState:requestSprintStart(playerStateSummary)
    if playerStateSummary.IsDead then
        self.SprintRequested = false
        self.Mode = MODE.Walk
        return false, 'Dead'
    end

    if not playerStateSummary.CanSprint then
        self.SprintRequested = false
        self.Mode = MODE.Walk
        return false, 'StaminaDepleted'
    end

    self.SprintRequested = true
    self.Mode = MODE.Sprint
    return true, self:getSummary()
end

function ControlState:requestSprintStop()
    self.SprintRequested = false
    self.Mode = MODE.Walk
    return true, self:getSummary()
end

function ControlState:syncPlayerState(playerStateSummary)
    if playerStateSummary.IsDead then
        self.SprintRequested = false
        self.Mode = MODE.Walk
        return self:getSummary()
    end

    if playerStateSummary.CanSprint ~= true then
        self.SprintRequested = false
        self.Mode = MODE.Walk
        return self:getSummary()
    end

    if self.SprintRequested and playerStateSummary.CanSprint then
        self.Mode = MODE.Sprint
    else
        self.Mode = MODE.Walk
    end

    return self:getSummary()
end

return ControlState
