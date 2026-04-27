local MODE = table.freeze({
    Walk = 'Walk',
    Sprint = 'Sprint',
    Sneak = 'Sneak',
})

local ControlState = {}
ControlState.__index = ControlState

ControlState.Mode = MODE

function ControlState.new()
    return setmetatable({
        Mode = MODE.Walk,
        SprintRequested = false,
        SneakRequested = false,
        SprintEnabled = true,
        CrouchEnabled = false,
    }, ControlState)
end

function ControlState:getSummary()
    return {
        Mode = self.Mode,
        SprintRequested = self.SprintRequested,
        SneakRequested = self.SneakRequested,
        SprintEnabled = self.SprintEnabled,
        CrouchEnabled = self.CrouchEnabled,
    }
end

function ControlState:requestSprintStart(playerStateSummary)
    if type(playerStateSummary) ~= 'table' then
        self.SprintRequested = false
        self.SneakRequested = false
        self.Mode = MODE.Walk
        return false, 'MissingPlayerState'
    end

    if playerStateSummary.IsDead then
        self.SprintRequested = false
        self.SneakRequested = false
        self.Mode = MODE.Walk
        return false, 'Dead'
    end

    if not playerStateSummary.CanSprint then
        self.SprintRequested = false
        if self.Mode == MODE.Sprint then
            self.Mode = MODE.Walk
        end
        return false, 'StaminaDepleted'
    end

    if
        playerStateSummary.ActiveEffects
        and playerStateSummary.ActiveEffects['SprintSuppressed']
    then
        self.SprintRequested = false
        if self.Mode == MODE.Sprint then
            self.Mode = MODE.Walk
        end
        return false, 'SprintSuppressed'
    end

    self.SprintRequested = true
    self.SneakRequested = false
    self.Mode = MODE.Sprint
    return true, self:getSummary()
end

function ControlState:requestSprintStop()
    self.SprintRequested = false
    if self.Mode == MODE.Sprint then
        self.Mode = MODE.Walk
    end
    return true, self:getSummary()
end

function ControlState:requestSneakStart(playerStateSummary)
    if type(playerStateSummary) ~= 'table' then
        self.SprintRequested = false
        self.SneakRequested = false
        self.Mode = MODE.Walk
        return false, 'MissingPlayerState'
    end

    if playerStateSummary.IsDead then
        self.SprintRequested = false
        self.SneakRequested = false
        self.Mode = MODE.Walk
        return false, 'Dead'
    end

    self.SprintRequested = false
    self.SneakRequested = true
    self.Mode = MODE.Sneak
    return true, self:getSummary()
end

function ControlState:requestSneakStop()
    self.SneakRequested = false
    if self.Mode == MODE.Sneak then
        self.Mode = MODE.Walk
    end
    return true, self:getSummary()
end

function ControlState:syncPlayerState(playerStateSummary)
    if type(playerStateSummary) ~= 'table' then
        self.SprintRequested = false
        self.SneakRequested = false
        self.Mode = MODE.Walk
        return self:getSummary()
    end

    if playerStateSummary.IsDead then
        self.SprintRequested = false
        self.SneakRequested = false
        self.Mode = MODE.Walk
        return self:getSummary()
    end

    if self.SneakRequested then
        self.SprintRequested = false
        self.Mode = MODE.Sneak
        return self:getSummary()
    end

    if playerStateSummary.CanSprint ~= true then
        self.SprintRequested = false
        self.Mode = MODE.Walk
        return self:getSummary()
    end

    if
        playerStateSummary.ActiveEffects
        and playerStateSummary.ActiveEffects['SprintSuppressed']
    then
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
