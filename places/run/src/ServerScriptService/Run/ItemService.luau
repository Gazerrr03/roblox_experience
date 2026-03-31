--!strict
--#region Types

export type PlayerData = {
    Inventory: {[string]: ItemData},
}

export type ItemData = {
    Name: string,
    Type: string,
    Description: string,
    IsEquipped: boolean,
    IsActive: boolean,
}

--#endregion

--#region Services

local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService('RunService')

--#endregion

--#region Requires

local Packages = ReplicatedStorage:WaitForChild('Packages')
local Shared = require(Packages:WaitForChild('Shared'))
local Remotes = Shared.Network.Remotes.waitForScope(Shared.Network.Remotes.Scope.Run)

--#endregion

--#region Module

local ItemService = {}

-- 道具定义
ItemService.Items = {
    BurningTorch = {
        Name = "燃烧的火把",
        Type = "Tool",
        Description = "点燃倒塌的灯塔",
        IsEquipped = false,
        IsActive = false,
    },
    Flashlight = {
        Name = "手电筒",
        Type = "Tool",
        Description = "照亮黑暗区域",
        IsEquipped = false,
        IsActive = false,
    },
    Rope = {
        Name = "绳索",
        Type = "Tool",
        Description = "攀爬高处、跨越断层、固定怪物",
        IsEquipped = false,
        IsActive = false,
    },
    Crowbar = {
        Name = "撬棍",
        Type = "Tool",
        Description = "撬开锁住的箱子/门",
        IsEquipped = false,
        IsActive = false,
    },
}

-- 玩家数据存储
ItemService.PlayerData = {}

-- 初始化玩家数据
function ItemService.initPlayer(player: Player)
    ItemService.PlayerData[player.UserId] = {
        Inventory = {},
    }
end

-- 清理玩家数据
function ItemService.cleanupPlayer(player: Player)
    ItemService.PlayerData[player.UserId] = nil
end

-- 检查玩家是否拥有道具
function ItemService.hasItem(player: Player, itemName: string): boolean
    local data = ItemService.PlayerData[player.UserId]
    if not data then
        return false
    end
    return data.Inventory[itemName] ~= nil
end

-- 获得道具
function ItemService.giveItem(player: Player, itemName: string): boolean
    if not ItemService.Items[itemName] then
        warn("Item not found: " .. itemName)
        return false
    end

    local data = ItemService.PlayerData[player.UserId]
    if not data then
        return false
    end

    -- 如果已经拥有该道具，不重复获得
    if data.Inventory[itemName] then
        return false
    end

    -- 创建道具数据
    local itemData = table.clone(ItemService.Items[itemName])
    data.Inventory[itemName] = itemData

    print(player.Name .. " 获得了道具: " .. itemName)
    return true
end

-- 装备道具
function ItemService.equipItem(player: Player, itemName: string): boolean
    local data = ItemService.PlayerData[player.UserId]
    if not data or not data.Inventory[itemName] then
        return false
    end

    -- 卸下其他已装备的道具
    for name, item in data.Inventory do
        if item.IsEquipped then
            item.IsEquipped = false
        end
    end

    -- 装备指定道具
    data.Inventory[itemName].IsEquipped = true
    return true
end

-- 卸下道具
function ItemService.unequipItem(player: Player, itemName: string): boolean
    local data = ItemService.PlayerData[player.UserId]
    if not data or not data.Inventory[itemName] then
        return false
    end

    data.Inventory[itemName].IsEquipped = false
    return true
end

-- 激活道具（如手电筒开关）
function ItemService.toggleItemActive(player: Player, itemName: string): boolean
    local data = ItemService.PlayerData[player.UserId]
    if not data or not data.Inventory[itemName] then
        return false
    end

    local currentState = data.Inventory[itemName].IsActive
    data.Inventory[itemName].IsActive = not currentState

    return not currentState -- 返回新的状态
end

-- 获取道具状态
function ItemService.getItemData(player: Player, itemName: string): ItemData?
    local data = ItemService.PlayerData[player.UserId]
    if not data then
        return nil
    end
    return data.Inventory[itemName]
end

-- 获取玩家背包
function ItemService.getInventory(player: Player): {[string]: ItemData}
    local data = ItemService.PlayerData[player.UserId]
    if not data then
        return {}
    end
    return data.Inventory
end

-- 初始化服务
Players.PlayerAdded:Connect(function(player)
    ItemService.initPlayer(player)
end)

Players.PlayerRemoving:Connect(function(player)
    ItemService.cleanupPlayer(player)
end)

-- ==================== 网络事件处理 ====================

-- 获取背包数据
Remotes.GetInventory.OnServerInvoke = function(player: Player): {[string]: ItemData}
    return ItemService.getInventory(player)
end

-- 装备/卸下道具
Remotes.EquipItem.OnServerEvent:Connect(function(player: Player, itemName: string, equip: boolean)
    if equip then
        local success = ItemService.equipItem(player, itemName)
        if success then
            print(player.Name .. " 装备了: " .. itemName)
        end
    else
        local success = ItemService.unequipItem(player, itemName)
        if success then
            print(player.Name .. " 卸下了: " .. itemName)
        end
    end
end)

-- 使用道具
Remotes.UseItem.OnServerEvent:Connect(function(player: Player, itemName: string)
    local success = ItemService.toggleItemActive(player, itemName)
    if success then
        local itemData = ItemService.getItemData(player, itemName)
        if itemData then
            print(player.Name .. " 使用了: " .. itemName .. " (状态: " .. tostring(itemData.IsActive) .. ")")
        end
    end
end)

return ItemService
