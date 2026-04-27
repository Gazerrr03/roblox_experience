local HealthComponent = {}
HealthComponent.__index = HealthComponent

function HealthComponent.new(options)
    local runtimeOptions = options or {}
    local maxHealth = runtimeOptions.MaxHp or runtimeOptions.MaxHealth or 1
    if type(maxHealth) ~= 'number' or maxHealth < 1 then
        maxHealth = 1
    end
    maxHealth = math.max(1, math.floor(maxHealth))

    return setmetatable({
        MaxHealth = maxHealth,
        CurrentHealth = maxHealth,
    }, HealthComponent)
end

function HealthComponent:isAlive()
    return self.CurrentHealth > 0
end

function HealthComponent:isDead()
    return not self:isAlive()
end

function HealthComponent:applyDamage(amount)
    local damage = math.max(0, amount or 0)
    self.CurrentHealth = math.max(0, self.CurrentHealth - damage)
    return self.CurrentHealth
end

function HealthComponent:reset()
    self.CurrentHealth = self.MaxHealth
    return self.CurrentHealth
end

return HealthComponent
