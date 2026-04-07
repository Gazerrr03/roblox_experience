-- NarrativeUI
-- 处理叙事文本的UI显示

local Players = game:GetService('Players')
local TweenService = game:GetService('TweenService')

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild('PlayerGui')

local NarrativeUI = {}

-- UI配置
local UI_CONFIG = {
    BackgroundColor = Color3.fromRGB(20, 20, 30),
    TextColor = Color3.fromRGB(220, 220, 220),
    AccentColor = Color3.fromRGB(154, 113, 214),
    Font = Enum.Font.Gotham,
    TextSize = 18,
    TitleSize = 24,
    Padding = 30,
    AnimationDuration = 0.3,
}

local currentNarrativeGui = nil
local isNarrativeVisible = false

-- 创建叙事UI
function NarrativeUI.create()
    if currentNarrativeGui then
        currentNarrativeGui:Destroy()
    end

    local screenGui = Instance.new('ScreenGui')
    screenGui.Name = 'NarrativeUI'
    screenGui.IgnoreGuiInset = true
    screenGui.ResetOnSpawn = false
    screenGui.Parent = playerGui

    -- 背景遮罩
    local background = Instance.new('Frame')
    background.Name = 'Background'
    background.Size = UDim2.fromScale(1, 1)
    background.BackgroundColor3 = Color3.new(0, 0, 0)
    background.BackgroundTransparency = 0.7
    background.BorderSizePixel = 0
    background.Parent = screenGui

    local backgroundFade = Instance.new('UIGradient')
    backgroundFade.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(10, 10, 20)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0)),
    })
    backgroundFade.Rotation = 45
    backgroundFade.Parent = background

    -- 主面板
    local panel = Instance.new('Frame')
    panel.Name = 'Panel'
    panel.AnchorPoint = Vector2.new(0.5, 0.5)
    panel.Position = UDim2.fromScale(0.5, 0.5)
    panel.Size = UDim2.fromOffset(600, 500)
    panel.BackgroundColor3 = UI_CONFIG.BackgroundColor
    panel.BorderSizePixel = 0
    panel.Parent = screenGui

    local corner = Instance.new('UICorner')
    corner.CornerRadius = UDim.new(0, 16)
    corner.Parent = panel

    local padding = Instance.new('UIPadding')
    padding.PaddingTop = UDim.new(0, UI_CONFIG.Padding)
    padding.PaddingLeft = UDim.new(0, UI_CONFIG.Padding)
    padding.PaddingRight = UDim.new(0, UI_CONFIG.Padding)
    padding.PaddingBottom = UDim.new(0, UI_CONFIG.Padding)
    padding.Parent = panel

    local list = Instance.new('UIListLayout')
    list.Padding = UDim.new(0, 16)
    list.Parent = panel

    -- 标题
    local title = Instance.new('TextLabel')
    title.Name = 'Title'
    title.Size = UDim2.new(1, 0, 0, 40)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.TextColor3 = UI_CONFIG.AccentColor
    title.TextSize = UI_CONFIG.TitleSize
    title.Text = 'Fragment of Truth'
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = panel

    -- 内容容器
    local contentContainer = Instance.new('Frame')
    contentContainer.Name = 'ContentContainer'
    contentContainer.Size = UDim2.new(1, 0, 1, -100)
    contentContainer.BackgroundTransparency = 1
    contentContainer.Parent = panel

    local contentList = Instance.new('UIListLayout')
    contentList.Padding = UDim.new(0, 20)
    contentList.Parent = contentContainer

    -- 滚动框
    local scrollFrame = Instance.new('ScrollingFrame')
    scrollFrame.Name = 'ScrollFrame'
    scrollFrame.Size = UDim2.new(1, 0, 1, 0)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.ScrollBarThickness = 6
    scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
    scrollFrame.Parent = contentContainer

    local contentPadding = Instance.new('UIPadding')
    contentPadding.PaddingBottom = UDim.new(0, 20)
    contentPadding.Parent = scrollFrame

    local scrollList = Instance.new('UIListLayout')
    scrollList.Padding = UDim.new(0, 24)
    scrollList.Parent = scrollFrame

    -- 关闭按钮
    local closeButton = Instance.new('TextButton')
    closeButton.Name = 'CloseButton'
    closeButton.Size = UDim2.new(1, 0, 0, 44)
    closeButton.BackgroundColor3 = UI_CONFIG.AccentColor
    closeButton.TextColor3 = Color3.new(1, 1, 1)
    closeButton.Font = Enum.Font.GothamBold
    closeButton.TextSize = 18
    closeButton.Text = 'Continue'
    closeButton.Parent = panel

    local closeCorner = Instance.new('UICorner')
    closeCorner.CornerRadius = UDim.new(0, 10)
    closeCorner.Parent = closeButton

    currentNarrativeGui = screenGui

    return {
        Gui = screenGui,
        Panel = panel,
        Title = title,
        ScrollFrame = scrollFrame,
        ScrollList = scrollList,
        CloseButton = closeButton,
        Background = background,
    }
end

-- 显示叙事文本
function NarrativeUI.show(layer1, layer2, layer3)
    if isNarrativeVisible then
        return
    end

    isNarrativeVisible = true
    local ui = NarrativeUI.create()

    -- 初始状态：完全透明
    ui.Panel.BackgroundTransparency = 1
    ui.Background.BackgroundTransparency = 1
    ui.Background.ImageTransparency = 1
    ui.CloseButton.BackgroundTransparency = 1

    -- 创建文本块
    local textBlocks = {}

    local function createTextBlock(text, isEmphasis)
        local textBlock = Instance.new('TextLabel')
        textBlock.Name = 'TextBlock'
        textBlock.Size = UDim2.new(1, 0, 0, 0)
        textBlock.AutomaticSize = Enum.AutomaticSize.Y
        textBlock.BackgroundTransparency = 1
        textBlock.Font = isEmphasis and Enum.Font.GothamBold or UI_CONFIG.Font
        textBlock.TextColor3 = isEmphasis and UI_CONFIG.AccentColor or UI_CONFIG.TextColor
        textBlock.TextSize = UI_CONFIG.TextSize
        textBlock.Text = text
        textBlock.TextWrapped = true
        textBlock.TextXAlignment = Enum.TextXAlignment.Left
        textBlock.TextYAlignment = Enum.TextYAlignment.Top
        textBlock.Parent = ui.ScrollFrame

        -- 添加分隔线（除了第一个）
        if #textBlocks > 0 then
            local separator = Instance.new('Frame')
            separator.Name = 'Separator'
            separator.Size = UDim2.new(1, 0, 0, 1)
            separator.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
            separator.BackgroundTransparency = 0.5
            separator.BorderSizePixel = 0
            separator.Parent = ui.ScrollFrame
        end

        table.insert(textBlocks, textBlock)
        return textBlock
    end

    -- 显示第一层
    local layer1Text = createTextBlock(layer1 or '')
    layer1Text.Visible = false

    -- 显示第二层（如果有的话）
    local layer2Text = nil
    if layer2 and layer2 ~= '' then
        layer2Text = createTextBlock(layer2, true)
        layer2Text.Visible = false
    end

    -- 显示第三层（如果有的话）
    local layer3Text = nil
    if layer3 and layer3 ~= '' then
        layer3Text = createTextBlock(layer3, true)
        layer3Text.Visible = false
    end

    -- 更新滚动框大小
    ui.ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, ui.ScrollList.AbsoluteContentSize.Y)

    -- 淡入动画
    local fadeInTween = TweenService:Create(
        ui.Panel,
        TweenInfo.new(UI_CONFIG.AnimationDuration, Enum.EasingStyle.Quad),
        {
            BackgroundTransparency = 0,
        }
    )
    local backgroundFadeIn = TweenService:Create(
        ui.Background,
        TweenInfo.new(UI_CONFIG.AnimationDuration, Enum.EasingStyle.Quad),
        {
            BackgroundTransparency = 0.7,
        }
    )
    local buttonFadeIn = TweenService:Create(
        ui.CloseButton,
        TweenInfo.new(UI_CONFIG.AnimationDuration, Enum.EasingStyle.Quad),
        {
            BackgroundTransparency = 0,
        }
    )

    fadeInTween:Play()
    backgroundFadeIn:Play()
    buttonFadeIn:Play()

    -- 显示第一层文本
    task.wait(0.2)
    layer1Text.Visible = true

    -- 显示第二层文本（延迟）
    if layer2Text then
        task.delay(1.5, function()
            layer2Text.Visible = true
            ui.ScrollFrame.CanvasPosition =
                Vector2.new(0, ui.ScrollFrame.CanvasSize.Y.Offset - ui.ScrollFrame.AbsoluteSize.Y)
        end)
    end

    -- 显示第三层文本（延迟）
    if layer3Text then
        task.delay(3.0, function()
            layer3Text.Visible = true
            ui.ScrollFrame.CanvasPosition =
                Vector2.new(0, ui.ScrollFrame.CanvasSize.Y.Offset - ui.ScrollFrame.AbsoluteSize.Y)
        end)
    end

    -- 关闭按钮处理
    local function closeNarrative()
        isNarrativeVisible = false

        -- 淡出动画
        local fadeOutTween = TweenService:Create(
            ui.Panel,
            TweenInfo.new(UI_CONFIG.AnimationDuration, Enum.EasingStyle.Quad),
            {
                BackgroundTransparency = 1,
            }
        )
        local backgroundFadeOut = TweenService:Create(
            ui.Background,
            TweenInfo.new(UI_CONFIG.AnimationDuration, Enum.EasingStyle.Quad),
            {
                BackgroundTransparency = 1,
            }
        )
        local buttonFadeOut = TweenService:Create(
            ui.CloseButton,
            TweenInfo.new(UI_CONFIG.AnimationDuration, Enum.EasingStyle.Quad),
            {
                BackgroundTransparency = 1,
            }
        )

        fadeOutTween:Play()
        backgroundFadeOut:Play()
        buttonFadeOut:Play()

        task.wait(UI_CONFIG.AnimationDuration)
        if currentNarrativeGui then
            currentNarrativeGui:Destroy()
            currentNarrativeGui = nil
        end
    end

    ui.CloseButton.MouseButton1Click:Connect(closeNarrative)

    -- ESC键关闭
    local inputConnection = game:GetService('UserInputService').InputBegan
        :Connect(function(input, gameProcessed)
            if gameProcessed then
                return
            end
            if
                input.KeyCode == Enum.KeyCode.Escape
                or input.KeyCode == Enum.KeyCode.Space
                or input.KeyCode == Enum.KeyCode.Return
            then
                closeNarrative()
            end
        end)

    -- 清理
    ui.Gui.Destroying:Connect(function()
        inputConnection:Disconnect()
    end)
end

return NarrativeUI
