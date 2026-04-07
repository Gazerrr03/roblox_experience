--!strict
--#region Services

local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local UserInputService = game:GetService('UserInputService')
local RunService = game:GetService('RunService')

--#endregion

--#region Requires

local Packages = ReplicatedStorage:WaitForChild('Packages')
local Shared = require(Packages:WaitForChild('Shared'))
local Remotes = Shared.Network.Remotes.waitForScope(Shared.Network.Remotes.Scope.Run)

--#endregion

--#region Module

local ItemClient = {}

local player = Players.LocalPlayer
local currentInteractionTarget = nil
local interactionProximityPrompts = {}

-- ====================
-- 道具功能输入处理
-- ====================

-- 设置手电筒
local function setupFlashlightInput()
    -- F 键切换手电筒
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end

        if input.KeyCode == Enum.KeyCode.F then
            local itemData = Remotes.GetItemData:InvokeServer('Flashlight')
            if itemData and itemData.IsEquipped then
                Remotes.UseItemFunction:FireServer('Flashlight', nil, 'toggle')
            end
        end
    end)
end

-- 设置绳索交互
local function setupRopeInput()
    -- E 键触发绳索交互
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end

        if input.KeyCode == Enum.KeyCode.E and UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
            local itemData = Remotes.GetItemData:InvokeServer('Rope')
            if itemData and itemData.IsEquipped then
                -- 检测最近的交互对象
                local interactables = Remotes.GetInteractables:InvokeServer(10)

                for _, interactable in ipairs(interactables) do
                    local interactionType = interactable:GetAttribute('InteractionType')

                    if interactionType == 'Climbable' then
                        Remotes.UseItemFunction:FireServer('Rope', interactable, 'climb')
                        break
                    elseif interactionType == 'Crossable' then
                        local targetCFrame = interactable:GetAttribute('TargetCFrame')
                        Remotes.UseItemFunction:FireServer('Rope', targetCFrame, 'cross')
                        break
                    end
                end
            end
        end
    end)
end

-- 设置撬棍交互
local function setupCrowbarInput()
    local lastUpdateTime = 0
    local UPDATE_INTERVAL = 0.5

    -- 靠近锁住的对象时自动检测
    RunService.Heartbeat:Connect(function()
        local currentTime = os.clock()

        -- 降低检测频率，避免高频服务器调用
        if currentTime - lastUpdateTime < UPDATE_INTERVAL then
            return
        end
        lastUpdateTime = currentTime

        local itemData = Remotes.GetItemData:InvokeServer('Crowbar')

        if itemData and itemData.IsEquipped then
            local character = player.Character
            if not character or not character.HumanoidRootPart then return end

            local interactables = Remotes.GetInteractables:InvokeServer(5)
            local hasPryable = false

            for _, interactable in ipairs(interactables) do
                local interactionType = interactable:GetAttribute('InteractionType')

                if interactionType == 'Pryable' and not interactable:GetAttribute('PriedOpen') then
                    hasPryable = true
                    currentInteractionTarget = interactable
                    break
                end
            end

            if not hasPryable then
                currentInteractionTarget = nil
            end
        end
    end)

    -- 按键触发撬开
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end

        if input.KeyCode == Enum.KeyCode.E and currentInteractionTarget then
            Remotes.UseItemFunction:FireServer('Crowbar', currentInteractionTarget, 'pry')
        end
    end)
end

-- ====================
-- 视觉提示系统
-- ====================

-- 显示交互提示
local function showInteractionPrompt(part: BasePart, promptText: string)
    -- 创建屏幕提示
    local playerGui = player:WaitForChild('PlayerGui')

    local screenGui = Instance.new('ScreenGui')
    screenGui.Name = 'InteractionPrompt'
    screenGui.Parent = playerGui

    local frame = Instance.new('Frame')
    frame.Name = 'PromptFrame'
    frame.Size = UDim2.new(0, 300, 0, 60)
    frame.Position = UDim2.new(0.5, -150, 0.8, 0)
    frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    frame.BackgroundTransparency = 0.3
    frame.BorderSizePixel = 0
    frame.Parent = screenGui

    local corner = Instance.new('UICorner')
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = frame

    local textLabel = Instance.new('TextLabel')
    textLabel.Name = 'PromptText'
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = promptText
    textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    textLabel.TextSize = 18
    textLabel.Font = Enum.Font.GothamBold
    textLabel.TextWrapped = true
    textLabel.Parent = frame

    -- 3秒后自动消失
    task.delay(3, function()
        screenGui:Destroy()
    end)
end

-- 显示道具使用提示
local function showItemUsageFeedback(itemName: string, action: string, success: boolean)
    local playerGui = player:WaitForChild('PlayerGui')

    local screenGui = Instance.new('ScreenGui')
    screenGui.Name = 'UsageFeedback'
    screenGui.Parent = playerGui

    local frame = Instance.new('Frame')
    frame.Name = 'FeedbackFrame'
    frame.Size = UDim2.new(0, 400, 0, 80)
    frame.Position = UDim2.new(0.5, -200, 0.2, 0)
    frame.BackgroundColor3 = success and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(150, 0, 0)
    frame.BackgroundTransparency = 0.3
    frame.BorderSizePixel = 0
    frame.Parent = screenGui

    local corner = Instance.new('UICorner')
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = frame

    local textLabel = Instance.new('TextLabel')
    textLabel.Name = 'FeedbackText'
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = success and (itemName .. " 使用成功!") or (itemName .. " 使用失败!")
    textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    textLabel.TextSize = 20
    textLabel.Font = Enum.Font.GothamBold
    textLabel.Parent = frame

    -- 淡出动画
    local tween = game:GetService('TweenService'):Create(
        screenGui,
        TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {BackgroundTransparency = 1}
    )
    tween:Play()

    task.delay(2, function()
        screenGui:Destroy()
    end)
end

-- ====================
-- 初始化
-- ====================

function ItemClient.initialize()
    setupFlashlightInput()
    setupRopeInput()
    setupCrowbarInput()

    print("ItemClient 已初始化")
end

-- 监听服务器反馈
Remotes.ItemUsageFeedback.OnClientEvent:Connect(function(itemName: string, action: string, success: boolean)
    showItemUsageFeedback(itemName, action, success)
end)

return ItemClient
