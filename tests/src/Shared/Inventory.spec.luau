return function()
    local ReplicatedStorage = game:GetService('ReplicatedStorage')
    local gameplay = require(ReplicatedStorage:WaitForChild('Packages'):WaitForChild('Gameplay'))
    local sharedPackage = ReplicatedStorage:WaitForChild('Packages'):WaitForChild('Shared')
    local items = gameplay.Config.Items
    local inventory = gameplay.Inventory.new(7)
    local inventoryService =
        require(sharedPackage:WaitForChild('Runtime'):WaitForChild('InventoryService')).new(7)
    local fakePlayer = {
        UserId = 101,
    }
    local overweightItem = {
        Id = 'overweight-canister',
        Name = 'Overweight Canister',
        Weight = 5,
        Value = 99,
        Color = Color3.fromRGB(255, 140, 140),
    }
    local toolItem = {
        Id = 'tool-crowbar',
        Name = 'Crowbar',
        Weight = 3,
        Value = 0,
        Color = Color3.fromRGB(200, 200, 200),
        Description = 'Spec crowbar',
        IconAssetId = '',
        ToolTemplateName = 'ToolCrowbar',
        ToolCategory = 'Crowbar',
        StateModel = 'Durability',
        InitialState = 10,
        ConsumePerUse = 0,
        CooldownSeconds = 0.5,
        KnockbackStrength = 15,
    }

    local success, firstEntry = inventory:add(items[2])
    assert(success == true, 'Inventory should accept a low-weight item')
    assert(inventory.Weight == items[2].Weight, 'Inventory weight should increase after add')
    assert(firstEntry.InstanceId == 1, 'Inventory should issue a stable item instance id')
    assert(inventory:getSummary().BackpackCount == 1, 'Picked-up items should enter the backpack')

    local secondSuccess, secondEntry = inventory:add(items[1])
    assert(secondSuccess == true, 'Inventory should accept a second item within capacity')
    assert(secondEntry.InstanceId == 2, 'Second pickup should increment the instance id')

    local equipSuccess, equippedEntry = inventory:equip(firstEntry.InstanceId)
    assert(equipSuccess == true, 'Inventory should equip a valid backpack item')
    assert(
        equippedEntry.InstanceId == firstEntry.InstanceId,
        'Equipping should move the requested item into the held slot'
    )

    local inventorySummary = inventory:getSummary()
    assert(inventorySummary.HeldItem ~= nil, 'Inventory summary should surface the held item')
    assert(
        inventorySummary.HeldItem.InstanceId == firstEntry.InstanceId,
        'Held item summary should match the equipped item'
    )
    assert(
        inventorySummary.BackpackCount == 1 and inventorySummary.HeldCount == 1,
        'Summary should distinguish backpack and held counts'
    )

    local swapSuccess, swappedEntry = inventory:equip(secondEntry.InstanceId)
    assert(swapSuccess == true, 'Equipping another item should swap it into the held slot')
    assert(
        swappedEntry.InstanceId == secondEntry.InstanceId,
        'Second equip should hold the newly requested item'
    )

    local swappedSummary = inventory:getSummary()
    assert(
        swappedSummary.HeldItem.InstanceId == secondEntry.InstanceId,
        'Swap equip should replace the held item'
    )
    assert(
        swappedSummary.BackpackItems[1].InstanceId == firstEntry.InstanceId,
        'Previously held item should return to the backpack after a swap'
    )

    local unequipSuccess, unequippedEntry = inventory:unequip()
    assert(unequipSuccess == true, 'Unequip should move the held item back into the backpack')
    assert(
        unequippedEntry.InstanceId == secondEntry.InstanceId,
        'Unequip should return the previously held item'
    )
    assert(
        inventory:getSummary().HeldItem == nil,
        'Unequip should clear the held slot in the summary'
    )

    local missingItemSuccess, missingItemReason = inventory:equip(999)
    assert(missingItemSuccess == false, 'Inventory should reject unknown item instance ids')
    assert(missingItemReason == 'ItemNotFound', 'Unknown items should expose ItemNotFound')

    local missingHeldSuccess, missingHeldReason = inventory:unequip()
    assert(missingHeldSuccess == false, 'Inventory should reject unequip without a held item')
    assert(missingHeldReason == 'NothingHeld', 'Unequip should expose NothingHeld when empty')

    local thirdSuccess = inventory:add(overweightItem)
    assert(thirdSuccess == false, 'Inventory should reject items that exceed remaining capacity')

    local depositedValue = inventory:getTotalValue()
    assert(
        depositedValue == items[2].Value + items[1].Value,
        'Inventory value should include backpack contents after equip swaps'
    )

    inventory:clear()
    assert(inventory.Weight == 0, 'Inventory clear should reset weight')
    assert(
        inventory:getSummary().BackpackCount == 0 and inventory:getSummary().HeldCount == 0,
        'Inventory clear should reset backpack and held state'
    )

    inventoryService:addPlayer(fakePlayer)
    local servicePickupSuccess, serviceEntry = inventoryService:pickup(fakePlayer, items[4])
    assert(servicePickupSuccess == true, 'Runtime inventory should pick up items for the player')
    local tokenPickupSuccess, tokenEntry = inventoryService:pickup(fakePlayer, items[1])
    assert(tokenPickupSuccess == true, 'Runtime inventory should pick up the starter UGC token')
    assert(
        inventoryService:countByItemId(fakePlayer, items[1].Id) == 1,
        'Runtime inventory should count items by item id'
    )
    local consumedToken, consumedEntry = inventoryService:consumeByItemId(fakePlayer, items[1].Id)
    assert(consumedToken == true, 'Runtime inventory should consume an item by id')
    assert(
        consumedEntry.InstanceId == tokenEntry.InstanceId,
        'Consumed item should match the picked-up token instance id'
    )
    assert(
        inventoryService:countByItemId(fakePlayer, items[1].Id) == 0,
        'Consumed items should no longer be counted in inventory summaries'
    )

    local serviceEquipSuccess = inventoryService:equip(fakePlayer, serviceEntry.InstanceId)
    assert(serviceEquipSuccess == true, 'Runtime inventory should equip a held item')

    local serviceSummary = inventoryService:getSummary(fakePlayer)
    assert(
        serviceSummary.HeldItem.InstanceId == serviceEntry.InstanceId,
        'Runtime inventory summary should expose the held item'
    )
    assert(
        serviceSummary.HeldItem.Light ~= nil,
        'Runtime inventory should preserve held item effect data'
    )
    local toolPlayer = {
        UserId = 202,
    }
    inventoryService:addPlayer(toolPlayer)
    local pickupToolSuccess, pickedToolEntry = inventoryService:pickup(toolPlayer, toolItem)
    assert(pickupToolSuccess == true, 'Runtime inventory should pick up tool items')
    local equipToolSuccess = inventoryService:equip(toolPlayer, pickedToolEntry.InstanceId)
    assert(equipToolSuccess == true, 'Runtime inventory should equip tool items')

    local consumeToolSuccess, consumedHeldTool = inventoryService:consumeHeldItemState(toolPlayer)
    assert(consumeToolSuccess == true, 'Runtime inventory should consume held tool state')
    assert(
        consumedHeldTool.CurrentState == 10,
        'Crowbar with ConsumePerUse 0 should not decrement current state'
    )

    local toolSummary = inventoryService:getSummary(toolPlayer)
    assert(
        toolSummary.HeldItem.CurrentState == 10,
        'Tool state should persist unchanged when ConsumePerUse is 0'
    )
    assert(
        toolSummary.HeldItem.KnockbackStrength == toolItem.KnockbackStrength,
        'Runtime inventory should preserve extended item fields through summaries'
    )
    assert(
        toolSummary.HeldItem.ToolTemplateName == 'ToolCrowbar',
        'Tool presentation template name should round-trip through summaries'
    )

    local toolRoundTrip = gameplay.Inventory.new(7)
    assert(
        toolRoundTrip:loadSummary(toolSummary) == true,
        'Tool summaries should hydrate inventory'
    )
    assert(
        toolRoundTrip:getSummary().HeldItem.ToolTemplateName == 'ToolCrowbar',
        'Hydrated inventory should preserve ToolTemplateName'
    )

    local potionPlayer = {
        UserId = 204,
    }
    inventoryService:addPlayer(potionPlayer)
    local potionDef = {
        Id = 'tool-potion',
        Name = 'Potion',
        Weight = 1,
        Value = 0,
        Color = Color3.fromRGB(236, 72, 153),
        ToolCategory = 'Potion',
        StateModel = 'Charges',
        InitialState = 2,
        CurrentState = 2,
        ConsumePerUse = 1,
        CooldownSeconds = 0,
        HealHealthPips = 2,
    }
    local pickupPotionSuccess, potionEntry = inventoryService:pickup(potionPlayer, potionDef)
    assert(pickupPotionSuccess == true, 'Runtime inventory should pick up potion tool defs')
    local equipPotionSuccess = inventoryService:equip(potionPlayer, potionEntry.InstanceId)
    assert(equipPotionSuccess == true, 'Runtime inventory should equip potion tools')
    local potionSummary = inventoryService:getSummary(potionPlayer)
    assert(
        potionSummary.HeldItem.HealHealthPips == 2,
        'HealHealthPips should round-trip on held potion summaries'
    )

    local cooldownToolPlayer = {
        UserId = 203,
    }
    inventoryService:addPlayer(cooldownToolPlayer)
    local pickupCooldownToolSuccess, cooldownToolEntry =
        inventoryService:pickup(cooldownToolPlayer, toolItem)
    assert(pickupCooldownToolSuccess == true, 'Runtime inventory should pick up cooldown tools')
    local equipCooldownToolSuccess =
        inventoryService:equip(cooldownToolPlayer, cooldownToolEntry.InstanceId)
    assert(equipCooldownToolSuccess == true, 'Runtime inventory should equip cooldown tools')

    local consumeAt100Success = inventoryService:consumeHeldItemState(cooldownToolPlayer, 100)
    assert(consumeAt100Success == true, 'Tool should be usable before entering cooldown')

    local consumeDuringCooldownSuccess, cooldownReason, remainingSeconds =
        inventoryService:consumeHeldItemState(cooldownToolPlayer, 100.2)
    assert(
        consumeDuringCooldownSuccess == false and cooldownReason == 'Cooldown',
        'Tool should reject use attempts during cooldown window'
    )
    assert(
        remainingSeconds > 0 and remainingSeconds <= 0.3,
        'Cooldown rejection should report remaining cooldown seconds'
    )

    local restoredInventory = gameplay.Inventory.new(7)
    local restored = restoredInventory:loadSummary(serviceSummary)
    assert(
        restored == true,
        'Inventory should restore a carried summary from teleport payload data'
    )
    assert(
        restoredInventory:getSummary().HeldItem.InstanceId == serviceEntry.InstanceId,
        'Restored inventory should preserve the held item'
    )
    assert(
        restoredInventory:getSummary().HeldItem.Light ~= nil,
        'Restored inventory should preserve held item light metadata'
    )

    local restoredToolInventory = gameplay.Inventory.new(7)
    local restoredToolSummaryOk = restoredToolInventory:loadSummary(toolSummary)
    assert(
        restoredToolSummaryOk == true,
        'Inventory should restore tool summaries with extended item fields intact'
    )
    assert(
        restoredToolInventory:getSummary().HeldItem.KnockbackStrength == toolItem.KnockbackStrength,
        'Inventory loadSummary should preserve extended item fields copied by the OOP surface'
    )

    local sellInventory = gameplay.Inventory.new(10)
    local sellBackpackSuccess, sellBackpackEntry = sellInventory:add(items[2])
    assert(sellBackpackSuccess == true, 'Sell test inventory should accept a backpack item')
    local soldBackpackSuccess, soldBackpackItem, soldBackpackValue = sellInventory:sell(items[2].Id)
    assert(soldBackpackSuccess == true, 'Inventory should sell matching backpack items by item id')
    assert(
        soldBackpackItem.InstanceId == sellBackpackEntry.InstanceId
            and soldBackpackValue == items[2].Value,
        'Selling from the backpack should return the sold item entry and its value'
    )
    assert(
        sellInventory:getSummary().Count == 0,
        'Selling the only backpack item should remove it from the inventory summary'
    )

    local heldSellSuccess, heldSellEntry = sellInventory:add(toolItem)
    assert(heldSellSuccess == true, 'Sell test inventory should accept a held-item candidate')
    local heldEquipSuccess = sellInventory:equip(heldSellEntry.InstanceId)
    assert(heldEquipSuccess == true, 'Sell test inventory should equip the held-item candidate')
    local soldHeldSuccess, soldHeldItem, soldHeldValue = sellInventory:sell(toolItem.Id)
    assert(soldHeldSuccess == true, 'Inventory should sell a matching held item by item id')
    assert(
        soldHeldItem.InstanceId == heldSellEntry.InstanceId and soldHeldValue == toolItem.Value,
        'Selling a held item should return the held entry and its value'
    )
    assert(
        sellInventory:getSummary().HeldItem == nil,
        'Selling the held item should clear the held slot'
    )

    local serviceSellPlayer = {
        UserId = 204,
    }
    inventoryService:addPlayer(serviceSellPlayer)
    local serviceSellPickupSuccess = inventoryService:pickup(serviceSellPlayer, items[2])
    assert(
        serviceSellPickupSuccess == true,
        'Runtime inventory should pick up items before selling'
    )
    local serviceSoldSuccess, serviceSoldItem, serviceSoldValue =
        inventoryService:sell(serviceSellPlayer, items[2].Id)
    assert(serviceSoldSuccess == true, 'InventoryService should expose the restored sell facade')
    assert(
        serviceSoldItem.Id == items[2].Id and serviceSoldValue == items[2].Value,
        'InventoryService sell should return the sold item and its value'
    )
    assert(
        inventoryService:getSummary(serviceSellPlayer).Count == 0,
        'InventoryService sell should remove the sold item from the player inventory'
    )

    local serviceDepositValue = inventoryService:deposit(fakePlayer)
    assert(
        serviceDepositValue == items[4].Value,
        'Depositing should include the currently held item value'
    )

    local clearedServiceSummary = inventoryService:getSummary(fakePlayer)
    assert(clearedServiceSummary.Count == 0, 'Deposit should clear the inventory count')
    assert(clearedServiceSummary.HeldItem == nil, 'Deposit should clear the held slot')
end
