return function()
    local ReplicatedStorage = game:GetService('ReplicatedStorage')
    local Gameplay = require(ReplicatedStorage:WaitForChild('Packages'):WaitForChild('Gameplay'))
    local ToolUseEffects = Gameplay.ToolUseEffects

    local fakePlayerCrowbar = {} :: any

    local meleeCalled = false
    local mockMonster = {
        tryApplyPlayerMeleeHit = function(_self, pl, opts)
            meleeCalled = true
            assert(pl == fakePlayerCrowbar, 'player passed to melee')
            assert(opts.DamagePips == 2, 'damage from MeleeDamage')
            return false, 'OutOfRange'
        end,
    }

    local action, effect = ToolUseEffects.applyHeldToolUse(fakePlayerCrowbar, {
        ToolCategory = 'Crowbar',
        MeleeDamage = 2,
        SwingRange = 6,
        SwingArcDegrees = 70,
    }, { MonsterService = mockMonster })

    assert(meleeCalled, 'MonsterService.tryApplyPlayerMeleeHit should be called')
    assert(action == 'swung', action)
    assert(string.find(effect, 'swoosh') ~= nil, effect)

    local mockPlayerService = {
        healHealthPips = function(_self, _player, amount)
            assert(amount == 3, 'heal pips')
            return true, 8
        end,
    }

    action, effect = ToolUseEffects.applyHeldToolUse(fakePlayerCrowbar, {
        ToolCategory = 'Potion',
        HealHealthPips = 3,
    }, { PlayerService = mockPlayerService })

    assert(action == 'drank', action)
    assert(string.find(effect, '8') ~= nil, effect)

    action, effect = ToolUseEffects.applyHeldToolUse(fakePlayerCrowbar, {
        ToolCategory = 'UnknownGadget',
    }, {})

    assert(action == 'used' and effect == 'It worked!', string.format('%s | %s', action, effect))

    local charModel = Instance.new('Model')
    local head = Instance.new('Part')
    head.Name = 'Head'
    head.Anchored = true
    head.Parent = charModel
    local fakePlayerLight = { Character = charModel } :: any

    action, effect = ToolUseEffects.applyHeldToolUse(fakePlayerLight, {
        ToolCategory = 'Flashlight',
    }, {})

    assert(action == 'flashed', action)
    assert(string.find(effect, 'illuminated') ~= nil, effect)
    local light = head:FindFirstChild('FlashlightLight')
    assert(light and light:IsA('SpotLight'), 'SpotLight should be parented to Head')
    assert(light.Enabled == true, 'first use should enable light')

    action, effect = ToolUseEffects.applyHeldToolUse(fakePlayerLight, {
        ToolCategory = 'Flashlight',
    }, {})
    assert(light.Enabled == false, 'second use toggles off')
    assert(string.find(effect, 'beam off') ~= nil, effect)

    charModel:Destroy()
end
