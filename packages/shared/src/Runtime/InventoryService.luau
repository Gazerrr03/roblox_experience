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

function InventoryService:deposit(player)
    local inventory = self:get(player)
    if not inventory then
        return 0
    end

    local totalValue = inventory:getTotalValue()
    inventory:clear()
    return totalValue
end

function InventoryService:reset()
    for _, inventory in pairs(self.ByUserId) do
        inventory:clear()
    end
end

function InventoryService:getSummary(player)
    local inventory = self:get(player)
    if not inventory then
        return {
            Weight = 0,
            Count = 0,
            Value = 0,
        }
    end

    return {
        Weight = inventory.Weight,
        Count = #inventory.Order,
        Value = inventory:getTotalValue(),
    }
end

return InventoryService
