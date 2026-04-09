local HealthComponent = {}
HealthComponent.__index = HealthComponent

local DAMAGE_PIP_COST = {
    Light = 1,
    Heavy = 2,
}

function HealthComponent.new()
    return setmetatable({}, HealthComponent)
end

function HealthComponent:init(blackboard)
    local config = blackboard.Context.ComponentConfig.Health
<<<<<<< HEAD
    local maxHealthPips = if config and config.MaxHealthPips then config.MaxHealthPips else 2
=======
    local maxHealthPips = if config and config.MaxHealthPips then config.MaxHealthPips else 2
>>>>>>> af646b4 (feat(player): add Player OOP system with component architecture)

    self.MaxHealthPips = maxHealthPips
    self.CurrentHealthPips = maxHealthPips
    self.IsDead = false
    self.CorpseActive = false
end

<<<<<<< HEAD
function HealthComponent:applyDamage(blackboard, damageKind)
=======
function HealthComponent:applyDamage(blackboard, damageKind)
>>>>>>> af646b4 (feat(player): add Player OOP system with component architecture)
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

<<<<<<< HEAD
function HealthComponent:update(blackboard, dt)
=======
function HealthComponent:update(blackboard, dt)
>>>>>>> af646b4 (feat(player): add Player OOP system with component architecture)
    blackboard.Transient.CurrentHealthPips = self.CurrentHealthPips
    blackboard.Transient.MaxHealthPips = self.MaxHealthPips
    blackboard.Transient.IsDead = self.IsDead
    blackboard.Transient.CorpseActive = self.CorpseActive
end

function HealthComponent:destroy(_blackboard) end

return HealthComponent
