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

    local thirdSuccess = inventory:add(items[3])
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
    local servicePickupSuccess, serviceEntry = inventoryService:pickup(fakePlayer, items[2])
    assert(servicePickupSuccess == true, 'Runtime inventory should pick up items for the player')

    local serviceEquipSuccess = inventoryService:equip(fakePlayer, serviceEntry.InstanceId)
    assert(serviceEquipSuccess == true, 'Runtime inventory should equip a held item')

    local serviceSummary = inventoryService:getSummary(fakePlayer)
    assert(
        serviceSummary.HeldItem.InstanceId == serviceEntry.InstanceId,
        'Runtime inventory summary should expose the held item'
    )

    local serviceDepositValue = inventoryService:deposit(fakePlayer)
    assert(
        serviceDepositValue == items[2].Value,
        'Depositing should include the currently held item value'
    )

    local clearedServiceSummary = inventoryService:getSummary(fakePlayer)
    assert(clearedServiceSummary.Count == 0, 'Deposit should clear the inventory count')
    assert(clearedServiceSummary.HeldItem == nil, 'Deposit should clear the held slot')
end
