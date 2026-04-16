local HealthComponent = {}
HealthComponent.__index = HealthComponent

function HealthComponent.new(maxHp)
    local hp = 1
    if type(maxHp) == 'number' and maxHp >= 1 then
        hp = math.floor(maxHp)
    end

    return setmetatable({
        MaxHp = hp,
        CurrentHp = hp,
    }, HealthComponent)
end

function HealthComponent:init(_blackboard)
    -- No-op: initialization is done in the constructor.
end

function HealthComponent:applyDamage(amount, _source)
    if type(amount) ~= 'number' or amount <= 0 then
        return
    end

    self.CurrentHp = math.max(0, self.CurrentHp - amount)
end

function HealthComponent:heal(amount)
    if type(amount) ~= 'number' or amount <= 0 then
        return
    end

    self.CurrentHp = math.min(self.MaxHp, self.CurrentHp + amount)
end

function HealthComponent:isDead()
    return self.CurrentHp <= 0
end

function HealthComponent:update(_blackboard, _dt)
    -- No-op: HealthComponent is driven by explicit applyDamage / heal calls,
    -- not by a per-tick update tick.
end

function HealthComponent:destroy(_blackboard)
    -- No-op: no external resources to release.
end

return HealthComponent
