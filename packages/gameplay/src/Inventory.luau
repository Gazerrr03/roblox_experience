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
    -- UI
    'IconLabel',
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
    local equipSlots = table.create(4, nil)
    warn('[Inventory.new] created, EquipSlots length:', #equipSlots)

    return setmetatable({
        Capacity = capacity,
        Weight = 0,
        BackpackItems = backpackItems,
        EquipSlots = equipSlots,
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
    -- 返回4个值以匹配 autoEquipToFirstEmpty 的返回格式
    return true, 'backpack', itemEntry.InstanceId, cloneItemEntry(itemEntry)
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

-- 购买时自动填充装备槽
-- 返回: (成功, 槽类型, 槽索引或物品实例ID, 物品详情)
-- 槽类型: 'equip' = 装备槽, 'backpack' = 背包
function Inventory:autoEquipToFirstEmpty(itemDef)
    -- 注意：#self.EquipSlots 对全nil数组返回0，所以用固定数字4
    warn('[Inventory.autoEquipToFirstEmpty] starting')
    
    -- 查找第一个空装备槽（固定4个槽）
    for i = 1, 4 do
        warn('[Inventory.autoEquipToFirstEmpty] checking slot', i, '=', self.EquipSlots[i])
        if self.EquipSlots[i] == nil then
            warn('[Inventory.autoEquipToFirstEmpty] slot', i, 'is nil, placing item')
            local item = copyItemFields(itemDef, {
                InstanceId = self.NextItemInstanceId,
            })
            item.CurrentState = itemDef.InitialState
            self.EquipSlots[i] = item
            self.Weight += item.Weight  -- 更新总重量
            self.NextItemInstanceId += 1
            return true, 'equip', i, cloneItemEntry(item)
        end
    end

    warn('[Inventory.autoEquipToFirstEmpty] all slots full, going to backpack')
    -- 装备槽满了，放到背包
    return self:add(itemDef)
end

-- 从装备槽卸下物品到背包
function Inventory:unequipFromSlot(slotIndex)
    if slotIndex < 1 or slotIndex > 4 then
        return false, 'InvalidSlot'
    end

    local item = self.EquipSlots[slotIndex]
    if not item then
        return false, 'SlotEmpty'
    end

    -- 放入背包
    if self.Weight + item.Weight > self.Capacity then
        return false, 'OverCapacity'
    end

    self.EquipSlots[slotIndex] = nil
    table.insert(self.BackpackItems, item)
    self.Weight += item.Weight

    return true, cloneItemEntry(item)
end

-- 使用装备槽中的道具
-- 返回: (成功, 结果信息)
function Inventory:useEquipSlot(slotIndex)
    if slotIndex < 1 or slotIndex > 4 then
        return false, 'InvalidSlot'
    end

    local item = self.EquipSlots[slotIndex]
    if not item then
        return false, 'SlotEmpty'
    end

    -- 检查冷却时间
    local now = os.time()
    local cooldown = item.CooldownSeconds or 0
    local lastUsed = item.LastUsedAt or 0
    if now - lastUsed < cooldown then
        local remaining = cooldown - (now - lastUsed)
        return false, 'Cooldown', remaining
    end

    -- 切换型道具（如手电筒 on/off）
    local initialState = item.InitialState
    if initialState == 'on' or initialState == 'off' then
        item.CurrentState = item.CurrentState == 'on' and 'off' or 'on'
        item.LastUsedAt = now
        return true, 'Toggled', cloneItemEntry(item)
    end

    -- 消耗物品状态（如药水剂量）
    local consume = item.ConsumePerUse or 0
    if consume > 0 and item.CurrentState then
        item.CurrentState = item.CurrentState - consume
        if item.CurrentState <= 0 then
            -- 物品用完了，从装备槽移除
            self.EquipSlots[slotIndex] = nil
            return true, 'Consumed', cloneItemEntry(item)
        end
    end

    -- 更新最后使用时间
    item.LastUsedAt = now

    return true, 'Used', cloneItemEntry(item)
end

-- 移动背包物品到另一个格子（支持空格子UI索引）
function Inventory:moveBackpackItem(fromIndex, toIndex)
    local itemCount = #self.BackpackItems
    
    if fromIndex < 1 or fromIndex > itemCount then
        return false, 'InvalidFromSlot'
    end
    if toIndex < 1 then
        return false, 'InvalidToSlot'
    end
    
    if fromIndex == toIndex then
        return true
    end

    if toIndex > itemCount then
        -- 移动到空位置（超过物品数量）
        -- 移除原位置的物品，然后插入到数组末尾
        local item = table.remove(self.BackpackItems, fromIndex)
        table.insert(self.BackpackItems, item)
    else
        -- 交换两个位置的物品
        local temp = self.BackpackItems[fromIndex]
        self.BackpackItems[fromIndex] = self.BackpackItems[toIndex]
        self.BackpackItems[toIndex] = temp
    end

    return true
end

function Inventory:consumeHeldItemState(nowSeconds)
    local heldItem = self.HeldItem
    if heldItem == nil then
        return false, 'NothingHeld'
    end

    if type(heldItem.CurrentState) ~= 'number' or type(heldItem.ConsumePerUse) ~= 'number' then
        return false, 'NotConsumable'
    end

    -- Cooldown check applies to all tools (including zero-consume)
    local cooldownSeconds = heldItem.CooldownSeconds
    if type(cooldownSeconds) == 'number' and cooldownSeconds > 0 then
        local now = type(nowSeconds) == 'number' and nowSeconds or os.clock()
        local lastUsedAt = heldItem.LastUsedAt
        if type(lastUsedAt) == 'number' and now - lastUsedAt < cooldownSeconds then
            return false, 'Cooldown', cooldownSeconds - (now - lastUsedAt)
        end
    end

    local now = type(nowSeconds) == 'number' and nowSeconds or os.clock()

    -- Consume state only when ConsumePerUse > 0
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
    -- 克隆装备槽数据（固定4个槽，因为ipairs在nil处停止）
    local equipSlotsData = {}
    for i = 1, 4 do
        local item = self.EquipSlots[i]
        equipSlotsData[i] = item and cloneItemEntry(item) or nil
    end

    return {
        Capacity = self.Capacity,
        Weight = self.Weight,
        Count = self:getCount(),
        BackpackCount = #self.BackpackItems,
        HeldCount = self.HeldItem and 1 or 0,
        Value = self:getTotalValue(),
        BackpackItems = cloneArray(self.BackpackItems),
        EquipSlots = equipSlotsData,
        HeldItem = self.HeldItem and cloneItemEntry(self.HeldItem) or nil,
    }
end

function Inventory:loadSummary(summary)
    if type(summary) ~= 'table' then
        return false, 'InvalidSummary'
    end

    self.Weight = 0
    table.clear(self.BackpackItems)
    self.EquipSlots = table.create(4, nil)
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

    -- 加载装备槽（固定4个槽，因为ipairs在nil处停止）
    for i = 1, 4 do
        local rawItemEntry = summary.EquipSlots and summary.EquipSlots[i]
        self.EquipSlots[i] = processItem(rawItemEntry)
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
    self.EquipSlots = table.create(4, nil)
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
