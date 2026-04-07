--!strict
--#region Services

local Players = game:GetService('Players')
local UserInputService = game:GetService('UserInputService')
local ReplicatedStorage = game:GetService('ReplicatedStorage')

--#endregion

--#region Requires

local Packages = ReplicatedStorage:WaitForChild('Packages')
local Shared = require(Packages:WaitForChild('Shared'))
local Remotes = Shared.Network.Remotes.waitForScope(Shared.Network.Remotes.Scope.Run)

--#endregion

--#region Module

local BackpackUI = {}

-- 道具描述映射
local ItemDescriptions = {
    BurningTorch = '点燃倒塌的灯塔',
    Flashlight = '照亮黑暗区域（按F键开关）',
    Rope = '攀爬高处、跨越断层、固定怪物',
    Crowbar = '撬开锁住的箱子/门',
}

-- 创建背包 UI
function BackpackUI.createUI()
    -- ScreenGui
    local screenGui = Instance.new('ScreenGui')
    screenGui.Name = 'BackpackUI'
    screenGui.ResetOnSpawn = false
    screenGui.Parent = Players.LocalPlayer:WaitForChild('PlayerGui')

    -- 背包主框架（默认隐藏）
    local backpackFrame = Instance.new('Frame')
    backpackFrame.Name = 'BackpackFrame'
    backpackFrame.Size = UDim2.new(0, 500, 0, 400)
    backpackFrame.Position = UDim2.new(0.5, -250, 0.5, -200)
    backpackFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    backpackFrame.BorderSizePixel = 0
    backpackFrame.Visible = false
    backpackFrame.Parent = screenGui

    -- 背包标题
    local titleLabel = Instance.new('TextLabel')
    titleLabel.Name = 'TitleLabel'
    titleLabel.Size = UDim2.new(1, 0, 0, 50)
    titleLabel.Position = UDim2.new(0, 0, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = '背包'
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextSize = 28
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Parent = backpackFrame

    -- 关闭按钮
    local closeButton = Instance.new('TextButton')
    closeButton.Name = 'CloseButton'
    closeButton.Size = UDim2.new(0, 50, 0, 50)
    closeButton.Position = UDim2.new(1, -50, 0, 0)
    closeButton.BackgroundTransparency = 1
    closeButton.Text = '✕'
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.TextSize = 28
    closeButton.Font = Enum.Font.GothamBold
    closeButton.Parent = backpackFrame

    closeButton.MouseButton1Click:Connect(function()
        BackpackUI.hide()
    end)

    -- 道具容器
    local itemContainer = Instance.new('ScrollingFrame')
    itemContainer.Name = 'ItemContainer'
    itemContainer.Size = UDim2.new(1, -20, 1, -60)
    itemContainer.Position = UDim2.new(0, 10, 0, 60)
    itemContainer.BackgroundTransparency = 1
    itemContainer.ScrollBarThickness = 8
    itemContainer.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
    itemContainer.Parent = backpackFrame

    -- 分隔线
    local divider = Instance.new('Frame')
    divider.Name = 'Divider'
    divider.Size = UDim2.new(1, 0, 0, 2)
    divider.Position = UDim2.new(0, 0, 0, 50)
    divider.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
    divider.BorderSizePixel = 0
    divider.Parent = backpackFrame

    -- 保存引用
    BackpackUI.ScreenGui = screenGui
    BackpackUI.BackpackFrame = backpackFrame
    BackpackUI.ItemContainer = itemContainer
    BackpackUI.CloseButton = closeButton

    return screenGui
end

-- 创建道具卡片
function BackpackUI.createItemCard(itemName: string, itemData: { [string]: any }): Frame
    local card = Instance.new('Frame')
    card.Name = itemName .. 'Card'
    card.Size = UDim2.new(1, -10, 0, 80)
    card.Position = UDim2.new(0, 5, 0, 0)
    card.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    card.BorderSizePixel = 0
    card.Parent = BackpackUI.ItemContainer

    -- 道具图标（占位）
    local icon = Instance.new('Frame')
    icon.Name = 'Icon'
    icon.Size = UDim2.new(0, 60, 0, 60)
    icon.Position = UDim2.new(0, 10, 0.5, -30)
    icon.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    icon.BorderSizePixel = 0
    icon.Parent = card

    -- 道具名称
    local nameLabel = Instance.new('TextLabel')
    nameLabel.Name = 'NameLabel'
    nameLabel.Size = UDim2.new(1, -80, 0, 30)
    nameLabel.Position = UDim2.new(0, 80, 0, 10)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = itemData.Name or itemName
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextSize = 20
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = card

    -- 道具描述
    local descLabel = Instance.new('TextLabel')
    descLabel.Name = 'DescLabel'
    descLabel.Size = UDim2.new(1, -80, 0, 20)
    descLabel.Position = UDim2.new(0, 80, 0, 35)
    descLabel.BackgroundTransparency = 1
    descLabel.Text = ItemDescriptions[itemName] or itemData.Description or ''
    descLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
    descLabel.TextSize = 14
    descLabel.Font = Enum.Font.Gotham
    descLabel.TextXAlignment = Enum.TextXAlignment.Left
    descLabel.Parent = card

    -- 装备状态
    local statusLabel = Instance.new('TextLabel')
    statusLabel.Name = 'StatusLabel'
    statusLabel.Size = UDim2.new(0, 80, 0, 30)
    statusLabel.Position = UDim2.new(1, -90, 0, 10)
    statusLabel.BackgroundColor3 = itemData.IsEquipped and Color3.fromRGB(100, 200, 100)
        or Color3.fromRGB(80, 80, 90)
    statusLabel.BorderSizePixel = 0
    statusLabel.Text = itemData.IsEquipped and '已装备' or '未装备'
    statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    statusLabel.TextSize = 14
    statusLabel.Font = Enum.Font.GothamBold
    statusLabel.Parent = card

    -- 装备/卸下按钮
    local equipButton = Instance.new('TextButton')
    equipButton.Name = 'EquipButton'
    equipButton.Size = UDim2.new(0, 80, 0, 30)
    equipButton.Position = UDim2.new(1, -90, 0, 45)
    equipButton.BackgroundColor3 = Color3.fromRGB(100, 100, 120)
    equipButton.BorderSizePixel = 0
    equipButton.Text = itemData.IsEquipped and '卸下' or '装备'
    equipButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    equipButton.TextSize = 14
    equipButton.Font = Enum.Font.GothamBold
    equipButton.Parent = card

    equipButton.MouseButton1Click:Connect(function()
        if itemData.IsEquipped then
            Remotes.EquipItem:FireServer(itemName, false)
        else
            Remotes.EquipItem:FireServer(itemName, true)
        end
        -- 刷新背包显示
        BackpackUI.refresh()
    end)

    return card
end

-- 刷新背包显示
function BackpackUI.refresh()
    if not BackpackUI.ScreenGui then
        return
    end

    -- 清空道具容器
    for _, child in ipairs(BackpackUI.ItemContainer:GetChildren()) do
        if child:IsA('Frame') then
            child:Destroy()
        end
    end

    -- 从服务器获取背包数据
    local inventory = Remotes.GetInventory:InvokeServer()

    if not inventory or next(inventory) == nil then
        -- 背包为空提示
        local emptyLabel = Instance.new('TextLabel')
        emptyLabel.Size = UDim2.new(1, 0, 0, 50)
        emptyLabel.Position = UDim2.new(0, 0, 0.5, -25)
        emptyLabel.BackgroundTransparency = 1
        emptyLabel.Text = '背包是空的，去收集道具吧！'
        emptyLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
        emptyLabel.TextSize = 18
        emptyLabel.Font = Enum.Font.Gotham
        emptyLabel.Parent = BackpackUI.ItemContainer
        return
    end

    -- 显示道具列表
    local yOffset = 0
    for itemName, itemData in pairs(inventory) do
        local card = BackpackUI.createItemCard(itemName, itemData)
        card.Position = UDim2.new(0, 5, 0, yOffset)
        yOffset = yOffset + 90
    end

    -- 更新容器大小
    BackpackUI.ItemContainer.CanvasSize = UDim2.new(1, 0, 0, yOffset)
end

-- 显示背包
function BackpackUI.show()
    if not BackpackUI.ScreenGui then
        BackpackUI.createUI()
    end

    BackpackUI.BackpackFrame.Visible = true
    BackpackUI.refresh()
end

-- 隐藏背包
function BackpackUI.hide()
    if BackpackUI.ScreenGui then
        BackpackUI.BackpackFrame.Visible = false
    end
end

-- 切换背包显示状态
function BackpackUI.toggle()
    if BackpackUI.BackpackFrame and BackpackUI.BackpackFrame.Visible then
        BackpackUI.hide()
    else
        BackpackUI.show()
    end
end

-- 初始化
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then
        return
    end

    if input.KeyCode == Enum.KeyCode.B then
        BackpackUI.toggle()
    end

    if input.KeyCode == Enum.KeyCode.ButtonY then -- 手柄 Y 键
        BackpackUI.toggle()
    end
end)

return BackpackUI
