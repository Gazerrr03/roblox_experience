local EnemyBlackboard = {}
EnemyBlackboard.__index = EnemyBlackboard

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

function EnemyBlackboard.new(definition)
    return setmetatable({
        Definition = definition,
        State = nil,
        Context = {},
        Transient = {},
    }, EnemyBlackboard)
end

function EnemyBlackboard:beginTick(context)
    self.Context = cloneTable(context)
    self.Transient = {}
end

function EnemyBlackboard:setState(state)
    self.State = state
end

function EnemyBlackboard:getState()
    return self.State
end

return EnemyBlackboard
