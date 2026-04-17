local HealthComponent = require(script.Parent.Components.HealthComponent)

local BaseEnemy = {}

function BaseEnemy.setupHealth(self, componentConfig)
    local maxHp = 1
    if type(componentConfig) == 'table' and type(componentConfig.Health) == 'table' then
        local hp = componentConfig.Health.MaxHp
        if type(hp) == 'number' and hp >= 1 then
            maxHp = math.floor(hp)
        end
    end

    if not self.Components then
        self.Components = {}
    end

    self.Components.Health = HealthComponent.new(maxHp)
end

function BaseEnemy.applyDamage(self, amount, source)
    local health = self.Components and self.Components.Health
    if not health then
        return
    end

    if type(amount) ~= 'number' or amount <= 0 then
        return
    end

    local damageSource = source or 'unknown'
    health:applyDamage(amount, damageSource)

    if self.Blackboard and health:isDead() then
        self.Blackboard.Transient.DeathEvent = {
            MonsterId = if self.Blackboard.Definition then self.Blackboard.Definition.Id else nil,
            KilledBy = damageSource,
        }
    end
end

function BaseEnemy.heal(self, amount)
    local health = self.Components and self.Components.Health
    if not health then
        return
    end

    if type(amount) ~= 'number' or amount <= 0 then
        return
    end

    health:heal(amount)
end

function BaseEnemy.getHealth(self)
    local health = self.Components and self.Components.Health
    if not health then
        return {
            CurrentHp = 0,
            MaxHp = 0,
            IsDead = true,
        }
    end

    return {
        CurrentHp = health.CurrentHp,
        MaxHp = health.MaxHp,
        IsDead = health:isDead(),
    }
end

return BaseEnemy
