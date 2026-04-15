local HealthComponent = {}
HealthComponent.__index = HealthComponent

local DAMAGE_PIP_COST = {
    Light = 1,
    Heavy = 2,
}

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

function HealthComponent.new()
    return setmetatable({}, HealthComponent)
end

function HealthComponent:init(blackboard)
    local config = getComponentConfig(blackboard, 'Health')
    local maxHealthPips = if config and config.MaxHealthPips then config.MaxHealthPips else 2

    self.MaxHealthPips = maxHealthPips
    self.CurrentHealthPips = maxHealthPips
    self.IsDead = false
    self.CorpseActive = false
end

function HealthComponent:applyDamage(_blackboard, damageKind)
    local pipCost = DAMAGE_PIP_COST[damageKind]
    if pipCost == nil then
        return false, 'UnknownDamageKind'
    end

    self.CurrentHealthPips = math.max(0, self.CurrentHealthPips - pipCost)

    if self.CurrentHealthPips == 0 then
        self.IsDead = true
        self.CorpseActive = true
    end

    return true, self.CurrentHealthPips
end

function HealthComponent:healPips(blackboard, amount)
    if self.IsDead then
        return false, 'Dead'
    end

    local delta = math.floor(tonumber(amount) or 0)
    if delta < 1 then
        return false, 'InvalidAmount'
    end

    self.CurrentHealthPips = math.min(self.MaxHealthPips, self.CurrentHealthPips + delta)
    self:update(blackboard, 0)
    return true, self.CurrentHealthPips
end

function HealthComponent:update(blackboard, _dt)
    blackboard.Transient.CurrentHealthPips = self.CurrentHealthPips
    blackboard.Transient.MaxHealthPips = self.MaxHealthPips
    blackboard.Transient.IsDead = self.IsDead
    blackboard.Transient.CorpseActive = self.CorpseActive
end

function HealthComponent:destroy(_blackboard) end

return HealthComponent
