return function()
    local ReplicatedStorage = game:GetService('ReplicatedStorage')
    local packages = ReplicatedStorage:WaitForChild('Packages')
    local gameplay = require(packages:WaitForChild('Gameplay'))

    local HealthComponent = gameplay.Player.HealthComponent

    local function makeBlackboard(maxPips)
        return {
            Context = {
                ComponentConfig = {
                    Health = {
                        MaxHealthPips = maxPips,
                    },
                },
            },
        }
    end

    local h = HealthComponent.new()
    h:init(makeBlackboard(2))
    assert(h.CurrentHealthPips == 2 and h.MaxHealthPips == 2, 'init should start at full pips')

    local dmgOk = h:applyDamage(makeBlackboard(2), gameplay.PlayerState.DamageKind.Light)
    assert(dmgOk == true and h.CurrentHealthPips == 1, 'light damage should remove one pip')

    local healOk, pips = h:applyHealPips(makeBlackboard(2), 1)
    assert(healOk == true and pips == 2, 'heal should restore one pip up to max')

    local fullFail = h:applyHealPips(makeBlackboard(2), 1)
    assert(fullFail == false, 'heal at full health should fail')

    h.CurrentHealthPips = 0
    h.IsDead = true
    h.CorpseActive = true
    local deadFail = h:applyHealPips(makeBlackboard(2), 1)
    assert(deadFail == false, 'heal while dead should fail')
end
