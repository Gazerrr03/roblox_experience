local PlayerBlackboard = {}
PlayerBlackboard.__index = PlayerBlackboard

local function cloneTable(source)
    local clone = {}
    if type(source) ~= 'table' then
        return clone
    end

    for key, value in pairs(source) do
        clone[key] = value
    end

    return clone
end

function PlayerBlackboard.new(definition)
    return setmetatable({
        Definition = definition,
        State = nil,
        Context = {},
        Transient = {},
    }, PlayerBlackboard)
end

function PlayerBlackboard:beginTick(context)
    self.Context = cloneTable(context)
    self.Transient = {}
end

function PlayerBlackboard:setState(state)
    self.State = state
end

function PlayerBlackboard:getState()
    return self.State
end

return PlayerBlackboard
