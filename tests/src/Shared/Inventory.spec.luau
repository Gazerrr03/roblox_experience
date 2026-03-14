return function()
    local ReplicatedStorage = game:GetService('ReplicatedStorage')
    local gameplay = require(ReplicatedStorage:WaitForChild('Packages'):WaitForChild('Gameplay'))
    local items = gameplay.Config.Items
    local inventory = gameplay.Inventory.new(5)

    local success = inventory:add(items[2])
    assert(success == true, 'Inventory should accept a low-weight item')
    assert(inventory.Weight == items[2].Weight, 'Inventory weight should increase after add')

    local secondSuccess = inventory:add(items[3])
    assert(secondSuccess == false, 'Inventory should reject an item that exceeds capacity')

    local depositedValue = inventory:getTotalValue()
    assert(depositedValue == items[2].Value, 'Inventory value should match stored item value')

    inventory:clear()
    assert(inventory.Weight == 0, 'Inventory clear should reset weight')
end
