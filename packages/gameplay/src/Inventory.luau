local Inventory = {}
Inventory.__index = Inventory

function Inventory.new(capacity)
    return setmetatable({
        Capacity = capacity,
        Weight = 0,
        Order = {},
    }, Inventory)
end

function Inventory:add(itemDef)
    if self.Weight + itemDef.Weight > self.Capacity then
        return false, 'OverCapacity'
    end

    table.insert(self.Order, itemDef)
    self.Weight += itemDef.Weight
    return true, itemDef
end

function Inventory:getTotalValue()
    local totalValue = 0

    for _, itemDef in ipairs(self.Order) do
        totalValue += itemDef.Value
    end

    return totalValue
end

function Inventory:clear()
    self.Weight = 0
    table.clear(self.Order)
end

return Inventory
