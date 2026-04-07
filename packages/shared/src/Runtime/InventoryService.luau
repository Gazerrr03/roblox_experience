local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Packages = ReplicatedStorage:WaitForChild('Packages')
local Gameplay = require(Packages:WaitForChild('Gameplay'))

local Inventory = Gameplay.Inventory

local InventoryService = {}
InventoryService.__index = InventoryService

function InventoryService.new(capacity)
    return setmetatable({
        Capacity = capacity,
        ByUserId = {},
    }, InventoryService)
end

function InventoryService:addPlayer(player)
    self.ByUserId[player.UserId] = Inventory.new(self.Capacity)
end

function InventoryService:removePlayer(player)
    self.ByUserId[player.UserId] = nil
end

function InventoryService:get(player)
    return self.ByUserId[player.UserId]
end

function InventoryService:pickup(player, itemDef)
    local inventory = self:get(player)
    if not inventory then
        return false, 'MissingInventory'
    end

    return inventory:add(itemDef)
end

function InventoryService:equip(player, itemInstanceId)
    local inventory = self:get(player)
    if not inventory then
        return false, 'MissingInventory'
    end

    return inventory:equip(itemInstanceId)
end

function InventoryService:unequip(player)
    local inventory = self:get(player)
    if not inventory then
        return false, 'MissingInventory'
    end

    return inventory:unequip()
end

function InventoryService:deposit(player)
    local inventory = self:get(player)
    if not inventory then
        return 0
    end

    local totalValue = inventory:getTotalValue()
    inventory:clear()
    return totalValue
end

function InventoryService:loadSummary(player, summary)
    local inventory = self:get(player)
    if not inventory then
        return false, 'MissingInventory'
    end

    return inventory:loadSummary(summary)
end

function InventoryService:getSummary(player)
    local inventory = self:get(player)
    if not inventory then
        return {
            Capacity = self.Capacity,
            Weight = 0,
            Count = 0,
            BackpackCount = 0,
            HeldCount = 0,
            Value = 0,
            BackpackItems = {},
            HeldItem = nil,
        }
    end

    return inventory:getSummary()
end

function InventoryService:countByItemId(player, itemId)
    local inventory = self:get(player)
    if not inventory then
        return 0
    end

    return inventory:countById(itemId)
end

function InventoryService:consumeByItemId(player, itemId)
    local inventory = self:get(player)
    if not inventory then
        return false, 'MissingInventory'
    end

    return inventory:consumeById(itemId)
end

return InventoryService
