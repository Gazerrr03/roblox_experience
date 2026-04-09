local InventoryComponent = {}
InventoryComponent.__index = InventoryComponent

function InventoryComponent.new()
    return setmetatable({}, InventoryComponent)
end

function InventoryComponent:init(blackboard)
    local config = blackboard.Context.ComponentConfig.Inventory or {}

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

<<<<<<< HEAD
function InventoryComponent:removeItem(blackboard, slotIndex)
=======
function InventoryComponent:removeItem(blackboard, slotIndex)
>>>>>>> af646b4 (feat(player): add Player OOP system with component architecture)
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

<<<<<<< HEAD
function InventoryComponent:update(blackboard, dt)
=======
function InventoryComponent:update(blackboard, dt)
>>>>>>> af646b4 (feat(player): add Player OOP system with component architecture)
    blackboard.Transient.Slots = self.Slots
    blackboard.Transient.EquippedSlot = self.EquippedSlot
    blackboard.Transient.InteractionRange = self.InteractionRange
end

function InventoryComponent:destroy(_blackboard) end

return InventoryComponent
