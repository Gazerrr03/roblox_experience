local Inventory = {}
Inventory.__index = Inventory

local function cloneLightConfig(lightConfig)
    if type(lightConfig) ~= 'table' then
        return nil
    end

    return {
        Brightness = lightConfig.Brightness,
        Range = lightConfig.Range,
        Color = lightConfig.Color,
    }
end

-- ItemEntry field groups aligned to the live item payload shape:
-- Core (must-have): InstanceId (handled separately), Id, Name, Value
-- Optional — Weight
-- Optional — Tool state: InitialState, CurrentState, ConsumePerUse, CooldownSeconds, LastUsedAt, ToolCategory, StateModel
-- Optional — Light: Color (Light handled separately via cloneLightConfig)
-- Optional — Melee tool: SwingRange, SwingArcDegrees, KnockbackStrength, MeleeDamage
-- Optional — Consumable: ItemKind, ConsumableEffect, MaxCarryPerId
local ITEM_COPY_FIELDS = table.freeze({
    -- Core
    'Id',
    'Name',
    'Value',
    -- Optional: Weight
    'Weight',
    -- Optional: Tool state
    'InitialState',
    'CurrentState',
    'ConsumePerUse',
    'CooldownSeconds',
    'LastUsedAt',
    'ToolCategory',
    'StateModel',
    -- Optional: Light
    'Color',
    -- Optional: Melee tool
    'SwingRange',
    'SwingArcDegrees',
    'KnockbackStrength',
    'MeleeDamage',
    -- Optional: Consumable
    'ItemKind',
    'ConsumableEffect',
    'MaxCarryPerId',
})

local function copyItemFields(source, target)
    for _, field in ipairs(ITEM_COPY_FIELDS) do
        target[field] = source[field]
    end
    target.Light = cloneLightConfig(source.Light)
    return target
end

local function cloneItemEntry(itemEntry)
    return copyItemFields(itemEntry, {
        InstanceId = itemEntry.InstanceId,
    })
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
        HeldItem = nil,
        NextItemInstanceId = 1,
    }, Inventory)
end

function Inventory:getCount()
    local heldCount = self.HeldItem and 1 or 0
    return #self.BackpackItems + heldCount
end

function Inventory:_buildItemEntry(itemDef)
    local itemEntry = copyItemFields(itemDef, {
        InstanceId = self.NextItemInstanceId,
    })
    itemEntry.CurrentState = itemDef.InitialState

    self.NextItemInstanceId += 1

    return itemEntry
end

local function normalizeItemEntry(rawItemEntry)
    if type(rawItemEntry) ~= 'table' or type(rawItemEntry.InstanceId) ~= 'number' then
        return nil
    end

    local normalized = copyItemFields(rawItemEntry, {
        InstanceId = rawItemEntry.InstanceId,
    })
    normalized.Weight = rawItemEntry.Weight or 0
    normalized.Value = rawItemEntry.Value or 0
    return normalized
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

function Inventory:consumeHeldItemState(nowSeconds)
    local heldItem = self.HeldItem
    if heldItem == nil then
        return false, 'NothingHeld'
    end

    if type(heldItem.CurrentState) ~= 'number' or type(heldItem.ConsumePerUse) ~= 'number' then
        return false, 'NotConsumable'
    end

    local cooldownSeconds = heldItem.CooldownSeconds
    if type(cooldownSeconds) == 'number' and cooldownSeconds > 0 then
        local now = type(nowSeconds) == 'number' and nowSeconds or os.clock()
        local lastUsedAt = heldItem.LastUsedAt
        if type(lastUsedAt) == 'number' and now - lastUsedAt < cooldownSeconds then
            return false, 'Cooldown', cooldownSeconds - (now - lastUsedAt)
        end
    end

    local now = type(nowSeconds) == 'number' and nowSeconds or os.clock()

    if heldItem.ConsumePerUse > 0 then
        if heldItem.CurrentState < heldItem.ConsumePerUse then
            return false, 'Depleted'
        end

        heldItem.CurrentState -= heldItem.ConsumePerUse
    end

    heldItem.LastUsedAt = now

    return true, cloneItemEntry(heldItem)
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

function Inventory:loadSummary(summary)
    if type(summary) ~= 'table' then
        return false, 'InvalidSummary'
    end

    self.Weight = 0
    table.clear(self.BackpackItems)
    self.HeldItem = nil
    self.NextItemInstanceId = 1

    local maxItemInstanceId = 0
    local function processItem(rawItemEntry)
        local itemEntry = normalizeItemEntry(rawItemEntry)
        if itemEntry ~= nil then
            self.Weight += itemEntry.Weight
            if itemEntry.InstanceId > maxItemInstanceId then
                maxItemInstanceId = itemEntry.InstanceId
            end
        end

        return itemEntry
    end

    for _, rawItemEntry in ipairs(summary.BackpackItems or {}) do
        local itemEntry = processItem(rawItemEntry)
        if itemEntry ~= nil then
            table.insert(self.BackpackItems, itemEntry)
        end
    end

    local heldItem = processItem(summary.HeldItem)
    if heldItem ~= nil then
        self.HeldItem = heldItem
    end

    self.NextItemInstanceId = maxItemInstanceId + 1
    return true
end

function Inventory:clear()
    self.Weight = 0
    table.clear(self.BackpackItems)
    self.HeldItem = nil
end

function Inventory:countById(itemId)
    if type(itemId) ~= 'string' or itemId == '' then
        return 0
    end

    local count = 0
    for _, itemEntry in ipairs(self.BackpackItems) do
        if itemEntry.Id == itemId then
            count += 1
        end
    end

    if self.HeldItem and self.HeldItem.Id == itemId then
        count += 1
    end

    return count
end

function Inventory:consumeById(itemId)
    if type(itemId) ~= 'string' or itemId == '' then
        return false, 'MissingItemId'
    end

    for index, itemEntry in ipairs(self.BackpackItems) do
        if itemEntry.Id == itemId then
            local consumed = table.remove(self.BackpackItems, index)
            self.Weight -= consumed.Weight
            return true, cloneItemEntry(consumed)
        end
    end

    if self.HeldItem and self.HeldItem.Id == itemId then
        local consumed = self.HeldItem
        self.HeldItem = nil
        self.Weight -= consumed.Weight
        return true, cloneItemEntry(consumed)
    end

    return false, 'ItemNotFound'
end

function Inventory:sell(itemId)
    if type(itemId) ~= 'string' or itemId == '' then
        return false, 'MissingItemId'
    end

    for index, itemEntry in ipairs(self.BackpackItems) do
        if itemEntry.Id == itemId then
            local sold = table.remove(self.BackpackItems, index)
            self.Weight -= sold.Weight or 0
            return true, cloneItemEntry(sold), sold.Value or 0
        end
    end

    if self.HeldItem and self.HeldItem.Id == itemId then
        local sold = self.HeldItem
        self.HeldItem = nil
        self.Weight -= sold.Weight or 0
        return true, cloneItemEntry(sold), sold.Value or 0
    end

    return false, 'ItemNotFound'
end

return Inventory
