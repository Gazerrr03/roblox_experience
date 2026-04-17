return function()
    local ReplicatedStorage = game:GetService('ReplicatedStorage')
    local gameplay = require(ReplicatedStorage:WaitForChild('Packages'):WaitForChild('Gameplay'))

    local PlayerBlackboard = gameplay.Player.PlayerBlackboard
    local InventoryComponent = gameplay.Player.InventoryComponent
    local PlayerComponentConfig = gameplay.Player.PlayerComponentConfig

    local customConfig = PlayerComponentConfig.fromDefinition({
        Components = {
            Inventory = {
                SlotCount = 5,
                InteractionRange = 12,
            },
        },
    })

    local bb = PlayerBlackboard.new(gameplay.Config.Players.DefaultPlayer)
    local inv = InventoryComponent.new()
    bb:beginTick({ ComponentConfig = customConfig })
    inv:init(bb)

    assert(inv.SlotCount == 5, 'Inventory component should honor configured slot count')
    assert(
        inv.InteractionRange == 12,
        'Inventory component should honor configured interaction range'
    )

    bb:beginTick({ ComponentConfig = customConfig })
    inv:update(bb, 0.016)

    assert(bb.Transient.SlotCount == 5, 'Transient slot count should mirror component config')
    assert(
        bb.Transient.InteractionRange == 12,
        'Transient interaction range should mirror component config'
    )

    local defaultConfig = PlayerComponentConfig.fromDefinition({})
    local bbDefaults = PlayerBlackboard.new(gameplay.Config.Players.DefaultPlayer)
    local invDefaults = InventoryComponent.new()
    bbDefaults:beginTick({ ComponentConfig = defaultConfig })
    invDefaults:init(bbDefaults)

    assert(invDefaults.SlotCount == 8, 'Default slot count should match PlayerComponentConfig')
    assert(
        invDefaults.InteractionRange == 5,
        'Default interaction range should match PlayerComponentConfig'
    )
end
