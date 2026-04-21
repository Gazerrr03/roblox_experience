local ItemFields = require(script.Parent.Config.ItemFields)

local Inventory = {}
Inventory.__index = Inventory

local function cloneItemEntry(itemEntry)
    return ItemFields.copyItemEntry(itemEntry)
end

local function cloneArray(items)
    local result = {}

    for index, itemEntry in ipairs(items) do
        result[index] = cloneItemEntry(itemEntry)
    end

    return result
end

local function getItemCategory(itemEntry)
    if type(itemEntry.ItemCategory) == 'string' and itemEntry.ItemCategory ~= '' then
        return itemEntry.ItemCategory
    end

    if type(itemEntry.ToolCategory) == 'string' and itemEntry.ToolCategory ~= '' then
        return 'Tool'
    end

    return 'Loot'
end

local function getMissionCount(itemEntry)
    if type(itemEntry.MissionCount) == 'number' then
        return itemEntry.MissionCount
    end

    if getItemCategory(itemEntry) == 'Loot' then
        return 1
    end

    return 0
end

local function normalizeItemEntry(rawItemEntry)
    return ItemFields.normalizeItemEntryForLoad(rawItemEntry)
end

function Inventory.new(capacity)
    return setmetatable({
        Capacity = capacity,
        Weight = 0,
        BackpackItems = {},
        HeldItem = nil,
        NextItemInstanceId = 1,
    }, Inventory)
end

function Inventory:getCount()
    local heldCount = self.HeldItem and 1 or 0
    return #self.BackpackItems + heldCount
end

function Inventory:_hasCapacityFor(additionalCount)
    local nextCount = self:getCount() + (additionalCount or 1)
    return nextCount <= self.Capacity
end

function Inventory:_buildItemEntry(itemDef)
    local instanceId = self.NextItemInstanceId
    self.NextItemInstanceId += 1

    return ItemFields.copyItemEntry({
        InstanceId = instanceId,
        Id = itemDef.Id,
        Name = itemDef.Name,
        Weight = itemDef.Weight,
        Value = itemDef.Value,
        Color = itemDef.Color,
        Light = itemDef.Light,
        Description = itemDef.Description,
        IconAssetId = itemDef.IconAssetId,
        ToolTemplateName = itemDef.ToolTemplateName,
        ToolCategory = itemDef.ToolCategory,
        StateModel = itemDef.StateModel,
        InitialState = itemDef.InitialState,
        CurrentState = itemDef.CurrentState or itemDef.InitialState,
        ConsumePerUse = itemDef.ConsumePerUse,
        CooldownSeconds = itemDef.CooldownSeconds,
        LastUsedAt = itemDef.LastUsedAt,
        SwingRange = itemDef.SwingRange,
        SwingArcDegrees = itemDef.SwingArcDegrees,
        KnockbackStrength = itemDef.KnockbackStrength,
        MeleeDamage = itemDef.MeleeDamage,
        HealHealthPips = itemDef.HealHealthPips,
        ItemCategory = itemDef.ItemCategory,
        MissionCount = itemDef.MissionCount,
        ReadableTitle = itemDef.ReadableTitle,
        ReadableText = itemDef.ReadableText,
        ClueId = itemDef.ClueId,
        ThreatHintId = itemDef.ThreatHintId,
        SourceMarkerId = itemDef.SourceMarkerId,
    })
end

function Inventory:add(itemDef)
    if not self:_hasCapacityFor(1) then
        return false, 'InventoryFull'
    end

    local itemEntry = self:_buildItemEntry(itemDef)
    table.insert(self.BackpackItems, itemEntry)
    return true, cloneItemEntry(itemEntry)
end

function Inventory:addEntry(rawItemEntry)
    if not self:_hasCapacityFor(1) then
        return false, 'InventoryFull'
    end

    local itemEntry = normalizeItemEntry(rawItemEntry)
    if itemEntry == nil then
        return false, 'InvalidItemEntry'
    end

    if itemEntry.InstanceId >= self.NextItemInstanceId then
        self.NextItemInstanceId = itemEntry.InstanceId + 1
    end

    table.insert(self.BackpackItems, itemEntry)
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

    local now = type(nowSeconds) == 'number' and nowSeconds or os.clock()
    local cooldownSeconds = heldItem.CooldownSeconds
    if type(cooldownSeconds) == 'number' and cooldownSeconds > 0 then
        local lastUsedAt = heldItem.LastUsedAt
        if type(lastUsedAt) == 'number' and now - lastUsedAt < cooldownSeconds then
            return false, 'Cooldown', cooldownSeconds - (now - lastUsedAt)
        end
    end

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
    return 0
end

function Inventory:_summarizeCategories()
    local counts = {
        LootCount = 0,
        ClueCount = 0,
        ToolCount = 0,
        MissionCount = 0,
    }

    local function addItem(itemEntry)
        if itemEntry == nil then
            return
        end

        local itemCategory = getItemCategory(itemEntry)
        if itemCategory == 'Clue' then
            counts.ClueCount += 1
        elseif itemCategory == 'Tool' then
            counts.ToolCount += 1
        else
            counts.LootCount += 1
        end

        counts.MissionCount += getMissionCount(itemEntry)
    end

    for _, itemEntry in ipairs(self.BackpackItems) do
        addItem(itemEntry)
    end

    addItem(self.HeldItem)

    return counts
end

function Inventory:getSummary()
    local categoryCounts = self:_summarizeCategories()

    return {
        Capacity = self.Capacity,
        Weight = 0,
        Count = self:getCount(),
        BackpackCount = #self.BackpackItems,
        HeldCount = self.HeldItem and 1 or 0,
        Value = 0,
        BackpackItems = cloneArray(self.BackpackItems),
        HeldItem = self.HeldItem and cloneItemEntry(self.HeldItem) or nil,
        LootCount = categoryCounts.LootCount,
        ClueCount = categoryCounts.ClueCount,
        ToolCount = categoryCounts.ToolCount,
        MissionCount = categoryCounts.MissionCount,
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
        if itemEntry ~= nil and itemEntry.InstanceId > maxItemInstanceId then
            maxItemInstanceId = itemEntry.InstanceId
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
            return true, cloneItemEntry(consumed)
        end
    end

    if self.HeldItem and self.HeldItem.Id == itemId then
        local consumed = self.HeldItem
        self.HeldItem = nil
        return true, cloneItemEntry(consumed)
    end

    return false, 'ItemNotFound'
end

function Inventory:extractMissionCargo()
    local extracted = {}
    local remaining = {}
    local missionCount = 0

    for _, itemEntry in ipairs(self.BackpackItems) do
        if getMissionCount(itemEntry) > 0 then
            table.insert(extracted, cloneItemEntry(itemEntry))
            missionCount += getMissionCount(itemEntry)
        else
            table.insert(remaining, itemEntry)
        end
    end

    self.BackpackItems = remaining

    if self.HeldItem and getMissionCount(self.HeldItem) > 0 then
        table.insert(extracted, cloneItemEntry(self.HeldItem))
        missionCount += getMissionCount(self.HeldItem)
        self.HeldItem = nil
    end

    return extracted, missionCount
end

function Inventory:dropAllItems()
    local dropped = {}

    for _, itemEntry in ipairs(self.BackpackItems) do
        table.insert(dropped, cloneItemEntry(itemEntry))
    end

    if self.HeldItem ~= nil then
        table.insert(dropped, cloneItemEntry(self.HeldItem))
    end

    self:clear()
    return dropped
end

function Inventory:sell(itemId)
    if type(itemId) ~= 'string' or itemId == '' then
        return false, 'MissingItemId'
    end

    for index, itemEntry in ipairs(self.BackpackItems) do
        if itemEntry.Id == itemId then
            local sold = table.remove(self.BackpackItems, index)
            return true, cloneItemEntry(sold), sold.Value or 0
        end
    end

    if self.HeldItem and self.HeldItem.Id == itemId then
        local sold = self.HeldItem
        self.HeldItem = nil
        return true, cloneItemEntry(sold), sold.Value or 0
    end

    return false, 'ItemNotFound'
end

return Inventory
