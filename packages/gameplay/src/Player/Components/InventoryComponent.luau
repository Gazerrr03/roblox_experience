local InventoryComponent = {}
InventoryComponent.__index = InventoryComponent

local function getComponentConfig(blackboard, componentName)
    local context = if type(blackboard) == 'table' and type(blackboard.Context) == 'table'
        then blackboard.Context
        else {}
    local componentConfig = if type(context.ComponentConfig) == 'table'
        then context.ComponentConfig
        else {}
    local config = componentConfig[componentName]

    if type(config) == 'table' then
        return config
    end

    return {}
end

function InventoryComponent.new()
    return setmetatable({}, InventoryComponent)
end

function InventoryComponent:init(blackboard)
    local config = getComponentConfig(blackboard, 'Inventory')

    self.SlotCount = config.SlotCount or 8
    self.Slots = table.create(self.SlotCount, nil)
    self.EquippedSlot = nil
    self.InteractionRange = config.InteractionRange or 5
    self.NextInstanceId = 1
end

function InventoryComponent:addItem(blackboard, itemDef)
    local emptySlot = nil
    for i = 1, #self.Slots do
        if self.Slots[i] == nil then
            emptySlot = i
            break
        end
    end

    if not emptySlot then
        return false, 'OverCapacity'
    end

    local instanceId = self.NextInstanceId
    self.NextInstanceId += 1

    self.Slots[emptySlot] = {
        InstanceId = instanceId,
        Id = itemDef.Id,
        Name = itemDef.Name,
        CurrentState = itemDef.InitialState,
        ConsumePerUse = itemDef.ConsumePerUse,
        CooldownSeconds = itemDef.CooldownSeconds,
        LastUsedAt = 0,
    }

    blackboard.Transient.ItemAdded = emptySlot
    return true, instanceId
end

function InventoryComponent:equipSlot(blackboard, slotIndex)
    if slotIndex < 1 or slotIndex > #self.Slots then
        return false, 'InvalidSlot'
    end

    local slot = self.Slots[slotIndex]
    if not slot then
        return false, 'SlotEmpty'
    end

    self.EquippedSlot = slotIndex
    blackboard.Transient.EquippedSlot = slotIndex
    return true, slot
end

function InventoryComponent:unequip(blackboard)
    if not self.EquippedSlot then
        return false, 'NothingEquipped'
    end

    self.EquippedSlot = nil
    blackboard.Transient.EquippedSlot = nil
    return true
end

function InventoryComponent:useItem(blackboard)
    if not self.EquippedSlot then
        return false, 'NothingEquipped'
    end

    local slot = self.Slots[self.EquippedSlot]
    if not slot then
        return false, 'SlotEmpty'
    end

    local now = os.clock()
    local cooldownRemaining = 0
    if slot.CooldownSeconds and slot.CooldownSeconds > 0 then
        cooldownRemaining = math.max(0, slot.LastUsedAt + slot.CooldownSeconds - now)
        if cooldownRemaining > 0 then
            return false, 'OnCooldown', cooldownRemaining
        end
    end

    slot.LastUsedAt = now

    if slot.ConsumePerUse then
        slot.CurrentState = (slot.CurrentState or 0) - slot.ConsumePerUse
        if slot.CurrentState <= 0 then
            self.Slots[self.EquippedSlot] = nil
            self.EquippedSlot = nil
            blackboard.Transient.ItemConsumed = true
        end
    end

    blackboard.Transient.ItemUsed = slot.InstanceId
    return true, slot
end

function InventoryComponent:removeItem(_blackboard, slotIndex)
    if slotIndex < 1 or slotIndex > #self.Slots then
        return false, 'InvalidSlot'
    end

    if not self.Slots[slotIndex] then
        return false, 'SlotEmpty'
    end

    if self.EquippedSlot == slotIndex then
        self.EquippedSlot = nil
    end

    self.Slots[slotIndex] = nil
    return true
end

function InventoryComponent:update(blackboard, _dt)
    blackboard.Transient.Slots = self.Slots
    blackboard.Transient.EquippedSlot = self.EquippedSlot
    blackboard.Transient.InteractionRange = self.InteractionRange
end

function InventoryComponent:destroy(_blackboard) end

return InventoryComponent
