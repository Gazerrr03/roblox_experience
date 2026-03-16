local Inventory = {}
Inventory.__index = Inventory

local function cloneItemEntry(itemEntry)
    return {
        InstanceId = itemEntry.InstanceId,
        Id = itemEntry.Id,
        Name = itemEntry.Name,
        Weight = itemEntry.Weight,
        Value = itemEntry.Value,
        Color = itemEntry.Color,
    }
end

local function cloneArray(items)
    local result = {}

    for index, itemEntry in ipairs(items) do
        result[index] = cloneItemEntry(itemEntry)
    end

    return result
end

function Inventory.new(capacity)
    local backpackItems = {}

    return setmetatable({
        Capacity = capacity,
        Weight = 0,
        BackpackItems = backpackItems,
        Order = backpackItems,
        HeldItem = nil,
        NextItemInstanceId = 1,
    }, Inventory)
end

function Inventory:getCount()
    local heldCount = self.HeldItem and 1 or 0
    return #self.BackpackItems + heldCount
end

function Inventory:_buildItemEntry(itemDef)
    local itemEntry = {
        InstanceId = self.NextItemInstanceId,
        Id = itemDef.Id,
        Name = itemDef.Name,
        Weight = itemDef.Weight,
        Value = itemDef.Value,
        Color = itemDef.Color,
    }

    self.NextItemInstanceId += 1

    return itemEntry
end

function Inventory:add(itemDef)
    if self.Weight + itemDef.Weight > self.Capacity then
        return false, 'OverCapacity'
    end

    local itemEntry = self:_buildItemEntry(itemDef)
    table.insert(self.BackpackItems, itemEntry)
    self.Weight += itemDef.Weight
    return true, cloneItemEntry(itemEntry)
end

function Inventory:equip(itemInstanceId)
    if type(itemInstanceId) ~= 'number' then
        return false, 'MissingItemInstanceId'
    end

    local nextIndex = nil
    for index, itemEntry in ipairs(self.BackpackItems) do
        if itemEntry.InstanceId == itemInstanceId then
            nextIndex = index
            break
        end
    end

    if nextIndex == nil then
        return false, 'ItemNotFound'
    end

    local nextHeldItem = table.remove(self.BackpackItems, nextIndex)
    if self.HeldItem ~= nil then
        table.insert(self.BackpackItems, self.HeldItem)
    end

    self.HeldItem = nextHeldItem
    return true, cloneItemEntry(nextHeldItem)
end

function Inventory:unequip()
    if self.HeldItem == nil then
        return false, 'NothingHeld'
    end

    local previousHeldItem = self.HeldItem
    table.insert(self.BackpackItems, previousHeldItem)
    self.HeldItem = nil

    return true, cloneItemEntry(previousHeldItem)
end

function Inventory:getTotalValue()
    local totalValue = 0

    for _, itemEntry in ipairs(self.BackpackItems) do
        totalValue += itemEntry.Value
    end

    if self.HeldItem ~= nil then
        totalValue += self.HeldItem.Value
    end

    return totalValue
end

function Inventory:getSummary()
    return {
        Capacity = self.Capacity,
        Weight = self.Weight,
        Count = self:getCount(),
        BackpackCount = #self.BackpackItems,
        HeldCount = self.HeldItem and 1 or 0,
        Value = self:getTotalValue(),
        BackpackItems = cloneArray(self.BackpackItems),
        HeldItem = self.HeldItem and cloneItemEntry(self.HeldItem) or nil,
    }
end

function Inventory:clear()
    self.Weight = 0
    table.clear(self.BackpackItems)
    self.HeldItem = nil
end

return Inventory
