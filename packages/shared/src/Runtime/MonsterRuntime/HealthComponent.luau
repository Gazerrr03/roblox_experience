local HealthComponent = {}
HealthComponent.__index = HealthComponent

function HealthComponent.new(options)
    local runtimeOptions = options or {}
    local maxHealth = runtimeOptions.MaxHealth or 1

    return setmetatable({
        MaxHealth = maxHealth,
        CurrentHealth = maxHealth,
    }, HealthComponent)
end

function HealthComponent:isAlive()
    return self.CurrentHealth > 0
end

function HealthComponent:applyDamage(amount)
    local damage = math.max(0, amount or 0)
    self.CurrentHealth = math.max(0, self.CurrentHealth - damage)
    return self.CurrentHealth
end

return HealthComponent
