local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService('RunService')
local TweenService = game:GetService('TweenService')
local UserInputService = game:GetService('UserInputService')
local SoundService = game:GetService('SoundService')
local StarterGui = game:GetService('StarterGui')
local Lighting = game:GetService('Lighting')

-- 测试日志：确认同步到正确版本
warn('[同步测试] 这是4.19.2026.04.19-1542版本！库存刷新测试中')

-- 禁用 Roblox 默认背包 UI（~键打开的旧背包）
task.spawn(function()
    local attempts = 0
    repeat
        attempts += 1
        local success = pcall(function()
            StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
        end)
        if success then
            break
        end
        task.wait(0.5)
    until attempts >= 5
end)

-- 音效配置
local SOUND_IDS = {
    Success = 'rbxassetid://9118822222',  -- 成功音效
    Error = 'rbxassetid://9118822223',    -- 错误音效
}

local function playUISound(soundType)
    local soundId = SOUND_IDS[soundType]
    if not soundId then return end
    
    local sound = Instance.new('Sound')
    sound.SoundId = soundId
    sound.Volume = 0.5
    sound.Parent = SoundService
    sound:Play()
    
    sound.Ended:Connect(function()
        sound:Destroy()
    end)
    
    task.delay(3, function()
        if sound and sound.Parent then
            sound:Destroy()
        end
    end)
end

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild('PlayerGui')

local Packages = ReplicatedStorage:WaitForChild('Packages')
local Shared = require(Packages:WaitForChild('Shared'))
local UI = require(Packages:WaitForChild('UI'))

local Remotes = Shared.Network.Remotes.waitForScope(Shared.Network.Remotes.Scope.Run)
local FormalLocomotion = Shared.Runtime.FormalLocomotion
local heldItemController = Shared.Client.HeldItemController.new(localPlayer)
local Theme = UI.Hud.Theme

local TEMPLE_LABEL = 'Temple'
local PAGE_LABEL = 'Pages'
local SAND_BOOK_LABEL = 'Book of Sand'
local SAND_BOOK_PROGRESS_LABEL = 'Book of Sand Progress'

local disconnectFirstPersonLock
local ensureFirstPersonLock
local canRequestMazeEntry = false
local isRunLaunched = false
local isCampPanelVisible = true
local isCampPanelCollapsed = false
local isMouseFree = false
local actionInputConnection
local sprintInputEndedConnection
local isMenuMouseUnlockBound = false
local visibleBackpackItems = {}
local MENU_MOUSE_UNLOCK_STEP = 'RunMenuMouseUnlock'
local MOUSE_TOGGLE_KEY = Enum.KeyCode.LeftAlt

-- 开局隐藏鼠标，等待玩家按 ALT 呼出
local isMouseVisible = false
local teamPages = 0
local goalAmount = 120
local goalProgress = 0
local inventorySummary = nil
local activeShopItems = {}
local activeSalvageItems = {}
local activeModal = nil
local activeBuildFingerprint = 'unknown'
local isInOcean = false
local oceanSlowdownTween = nil
ensureFirstPersonLock = function()
    disconnectFirstPersonLock = Shared.Client.FirstPersonController.start(localPlayer)
    ensureFirstPersonLock = function() end
end

-- 立即启用第一人称并隐藏鼠标图标
ensureFirstPersonLock()
UserInputService.MouseIconEnabled = false

local function bindMenuMouseUnlock()
    if isMenuMouseUnlockBound then
        return
    end

    isMenuMouseUnlockBound = true
    RunService:BindToRenderStep(
        MENU_MOUSE_UNLOCK_STEP,
        Enum.RenderPriority.Camera.Value + 1,
        function()
            localPlayer.CameraMode = Enum.CameraMode.Classic
            localPlayer.CameraMinZoomDistance = 0.5
            localPlayer.CameraMaxZoomDistance = 12
            UserInputService.MouseBehavior = Enum.MouseBehavior.Default
            UserInputService.MouseIconEnabled = true
        end
    )
end

local function unbindMenuMouseUnlock()
    if not isMenuMouseUnlockBound then
        return
    end

    isMenuMouseUnlockBound = false
    RunService:UnbindFromRenderStep(MENU_MOUSE_UNLOCK_STEP)
end

local function releaseFirstPersonLockForMenu()
    if disconnectFirstPersonLock ~= nil then
        disconnectFirstPersonLock()
        disconnectFirstPersonLock = nil
        ensureFirstPersonLock = function()
            disconnectFirstPersonLock = Shared.Client.FirstPersonController.start(localPlayer)
            ensureFirstPersonLock = function() end
        end
    end

    localPlayer.CameraMode = Enum.CameraMode.Classic
    localPlayer.CameraMinZoomDistance = 0.5
    localPlayer.CameraMaxZoomDistance = 12
    UserInputService.MouseBehavior = Enum.MouseBehavior.Default  -- 鼠标自由移动
    UserInputService.MouseIconEnabled = true  -- 显示鼠标图标
end

local function syncMouseMode()
    -- 优先级：UI面板 > ALT切换 > 游戏状态
    -- 打开任何UI面板（商店、任务看板、物资回收）时，释放鼠标让玩家可以点击按钮
    
    if activeModal ~= nil then
        -- 有UI面板打开，释放鼠标锁定
        releaseFirstPersonLockForMenu()
        bindMenuMouseUnlock()
        UserInputService.MouseIconEnabled = true  -- 显示鼠标图标
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default  -- 鼠标自由移动
    elseif isMouseFree then
        -- 玩家按ALT切换到自由鼠标模式
        releaseFirstPersonLockForMenu()
        bindMenuMouseUnlock()
        UserInputService.MouseIconEnabled = true
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
    elseif isRunLaunched then
        -- 游戏运行中，没有UI面板，锁定鼠标（第一人称）
        unbindMenuMouseUnlock()
        ensureFirstPersonLock()
        UserInputService.MouseIconEnabled = false  -- 隐藏鼠标图标
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter  -- 锁定鼠标到屏幕中心
    else
        -- 开局菜单状态，释放鼠标
        releaseFirstPersonLockForMenu()
        bindMenuMouseUnlock()
        UserInputService.MouseIconEnabled = true
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
    end
end

script.Destroying:Connect(function()
    if disconnectFirstPersonLock ~= nil then
        disconnectFirstPersonLock()
        disconnectFirstPersonLock = nil
    end

    if actionInputConnection ~= nil then
        actionInputConnection:Disconnect()
        actionInputConnection = nil
    end

    if sprintInputEndedConnection ~= nil then
        sprintInputEndedConnection:Disconnect()
        sprintInputEndedConnection = nil
    end

    heldItemController:destroy()
    unbindMenuMouseUnlock()
end)

local screenGui = Instance.new('ScreenGui')
screenGui.Name = 'RunHud'
screenGui.IgnoreGuiInset = true
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- ============================================================
-- 所有UI初始化代码包进IIFE，避免顶层local变量占用寄存器
-- ============================================================
local _ui = (function()
-- makeTextLabel 辅助函数
local function makeTextLabel(parent, size, color, textSize, bold)
    local label = Instance.new('TextLabel')
    label.Size = size
    label.BackgroundTransparency = 1
    label.Font = bold and Enum.Font.GothamBold or Theme.Font
    label.TextColor3 = color
    label.TextSize = textSize
    label.TextWrapped = true
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Top
    label.Parent = parent
    return label
end

local function makeButton(parent, text, height, backgroundColor)
    local button = Instance.new('TextButton')
    button.Size = UDim2.new(1, 0, 0, height)
    button.BackgroundColor3 = backgroundColor
    button.TextColor3 = Theme.Background
    button.Font = Enum.Font.GothamBold
    button.TextSize = 18
    button.Text = text
    button.AutoButtonColor = true
    button.Parent = parent

    local corner = Instance.new('UICorner')
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = button

    local stroke = Instance.new('UIStroke')
    stroke.Color = Theme.Background
    stroke.Transparency = 0.65
    stroke.Thickness = 1
    stroke.Parent = button

    local gradient = Instance.new('UIGradient')
    gradient.Rotation = 90
    local base = button.BackgroundColor3
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, base:Lerp(Color3.new(1, 1, 1), 0.08)),
        ColorSequenceKeypoint.new(1, base:Lerp(Color3.new(0, 0, 0), 0.12)),
    })
    gradient.Parent = button

    return button
end

local function clearLayoutChildren(container)
    for _, child in ipairs(container:GetChildren()) do
        if child:IsA('TextButton') or child:IsA('TextLabel') or child:IsA('Frame') then
            if child.Name ~= 'UIListLayout' and child.Name ~= 'UICorner' then
                child:Destroy()
            end
        end
    end
end

local function applyPanelStyle(frame, cornerRadius, strokeTransparency)
    local corner = Instance.new('UICorner')
    corner.CornerRadius = UDim.new(0, cornerRadius)
    corner.Parent = frame

    local stroke = Instance.new('UIStroke')
    stroke.Color = Theme.Text
    stroke.Transparency = strokeTransparency or 0.86
    stroke.Thickness = 1
    stroke.Parent = frame

    local gradient = Instance.new('UIGradient')
    gradient.Rotation = 90
    local base = frame.BackgroundColor3
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, base:Lerp(Color3.new(1, 1, 1), 0.03)),
        ColorSequenceKeypoint.new(1, base:Lerp(Color3.new(0, 0, 0), 0.08)),
    })
    gradient.Parent = frame
end

local function buildMazeEntryText(snapshot)
    local mode = snapshot.MazeEntryMode or 'Blocked'
    local reasonCode = snapshot.MazeEntryReasonCode or 'Unknown'
    local reason = snapshot.MazeEntryReason
    if type(reason) == 'string' and reason ~= '' then
        return string.format('%s [%s] (%s)', mode, reasonCode, reason)
    end

    return string.format('%s [%s]', mode, reasonCode)
end

local function buildFingerprintText(snapshot)
    local fingerprint = snapshot.BuildFingerprint or activeBuildFingerprint or 'unknown'
    return string.format('Build: %s', fingerprint)
end

local function buildSessionPhaseText(snapshot)
    return string.format('Phase: %s', snapshot.SessionPhase or 'RunPrep')
end

local menuBackdrop = Instance.new('Frame')
menuBackdrop.Name = 'StartMenu'
menuBackdrop.Size = UDim2.fromScale(1, 1)
menuBackdrop.BackgroundColor3 = Theme.Background
menuBackdrop.Visible = false  -- 默认隐藏，进入时直接开始游戏
menuBackdrop.Parent = screenGui

local menuBackdropGradient = Instance.new('UIGradient')
menuBackdropGradient.Rotation = 120
menuBackdropGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Theme.Background:Lerp(Color3.new(1, 1, 1), 0.02)),
    ColorSequenceKeypoint.new(1, Theme.Background:Lerp(Color3.new(0, 0, 0), 0.12)),
})
menuBackdropGradient.Parent = menuBackdrop

local menuPanel = Instance.new('Frame')
menuPanel.Name = 'Panel'
menuPanel.AnchorPoint = Vector2.new(0.5, 0.5)
menuPanel.Position = UDim2.fromScale(0.5, 0.5)
menuPanel.Size = UDim2.fromOffset(520, 360)
menuPanel.BackgroundColor3 = Theme.Surface
menuPanel.BorderSizePixel = 0
menuPanel.Parent = menuBackdrop

applyPanelStyle(menuPanel, 18, 0.8)

local menuPadding = Instance.new('UIPadding')
menuPadding.PaddingTop = UDim.new(0, 28)
menuPadding.PaddingLeft = UDim.new(0, 28)
menuPadding.PaddingRight = UDim.new(0, 28)
menuPadding.PaddingBottom = UDim.new(0, 28)
menuPadding.Parent = menuPanel

local menuList = Instance.new('UIListLayout')
menuList.Padding = UDim.new(0, 14)
menuList.Parent = menuPanel

local eyebrow = makeTextLabel(menuPanel, UDim2.new(1, 0, 0, 20), Theme.Accent, 16, true)
eyebrow.Text = 'TEMPLE DIRECT ENTRY'

local menuTitle = makeTextLabel(menuPanel, UDim2.new(1, 0, 0, 72), Theme.Text, 34, true)
menuTitle.Text = string.format('Enter the %s', TEMPLE_LABEL)

local menuBody = makeTextLabel(menuPanel, UDim2.new(1, 0, 0, 78), Theme.SubtleText, 18, false)
menuBody.Text =
    'Run now boots directly into the temple flow. Hold while the camp session syncs, then regroup inside before opening the gate to the wilderness and the shared maze.'

local singlePlayerButton = Instance.new('TextButton')
singlePlayerButton.Size = UDim2.new(1, 0, 0, 52)
singlePlayerButton.BackgroundColor3 = Theme.Accent
singlePlayerButton.TextColor3 = Theme.Background
singlePlayerButton.Font = Enum.Font.GothamBold
singlePlayerButton.TextSize = 20
singlePlayerButton.Text = string.format('Syncing %s...', TEMPLE_LABEL)
singlePlayerButton.Parent = menuPanel
singlePlayerButton.Active = false
singlePlayerButton.AutoButtonColor = false

local singlePlayerCorner = Instance.new('UICorner')
singlePlayerCorner.CornerRadius = UDim.new(0, 12)
singlePlayerCorner.Parent = singlePlayerButton

local singlePlayerStroke = Instance.new('UIStroke')
singlePlayerStroke.Color = Theme.Background
singlePlayerStroke.Transparency = 0.55
singlePlayerStroke.Thickness = 1
singlePlayerStroke.Parent = singlePlayerButton

local singlePlayerGradient = Instance.new('UIGradient')
singlePlayerGradient.Rotation = 90
singlePlayerGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Theme.Accent:Lerp(Color3.new(1, 1, 1), 0.1)),
    ColorSequenceKeypoint.new(1, Theme.Accent:Lerp(Color3.new(0, 0, 0), 0.12)),
})
singlePlayerGradient.Parent = singlePlayerButton

local menuStatusLabel =
    makeTextLabel(menuPanel, UDim2.new(1, 0, 0, 52), Theme.SubtleText, 16, false)
menuStatusLabel.Text = string.format('Preparing %s access...', TEMPLE_LABEL)

local placeholders = Instance.new('Frame')
placeholders.Size = UDim2.new(1, 0, 0, 78)
placeholders.BackgroundTransparency = 1
placeholders.Parent = menuPanel

local placeholderList = Instance.new('UIListLayout')
placeholderList.Padding = UDim.new(0, 10)
placeholderList.FillDirection = Enum.FillDirection.Horizontal
placeholderList.Parent = placeholders

local function makePlaceholder(text)
    local button = Instance.new('TextButton')
    button.Size = UDim2.new(0.5, -5, 1, 0)
    button.BackgroundColor3 = Theme.Background
    button.TextColor3 = Theme.SubtleText
    button.Font = Theme.Font
    button.TextSize = 16
    button.Text = text
    button.AutoButtonColor = false
    button.Active = false
    button.Parent = placeholders

    local corner = Instance.new('UICorner')
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = button
end

makePlaceholder('Temple Shop (Soon)')
makePlaceholder('Shared Maze Gate')

local panel = Instance.new('Frame')
panel.Name = 'CampPanel'
panel.AnchorPoint = Vector2.new(0, 0)
panel.Position = UDim2.fromScale(0.03, 0.05)
panel.Size = UDim2.fromOffset(440, 620)
panel.BackgroundColor3 = Theme.Background
panel.BackgroundTransparency = 0.5
panel.BorderSizePixel = 0
panel.Visible = false
panel.Parent = screenGui

applyPanelStyle(panel, 16, 0.84)

-- 折叠按钮（信息面板右上角，Parent到screenGui避免布局影响）
local collapseButton = Instance.new('TextButton')
collapseButton.Name = 'CollapseButton'
collapseButton.AnchorPoint = Vector2.new(1, 0)
collapseButton.Position = UDim2.new(0, 452, 0, 50)  -- 信息面板在(0.03, 0.05)，宽440，加上偏移
collapseButton.Size = UDim2.fromOffset(28, 28)
collapseButton.BackgroundColor3 = Theme.Surface
collapseButton.TextColor3 = Theme.Text
collapseButton.Font = Enum.Font.GothamBold
collapseButton.TextSize = 16
collapseButton.Text = '−'
collapseButton.Parent = screenGui
collapseButton.ZIndex = 10

local collapseCorner = Instance.new('UICorner')
collapseCorner.CornerRadius = UDim.new(0, 6)
collapseCorner.Parent = collapseButton

local collapseStroke = Instance.new('UIStroke')
collapseStroke.Color = Theme.SubtleText
collapseStroke.Transparency = 0.5
collapseStroke.Thickness = 1
collapseStroke.Parent = collapseButton

-- 折叠后显示的小图标按钮（左上角）
local expandButton = Instance.new('TextButton')
expandButton.Name = 'ExpandButton'
expandButton.AnchorPoint = Vector2.new(0, 0)
expandButton.Position = UDim2.new(0, 21, 0, 67)  -- 再左移8
expandButton.Size = UDim2.fromOffset(36, 36)
expandButton.BackgroundColor3 = Theme.Background
expandButton.TextColor3 = Theme.Text
expandButton.Font = Enum.Font.GothamBold
expandButton.TextSize = 22
expandButton.Text = '+'
expandButton.Visible = false
expandButton.Parent = screenGui

local expandCorner = Instance.new('UICorner')
expandCorner.CornerRadius = UDim.new(0, 8)
expandCorner.Parent = expandButton

local expandStroke = Instance.new('UIStroke')
expandStroke.Color = Theme.Text
expandStroke.Transparency = 0.6
expandStroke.Thickness = 1
expandStroke.Parent = expandButton

local panelPadding = Instance.new('UIPadding')
panelPadding.PaddingTop = UDim.new(0, 18)
panelPadding.PaddingLeft = UDim.new(0, 18)
panelPadding.PaddingRight = UDim.new(0, 36)
panelPadding.PaddingBottom = UDim.new(0, 18)
panelPadding.Parent = panel

local list = Instance.new('UIListLayout')
list.Padding = UDim.new(0, 10)
list.Parent = panel

local title = makeTextLabel(panel, UDim2.new(1, 0, 0, 36), Theme.Text, 28, true)
title.Text = 'Info Panel'

local statusLabel = makeTextLabel(panel, UDim2.new(1, 0, 0, 70), Theme.SubtleText, 18, false)
statusLabel.Text = string.format('Waiting for %s snapshot...', TEMPLE_LABEL)

local objectiveLabel = makeTextLabel(panel, UDim2.new(1, 0, 0, 64), Theme.Accent, 18, false)
objectiveLabel.Text = string.format('%s Objective: --', SAND_BOOK_LABEL)

local guideLabel = makeTextLabel(panel, UDim2.new(1, 0, 0, 60), Theme.Text, 16, false)
guideLabel.Text = string.format(
    'In-world prompts:\n- %s Shop\n- Salvage Exchange\n- %s Board\n- %s Gate / Shared Maze Gate\nKeyboard: Hold LeftShift to sprint, tap C to toggle %s Status, %s to free mouse, 1-3 to equip, X to stow',
    TEMPLE_LABEL,
    SAND_BOOK_LABEL,
    TEMPLE_LABEL,
    TEMPLE_LABEL,
    MOUSE_TOGGLE_KEY.Name
)

local inventoryLabel = makeTextLabel(panel, UDim2.new(1, 0, 0, 44), Theme.Warning, 16, false)
inventoryLabel.Text = 'Inventory: --'

local inventoryDetailLabel = makeTextLabel(panel, UDim2.new(1, 0, 0, 126), Theme.Text, 15, false)
inventoryDetailLabel.Text = ''

local playerStateLabel = makeTextLabel(panel, UDim2.new(1, 0, 0, 86), Theme.Warning, 16, false)
playerStateLabel.Text = 'Health: --\nStamina: --\nState: --\nMovement: --'

local rosterLabel = makeTextLabel(panel, UDim2.new(1, 0, 0, 90), Theme.SubtleText, 16, false)
rosterLabel.Text = ''

local mazeLabel = makeTextLabel(panel, UDim2.new(1, 0, 0, 96), Theme.SubtleText, 16, false)
mazeLabel.Text = ''

local function createModalPanel(name, size)
    local modal = Instance.new('Frame')
    modal.Name = name
    modal.AnchorPoint = Vector2.new(0.5, 0.5)
    modal.Position = UDim2.fromScale(0.5, 0.5)
    modal.Size = size
    modal.BackgroundColor3 = Theme.Surface
    modal.BorderSizePixel = 0
    modal.Visible = false
    modal.Parent = screenGui

    applyPanelStyle(modal, 16, 0.82)

    local modalPadding = Instance.new('UIPadding')
    modalPadding.PaddingTop = UDim.new(0, 18)
    modalPadding.PaddingLeft = UDim.new(0, 18)
    modalPadding.PaddingRight = UDim.new(0, 18)
    modalPadding.PaddingBottom = UDim.new(0, 18)
    modalPadding.Parent = modal

    local modalList = Instance.new('UIListLayout')
    modalList.Padding = UDim.new(0, 10)
    modalList.SortOrder = Enum.SortOrder.LayoutOrder
    modalList.Parent = modal

    return modal, modalList
end

local modalBackdrop = Instance.new('Frame')
modalBackdrop.Name = 'ModalBackdrop'
modalBackdrop.Size = UDim2.fromScale(1, 1)
modalBackdrop.BackgroundColor3 = Color3.new(0, 0, 0)
modalBackdrop.BackgroundTransparency = 0.7
modalBackdrop.Visible = false
modalBackdrop.Parent = screenGui

local oceanSplashOverlay = Instance.new('Frame')
oceanSplashOverlay.Name = 'OceanSplashOverlay'
oceanSplashOverlay.Size = UDim2.fromScale(1, 1)
oceanSplashOverlay.BackgroundColor3 = Color3.fromRGB(60, 176, 255)
oceanSplashOverlay.BackgroundTransparency = 1
oceanSplashOverlay.BorderSizePixel = 0
oceanSplashOverlay.Parent = screenGui

local oceanSplashGradient = Instance.new('UIGradient')
oceanSplashGradient.Rotation = 90
oceanSplashGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(140, 220, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(32, 100, 164)),
})
oceanSplashGradient.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0.1),
    NumberSequenceKeypoint.new(0.45, 0.65),
    NumberSequenceKeypoint.new(1, 0.15),
})
oceanSplashGradient.Parent = oceanSplashOverlay

-- Sustained slowdown overlay (visible while in ocean)
local oceanSlowdownOverlay = Instance.new('Frame')
oceanSlowdownOverlay.Name = 'OceanSlowdownOverlay'
oceanSlowdownOverlay.Size = UDim2.fromScale(1, 1)
oceanSlowdownOverlay.BackgroundColor3 = Color3.fromRGB(60, 176, 255)
oceanSlowdownOverlay.BackgroundTransparency = 1
oceanSlowdownOverlay.BorderSizePixel = 0
oceanSlowdownOverlay.Parent = screenGui

local oceanSlowdownGradient = Instance.new('UIGradient')
oceanSlowdownGradient.Rotation = 90
oceanSlowdownGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(140, 220, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(32, 100, 164)),
})
oceanSlowdownGradient.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0.85),
    NumberSequenceKeypoint.new(1, 0.92),
})
oceanSlowdownGradient.Parent = oceanSlowdownOverlay

-- ============================================
-- 物品图标生成函数
-- ============================================
local function createItemIcon(parent, item, isEquipSlot)
    if not item then return end
    
    local iconText = item.IconLabel or item.Name or '?'
    
    local iconFrame = Instance.new('Frame')
    iconFrame.Name = 'ItemIconFrame'
    if isEquipSlot then
        iconFrame.Size = UDim2.new(0.85, 0, 0.85, 0)
        iconFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
        iconFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    else
        iconFrame.Size = UDim2.new(0.7, 0, 0.7, 0)
        iconFrame.Position = UDim2.fromOffset(0, 2)
    end
    iconFrame.BackgroundTransparency = 1
    iconFrame.Parent = parent

    local iconLabel2 = Instance.new('TextLabel')
    iconLabel2.Size = UDim2.new(1, 0, 1, 0)
    iconLabel2.BackgroundTransparency = 1
    iconLabel2.TextColor3 = Theme.Accent
    iconLabel2.Font = Enum.Font.GothamBold
    iconLabel2.TextSize = isEquipSlot and 32 or 24
    iconLabel2.Text = iconText
    iconLabel2.Parent = iconFrame
end


-- ============================================
-- 左上角生命值显示（两颗爱心）
-- ============================================
local healthDisplay = Instance.new('Frame')
healthDisplay.Name = 'HealthDisplay'
healthDisplay.Size = UDim2.new(0, 100, 0, 36)
healthDisplay.Position = UDim2.new(0, 200, 0, 20)  -- 往右200，下移20
healthDisplay.BackgroundTransparency = 1
healthDisplay.Parent = screenGui

-- 爱心容器（水平排列）
local heart1 = Instance.new('TextLabel')
heart1.Name = 'Heart1'
heart1.Size = UDim2.new(0, 32, 0, 32)
heart1.Position = UDim2.new(0, 0, 0, 2)
heart1.BackgroundTransparency = 1
heart1.TextColor3 = Color3.fromRGB(255, 60, 60)  -- 红色爱心
heart1.Font = Enum.Font.GothamBold
heart1.TextSize = 28
heart1.Text = '❤'
heart1.Parent = healthDisplay

local heart2 = Instance.new('TextLabel')
heart2.Name = 'Heart2'
heart2.Size = UDim2.new(0, 32, 0, 32)
heart2.Position = UDim2.new(0, 36, 0, 2)
heart2.BackgroundTransparency = 1
heart2.TextColor3 = Color3.fromRGB(80, 80, 80)  -- 灰色空爱心
heart2.Font = Enum.Font.GothamBold
heart2.TextSize = 28
heart2.Text = '❤'
heart2.Parent = healthDisplay

-- 更新生命值显示
local FULL_HEART_COLOR = Color3.fromRGB(255, 60, 60)   -- 红色
local EMPTY_HEART_COLOR = Color3.fromRGB(80, 80, 80)   -- 灰色

local function updateHealthDisplay(health, maxHealth)
    local fullHearts = health or 0
    local totalHearts = maxHealth or 2
    
    -- 更新心1
    if fullHearts >= 1 then
        heart1.TextColor3 = FULL_HEART_COLOR
    else
        heart1.TextColor3 = EMPTY_HEART_COLOR
    end
    
    -- 更新心2
    if totalHearts >= 2 then
        heart2.Visible = true
        if fullHearts >= 2 then
            heart2.TextColor3 = FULL_HEART_COLOR
        else
            heart2.TextColor3 = EMPTY_HEART_COLOR
        end
    else
        heart2.Visible = false
    end
end

-- ============================================
-- 右侧常驻装备栏（4格）
-- ============================================
local EQUIP_SLOT_SIZE = 72
local EQUIP_SLOT_PADDING = 8

-- 装备栏容器
local equipPanel = Instance.new('Frame')
equipPanel.Name = 'EquipPanel'
equipPanel.Size = UDim2.new(0, EQUIP_SLOT_SIZE, 0, (EQUIP_SLOT_SIZE + EQUIP_SLOT_PADDING) * 4 - EQUIP_SLOT_PADDING)
equipPanel.Position = UDim2.new(1, -12, 0.5, 0)
equipPanel.AnchorPoint = Vector2.new(1, 0.5)
equipPanel.BackgroundTransparency = 1
equipPanel.Parent = screenGui

-- 装备栏格子数组
local equipSlots = {}
for i = 1, 4 do
    local slot = Instance.new('TextButton')
    slot.Name = 'EquipSlot' .. i
    slot.Size = UDim2.fromOffset(EQUIP_SLOT_SIZE, EQUIP_SLOT_SIZE)
    slot.BackgroundColor3 = Theme.Surface
    slot.BackgroundTransparency = 0.5
    slot.BorderSizePixel = 0
    slot.Text = ''
    slot.LayoutOrder = i
    slot.Parent = equipPanel

    local corner = Instance.new('UICorner')
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = slot

    local stroke = Instance.new('UIStroke')
    stroke.Color = Theme.SubtleText
    stroke.Transparency = 0.7
    stroke.Thickness = 1
    stroke.Parent = slot

    -- 右下角快捷键数字标签
    local keyLabel = Instance.new('TextLabel')
    keyLabel.Name = 'KeyLabel'
    keyLabel.Size = UDim2.new(0, 16, 0, 16)
    keyLabel.Position = UDim2.new(1, -4, 1, -4)
    keyLabel.AnchorPoint = Vector2.new(1, 1)
    keyLabel.BackgroundTransparency = 1
    keyLabel.Text = tostring(i)
    keyLabel.TextColor3 = Theme.SubtleText
    keyLabel.TextSize = 11
    keyLabel.Font = Enum.Font.GothamBold
    keyLabel.ZIndex = 10
    keyLabel.Parent = slot

    equipSlots[i] = slot
    
    -- 装备栏格子点击
    slot.MouseButton1Click:Connect(function()
        -- 背包打开时，禁用装备栏点击
        if isBackpackOpen then
            return
        end
        
        local item = inventorySummary and inventorySummary.EquipSlots and inventorySummary.EquipSlots[i]
        if item then
            -- 背包关闭时，触发道具使用
            Remotes.RunAction:FireServer({
                Type = 'UseEquipSlot',
                SlotIndex = i,
            })
        end
    end)
end

-- 装备栏布局
local equipLayout = Instance.new('UIListLayout')
equipLayout.Padding = UDim.new(0, EQUIP_SLOT_PADDING)
equipLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
equipLayout.VerticalAlignment = Enum.VerticalAlignment.Center
equipLayout.SortOrder = Enum.SortOrder.LayoutOrder
equipLayout.Parent = equipPanel

-- ============================================
-- 背包快捷键提示（右下角）
-- ============================================
local BACKPACK_HINT_SIZE = 50

local backpackHint = Instance.new('Frame')
backpackHint.Name = 'BackpackHint'
backpackHint.Size = UDim2.new(0, 48, 0, 58)
backpackHint.Position = UDim2.new(1, -12, 1, -12)
backpackHint.AnchorPoint = Vector2.new(1, 1)
backpackHint.BackgroundColor3 = Theme.Surface
backpackHint.BackgroundTransparency = 0.2
backpackHint.BorderSizePixel = 0
backpackHint.Parent = screenGui

local backpackHintCorner = Instance.new('UICorner')
backpackHintCorner.CornerRadius = UDim.new(0, 10)
backpackHintCorner.Parent = backpackHint

-- 冒险背包图标（用简洁的图标字符）
local backpackHintIcon = Instance.new('TextLabel')
backpackHintIcon.Name = 'Icon'
backpackHintIcon.Size = UDim2.new(1, 0, 0, 28)
backpackHintIcon.Position = UDim2.new(0, 0, 0, 6)
backpackHintIcon.BackgroundTransparency = 1
backpackHintIcon.Text = '⌨'
backpackHintIcon.TextSize = 24
backpackHintIcon.Font = Enum.Font.GothamBold
backpackHintIcon.TextColor3 = Theme.Text
backpackHintIcon.Parent = backpackHint

-- B键提示
local backpackHintKey = Instance.new('TextLabel')
backpackHintKey.Name = 'KeyLabel'
backpackHintKey.Size = UDim2.new(1, -8, 0, 14)
backpackHintKey.Position = UDim2.new(0.5, 0, 1, -10)
backpackHintKey.AnchorPoint = Vector2.new(0.5, 1)
backpackHintKey.BackgroundTransparency = 1
backpackHintKey.Text = 'B'
backpackHintKey.TextSize = 12
backpackHintKey.Font = Enum.Font.GothamBold
backpackHintKey.TextColor3 = Theme.Warning
backpackHintKey.Parent = backpackHint

-- ============================================
-- 手电筒照明系统
-- ============================================
local currentFlashlight = nil  -- 当前激活的手电筒 SpotLight

-- ============================================
-- 手持道具渲染系统
-- ============================================
local currentHeldTool = nil  -- 当前手持的道具模型

local function renderHeldTool(equipSlotsData)
    local player = Players.LocalPlayer
    local character = player and player.Character
    if not character then
        if currentHeldTool then
            currentHeldTool:Destroy()
            currentHeldTool = nil
        end
        return
    end

    -- 查找第一个有道具的装备槽
    local heldItem = nil
    local slotIndex = 0
    for i, item in ipairs(equipSlotsData or {}) do
        if item then
            heldItem = item
            slotIndex = i
            break
        end
    end

    if not heldItem then
        if currentHeldTool then
            currentHeldTool:Destroy()
            currentHeldTool = nil
        end
        return
    end

    -- 用 Icon 字段查找模型（配置里是 'Crowbar', 'Flashlight' 等）
    local toolName = heldItem.Icon
    if not toolName then
        if currentHeldTool then
            currentHeldTool:Destroy()
            currentHeldTool = nil
        end
        return
    end

    -- 如果当前手持的模型已经是我们需要的，就不重新创建
    if currentHeldTool and currentHeldTool.Name == 'HeldTool_' .. toolName then
        return
    end

    if currentHeldTool then
        currentHeldTool:Destroy()
        currentHeldTool = nil
    end

    -- 从 ReplicatedStorage → Assets → ToolTemplates 克隆道具模型
    local assets = ReplicatedStorage:FindFirstChild('Assets')
    if not assets then
        return
    end
    local toolTemplates = assets:FindFirstChild('ToolTemplates')
    if not toolTemplates then
        return
    end

    local toolModel = toolTemplates:FindFirstChild(toolName)
    if not toolModel then
        return
    end

    -- 克隆模型
    local heldInstance = toolModel:Clone()
    heldInstance.Name = 'HeldTool_' .. toolName

    -- 确保所有部件都是可移动的
    for _, part in heldInstance:GetDescendants() do
        if part:IsA('BasePart') then
            part.Anchored = false
            part.CanCollide = false
        end
    end
    -- 同时检查根部件
    local rootPart = heldInstance:FindFirstChildWhichIsA('BasePart')
    if rootPart then
        rootPart.Anchored = false
        rootPart.CanCollide = false
    end

    -- 找到玩家的右手（R15 角色）
    local rightHand = character:FindFirstChild('RightHand')
    if rightHand then
        if rootPart then
            local motor6D = Instance.new('Motor6D')
            motor6D.Name = 'HeldToolMotor'
            motor6D.Part0 = rightHand
            motor6D.Part1 = rootPart
            motor6D.C0 = CFrame.new(0, -0.3, -0.5) * CFrame.Angles(math.rad(-30), 0, 0)
            motor6D.C1 = CFrame.new()
            motor6D.Parent = rightHand

            heldInstance.Parent = rightHand
            currentHeldTool = heldInstance
        else
            heldInstance:Destroy()
        end
    else
        heldInstance:Destroy()
    end
end

local function renderFlashlight(equipSlotsData)
    local player = Players.LocalPlayer
    local character = player and player.Character
    if not character then
        if currentFlashlight then
            currentFlashlight:Destroy()
            currentFlashlight = nil
        end
        return
    end

    -- 查找装备槽中是否有手电筒且状态为 on
    local flashlightItem = nil
    for _, item in ipairs(equipSlotsData or {}) do
        if item and item.Id == 'flashlight' and item.CurrentState == 'on' then
            flashlightItem = item
            break
        end
    end

    if not flashlightItem then
        -- 手电筒不在装备槽或状态为 off，关闭光源
        if currentFlashlight then
            currentFlashlight:Destroy()
            currentFlashlight = nil
        end
        return
    end

    -- 手电筒状态为 on，渲染光源
    if currentFlashlight then
        return  -- 已存在，无需重复创建
    end

    local lightConfig = flashlightItem.Light
    if not lightConfig then return end

    -- 在玩家头部（Head）创建 SpotLight
    local head = character:FindFirstChild('Head')
    if not head then return end

    local spotLight = Instance.new('SpotLight')
    spotLight.Name = 'FlashlightBeam'
    spotLight.Brightness = lightConfig.Brightness or 3
    spotLight.Range = lightConfig.Range or 16
    spotLight.Angle = 35
    spotLight.Face = Enum.NormalId.Front
    if lightConfig.Color then
        spotLight.Color = lightConfig.Color
    else
        spotLight.Color = Color3.fromRGB(255, 240, 200)
    end
    spotLight.Shadows = true
    spotLight.Parent = head

    currentFlashlight = spotLight
    warn('[Flashlight] Turned on')
end

-- 更新装备栏显示函数
-- equipSlotsData: 来自服务器的 EquipSlots 数组
local function updateEquipSlots(equipSlotsData)
    for i, slot in ipairs(equipSlots) do
        -- 清除原有内容
        for _, child in ipairs(slot:GetChildren()) do
            if child.Name == 'ItemIconFrame' then
                child:Destroy()
            end
        end
        
        -- 获取对应槽位的物品数据
        local item = equipSlotsData and equipSlotsData[i]
        
        if item then
            slot.BackgroundTransparency = 0.3
            createItemIcon(slot, item, true)

            local stroke = slot:FindFirstChildOfClass('UIStroke')
            if stroke then
                stroke.Color = Theme.Accent
                stroke.Transparency = 0.3
            end
        else
            slot.BackgroundTransparency = 0.5
            local stroke = slot:FindFirstChildOfClass('UIStroke')
            if stroke then
                stroke.Color = Theme.SubtleText
                stroke.Transparency = 0.7
            end
        end
    end

    -- 更新手电筒照明状态
    renderFlashlight(equipSlotsData)

    -- 更新手持道具渲染
    renderHeldTool(equipSlotsData)
end

-- ============================================
-- 4x4背包系统（B键打开）
-- ============================================
local BACKPACK_COLS = 4
local BACKPACK_ROWS = 4
local BACKPACK_CAPACITY = BACKPACK_COLS * BACKPACK_ROWS
local BACKPACK_SLOT_SIZE = 56
local BACKPACK_SLOT_PADDING = 4
local BACKPACK_PANEL_PADDING = 10

-- 背包面板（自动适应内容大小）
local backpackPanel = Instance.new('Frame')
backpackPanel.Name = 'BackpackPanel'
backpackPanel.AnchorPoint = Vector2.new(0.5, 0.5)
backpackPanel.Position = UDim2.fromScale(0.5, 0.5)
backpackPanel.Size = UDim2.fromOffset(
    BACKPACK_COLS * (BACKPACK_SLOT_SIZE + BACKPACK_SLOT_PADDING) + BACKPACK_PANEL_PADDING * 2,
    BACKPACK_ROWS * (BACKPACK_SLOT_SIZE + BACKPACK_SLOT_PADDING) + BACKPACK_PANEL_PADDING * 2 + 24 + 28  -- +24 for capacity label, +28 for title
)
backpackPanel.BackgroundColor3 = Theme.Background
backpackPanel.BackgroundTransparency = 0.15
backpackPanel.BorderSizePixel = 0
backpackPanel.Visible = false
backpackPanel.Parent = screenGui

local backpackCorner = Instance.new('UICorner')
backpackCorner.CornerRadius = UDim.new(0, 10)
backpackCorner.Parent = backpackPanel

local backpackStroke = Instance.new('UIStroke')
backpackStroke.Color = Theme.Surface
backpackStroke.Transparency = 0.4
backpackStroke.Thickness = 1.5
backpackStroke.Parent = backpackPanel

-- 背包内边距
local backpackPadding = Instance.new('UIPadding')
backpackPadding.PaddingTop = UDim.new(0, BACKPACK_PANEL_PADDING)
backpackPadding.PaddingLeft = UDim.new(0, BACKPACK_PANEL_PADDING)
backpackPadding.PaddingRight = UDim.new(0, BACKPACK_PANEL_PADDING)
backpackPadding.PaddingBottom = UDim.new(0, BACKPACK_PANEL_PADDING)
backpackPadding.Parent = backpackPanel

-- 背包标题
local backpackTitle = Instance.new('TextLabel')
backpackTitle.Name = 'BackpackTitle'
backpackTitle.Size = UDim2.fromOffset(200, 24)
backpackTitle.BackgroundTransparency = 1
backpackTitle.TextColor3 = Theme.Text
backpackTitle.Font = Enum.Font.GothamBold
backpackTitle.TextSize = 14
backpackTitle.Text = 'My Backpack'
backpackTitle.TextXAlignment = Enum.TextXAlignment.Left
backpackTitle.LayoutOrder = 0
backpackTitle.Parent = backpackPanel

-- 背包列表布局
local backpackLayout = Instance.new('UIListLayout')
backpackLayout.Padding = UDim.new(0, 8)
backpackLayout.SortOrder = Enum.SortOrder.LayoutOrder
backpackLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
backpackLayout.Parent = backpackPanel

-- 背包格子容器
local backpackGridContainer = Instance.new('Frame')
backpackGridContainer.Name = 'BackpackGridContainer'
backpackGridContainer.BackgroundTransparency = 1
backpackGridContainer.LayoutOrder = 1
backpackGridContainer.Size = UDim2.fromOffset(
    BACKPACK_COLS * (BACKPACK_SLOT_SIZE + BACKPACK_SLOT_PADDING),
    BACKPACK_ROWS * (BACKPACK_SLOT_SIZE + BACKPACK_SLOT_PADDING)
)
backpackGridContainer.Parent = backpackPanel

-- 背包网格布局
local backpackGrid = Instance.new('UIGridLayout')
backpackGrid.CellSize = UDim2.fromOffset(BACKPACK_SLOT_SIZE, BACKPACK_SLOT_SIZE)
backpackGrid.CellPadding = UDim2.fromOffset(BACKPACK_SLOT_PADDING, BACKPACK_SLOT_PADDING)
backpackGrid.SortOrder = Enum.SortOrder.LayoutOrder
backpackGrid.FillDirection = Enum.FillDirection.Horizontal
backpackGrid.Parent = backpackGridContainer

-- 背包选中状态（必须在格子创建前定义）
local selectedBackpackSlot = nil

-- 更新背包选中高亮（黄色选中）
local function updateBackpackSelection()
    if not backpackSlots then return end
    local SELECTED_COLOR = Color3.fromRGB(255, 220, 0)  -- 黄色选中
    for idx, slot in ipairs(backpackSlots) do
        if not slot then continue end
        local stroke = slot:FindFirstChildOfClass('UIStroke')
        if not stroke then
            stroke = Instance.new('UIStroke')
            stroke.Parent = slot
        end

        if idx == selectedBackpackSlot then
            stroke.Color = SELECTED_COLOR
            stroke.Transparency = 0.3
            stroke.Thickness = 2
        else
            stroke.Color = Theme.SubtleText
            stroke.Transparency = 0.7
            stroke.Thickness = 1
        end
    end
end

-- 背包格子
local backpackSlots = {}
for i = 1, BACKPACK_CAPACITY do
    local slot = Instance.new('TextButton')
    slot.Name = 'BackpackSlot' .. i
    slot.Size = UDim2.fromOffset(BACKPACK_SLOT_SIZE, BACKPACK_SLOT_SIZE)
    slot.BackgroundColor3 = Theme.Surface
    slot.BackgroundTransparency = 0.5
    slot.BorderSizePixel = 0
    slot.Text = ''
    slot.LayoutOrder = i
    slot.Parent = backpackGridContainer

    local corner = Instance.new('UICorner')
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = slot

    local stroke = Instance.new('UIStroke')
    stroke.Color = Theme.SubtleText
    stroke.Transparency = 0.5
    stroke.Thickness = 1
    stroke.Parent = slot

    backpackSlots[i] = slot
    
    -- 背包格子点击 - 选中/移动物品
    slot.MouseButton1Click:Connect(function()
        local hasIcon = slot:FindFirstChild('ItemIconFrame') ~= nil
        
        -- 如果点击的是空格子，且当前有选中的物品，则移动到该位置
        if not hasIcon and selectedBackpackSlot then
            Remotes.RunAction:FireServer({
                Type = 'MoveBackpackItem',
                FromSlot = selectedBackpackSlot,
                ToSlot = i,  -- i 是目标格子索引（超过物品数量时自动移到最后）
            })
            selectedBackpackSlot = nil
            updateBackpackSelection()
            return
        end
        
        -- 如果点击的是有物品的格子，选中它
        if hasIcon then
            -- 如果点击的就是已选中的，取消选中
            if selectedBackpackSlot == i then
                selectedBackpackSlot = nil
            else
                selectedBackpackSlot = i
            end
            updateBackpackSelection()
        end
    end)
end

-- 背包容量标签
local backpackCapacityLabel = Instance.new('TextLabel')
backpackCapacityLabel.Name = 'CapacityLabel'
backpackCapacityLabel.Size = UDim2.fromOffset(80, 18)
backpackCapacityLabel.BackgroundTransparency = 1
backpackCapacityLabel.TextColor3 = Theme.SubtleText
backpackCapacityLabel.Font = Enum.Font.Gotham
backpackCapacityLabel.TextSize = 11
backpackCapacityLabel.Text = '0/20'
backpackCapacityLabel.LayoutOrder = 999  -- 最后显示
backpackCapacityLabel.Parent = backpackPanel


-- 背包打开状态
local isBackpackOpen = false

-- 切换背包
local function toggleBackpack()
    isBackpackOpen = not isBackpackOpen
    backpackPanel.Visible = isBackpackOpen
    
    if isBackpackOpen then
        activeModal = 'Backpack'
        -- 打开背包时隐藏其他面板，显示modal背景
        if modalBackdrop then modalBackdrop.Visible = true end
        if shopPanel then shopPanel.Visible = false end
        if sellPanel then sellPanel.Visible = false end
        if objectivePanel then objectivePanel.Visible = false end
    else
        activeModal = nil
        -- 关闭背包时隐藏modal背景
        if modalBackdrop then modalBackdrop.Visible = false end
        -- 关闭背包时清空选中状态
        selectedBackpackSlot = nil
        updateBackpackSelection()
    end
end

-- ESC键关闭背包 / 禁用~键（Backquote）
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    -- 禁用~键：无论gameProcessed如何都拦截
    if input.KeyCode == Enum.KeyCode.Backquote then
        return  -- 直接返回，阻止任何默认行为
    end
    
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.Escape and isBackpackOpen then
        isBackpackOpen = false
        backpackPanel.Visible = false
        setActiveModal(nil)
    end
end)

-- ============================================
-- 更新背包显示
-- ============================================
local function updateBackpackSlots(backpackItems, weight, capacity)
    if not backpackSlots then return end
    
    -- 更新容量显示
    backpackCapacityLabel.Text = string.format('%d/%d', weight, capacity)
    
    for i, slot in ipairs(backpackSlots) do
        if not slot then continue end
        -- 清除原有内容（保留UIStroke）
        for _, child in ipairs(slot:GetChildren()) do
            if child.Name == 'ItemIconFrame' then
                child:Destroy()
            end
        end
        
        local item = backpackItems and backpackItems[i]
        if item then
            slot.BackgroundTransparency = 0.2
            createItemIcon(slot, item)
        else
            slot.BackgroundTransparency = 0.5
        end
    end
    
    -- 重新应用选中状态高亮
    updateBackpackSelection()
end

-- ============================================
-- 服务器消息处理 - 更新物品栏
-- ============================================
Remotes.RunAction.OnClientEvent:Connect(function(payload)
        if payload.Type == 'InventoryUpdate' or payload.Type == 'ShopResult' then
            if payload.Inventory then
                inventorySummary = payload.Inventory

                -- 更新装备栏
                updateEquipSlots(payload.Inventory.EquipSlots or {})

                -- 更新背包
                updateBackpackSlots(
                    payload.Inventory.BackpackItems or {},
                    payload.Inventory.Weight or 0,
                    payload.Inventory.Capacity or 20
                )

                -- 更新左侧面板的库存信息
                if inventoryLabel then
                    inventoryLabel.Text = string.format(
                        'Inventory: %d total | %d backpack | %d held | %d/%d KG | %d value',
                        payload.Inventory.Count or 0,
                        payload.Inventory.BackpackCount or 0,
                        payload.Inventory.HeldCount or 0,
                        payload.Inventory.Weight or 0,
                        payload.Inventory.Capacity or 0,
                        payload.Inventory.Value or 0
                    )
                end
            end
        end

        -- 商店购买结果提示（使用showToast函数，避免toastLabel未定义问题）
        if payload.Type == 'ShopResult' then
            if payload.Success then
                showToast('Purchase successful!', 'Success')
            else
                local reason = payload.Reason or 'Purchase failed'
                if reason == 'InsufficientFunds' then
                    showToast('Insufficient Pages!', 'Error')
                elseif reason == 'OverCapacity' or reason == 'InventoryFull' then
                    showToast('Backpack is full!', 'Error')
                else
                    showToast(reason, 'Error')
                end
            end
        end
end)

-- 按B键打开背包
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.B then
        toggleBackpack()
    end
end)

local toastLabel = Instance.new('TextLabel')
toastLabel.Name = 'Toast'
toastLabel.AnchorPoint = Vector2.new(0.5, 0.5)
toastLabel.Position = UDim2.fromScale(0.5, 0.88)
toastLabel.Size = UDim2.fromOffset(420, 52)
toastLabel.BackgroundColor3 = Theme.Background  -- 用更深背景色
toastLabel.BackgroundTransparency = 0.2  -- 20%透明度，更实的黑色
toastLabel.TextColor3 = Theme.Text
toastLabel.TextSize = 22
toastLabel.Font = Enum.Font.GothamBold
toastLabel.Text = ''
toastLabel.Visible = false
toastLabel.ZIndex = 100 -- 确保在modalBackdrop之上
toastLabel.Parent = screenGui

-- toast 不需要 stroke，保持简洁
local toastCorner = Instance.new('UICorner')
toastCorner.CornerRadius = UDim.new(0, 16)
toastCorner.Parent = toastLabel

-- 添加微弱阴影
local toastShadow = Instance.new('ImageLabel')
toastShadow.Name = 'Shadow'
toastShadow.Size = UDim2.new(1, 0, 1, 6)
toastShadow.Position = UDim2.fromOffset(0, 4)
toastShadow.BackgroundTransparency = 1
toastShadow.Image = 'rbxassetid://5554236805'
toastShadow.ImageColor3 = Color3.new(0, 0, 0)
toastShadow.ImageTransparency = 0.5
toastShadow.ZIndex = 99
toastShadow.Parent = toastLabel

local goalBanner = Instance.new('TextLabel')
goalBanner.Name = 'GoalBanner'
goalBanner.AnchorPoint = Vector2.new(0.5, 0.5)
goalBanner.Position = UDim2.fromScale(0.5, 0.16)
goalBanner.Size = UDim2.fromOffset(460, 56)
goalBanner.BackgroundColor3 = Theme.Accent
goalBanner.TextColor3 = Theme.Background
goalBanner.TextSize = 22
goalBanner.Font = Enum.Font.GothamBold
goalBanner.Text = ''
goalBanner.Visible = false
goalBanner.Parent = screenGui
applyPanelStyle(goalBanner, 12, 0.7)

-- 商店面板：左右分栏布局
local shopPanel = Instance.new('Frame')
shopPanel.Name = 'ShopPanel'
shopPanel.AnchorPoint = Vector2.new(0.5, 0.5)
shopPanel.Position = UDim2.fromScale(0.5, 0.5)
shopPanel.Size = UDim2.fromOffset(840, 560)
shopPanel.BackgroundColor3 = Theme.Surface
shopPanel.BorderSizePixel = 0
shopPanel.Visible = false
shopPanel.Parent = screenGui

-- 面板阴影效果
local shopShadow = Instance.new('ImageLabel')
shopShadow.Name = 'Shadow'
shopShadow.Size = UDim2.fromScale(1, 1)
shopShadow.Position = UDim2.fromOffset(0, 4)
shopShadow.BackgroundTransparency = 1
shopShadow.Image = 'rbxassetid://5554236805'
shopShadow.ImageColor3 = Color3.new(0, 0, 0)
shopShadow.ImageTransparency = 0.5
shopShadow.ScaleType = Enum.ScaleType.Slice
shopShadow.SliceCenter = Rect.new(23, 23, 277, 277)
shopShadow.Parent = shopPanel

-- 面板圆角和边框
local shopCorner = Instance.new('UICorner')
shopCorner.CornerRadius = UDim.new(0, 16)
shopCorner.Parent = shopPanel

local shopStroke = Instance.new('UIStroke')
shopStroke.Color = Theme.Text
shopStroke.Transparency = 0.8
shopStroke.Thickness = 1
shopStroke.Parent = shopPanel

-- 顶部标题栏
local shopHeader = Instance.new('Frame')
shopHeader.Name = 'ShopHeader'
shopHeader.Size = UDim2.new(1, 0, 0, 50)
shopHeader.BackgroundColor3 = Theme.Background
shopHeader.BackgroundTransparency = 0.3
shopHeader.BorderSizePixel = 0
shopHeader.Parent = shopPanel

local headerCorner = Instance.new('UICorner')
headerCorner.CornerRadius = UDim.new(0, 16)
headerCorner.Parent = shopHeader

-- 使用clipDescendants确保圆角只在顶部生效
local shopClip = Instance.new('Frame')
shopClip.Name = 'HeaderClip'
shopClip.Size = UDim2.new(1, 0, 1, 8)
shopClip.Position = UDim2.new(0, 0, 0, 0)
shopClip.BackgroundTransparency = 1
shopClip.ClipsDescendants = true
shopClip.Parent = shopHeader

-- 商店标题（居中）
local shopTitle = Instance.new('TextLabel')
shopTitle.Size = UDim2.new(1, -80, 1, 0)
shopTitle.Position = UDim2.fromOffset(0, 0)
shopTitle.BackgroundTransparency = 1
shopTitle.TextColor3 = Theme.Text
shopTitle.Font = Enum.Font.GothamBold
shopTitle.TextSize = 26
shopTitle.Text = 'Temple Shop'
shopTitle.Parent = shopClip

-- 关闭按钮（右上角）
local shopCloseButton = Instance.new('TextButton')
shopCloseButton.Name = 'CloseButton'
shopCloseButton.AnchorPoint = Vector2.new(1, 0.5)
shopCloseButton.Position = UDim2.new(1, -16, 0.5, 0)
shopCloseButton.Size = UDim2.fromOffset(36, 36)
shopCloseButton.BackgroundColor3 = Theme.Warning
shopCloseButton.TextColor3 = Theme.Background
shopCloseButton.Font = Enum.Font.GothamBold
shopCloseButton.TextSize = 20
shopCloseButton.Text = '×'
shopCloseButton.Parent = shopClip

local closeCorner = Instance.new('UICorner')
closeCorner.CornerRadius = UDim.new(1, 0)
closeCorner.Parent = shopCloseButton

-- 关闭按钮阴影
local closeShadow = Instance.new('ImageLabel')
closeShadow.Size = UDim2.fromScale(1, 1)
closeShadow.Position = UDim2.fromOffset(0, 2)
closeShadow.BackgroundTransparency = 1
closeShadow.Image = 'rbxassetid://5554236805'
closeShadow.ImageColor3 = Color3.new(0, 0, 0)
closeShadow.ImageTransparency = 0.6
closeShadow.ScaleType = Enum.ScaleType.Slice
closeShadow.SliceCenter = Rect.new(23, 23, 277, 277)
closeShadow.Parent = shopCloseButton

-- 关闭按钮交互效果
shopCloseButton.MouseEnter:Connect(function()
    local tween = TweenService:Create(shopCloseButton, TweenInfo.new(0.15), {
        Size = UDim2.fromOffset(40, 40),
        BackgroundColor3 = Color3.fromRGB(255, 100, 100)
    })
    tween:Play()
end)

shopCloseButton.MouseLeave:Connect(function()
    local tween = TweenService:Create(shopCloseButton, TweenInfo.new(0.15), {
        Size = UDim2.fromOffset(36, 36),
        BackgroundColor3 = Theme.Warning
    })
    tween:Play()
end)

-- 左侧商品展示区（2x2网格）
local shopLeftFrame = Instance.new('Frame')
shopLeftFrame.Name = 'ShopLeft'
shopLeftFrame.Size = UDim2.new(0, 340, 1, -64)
shopLeftFrame.Position = UDim2.new(0, 12, 0, 56)
shopLeftFrame.BackgroundColor3 = Theme.Background
shopLeftFrame.BackgroundTransparency = 0.4
shopLeftFrame.BorderSizePixel = 0
shopLeftFrame.Parent = shopPanel

local leftCorner = Instance.new('UICorner')
leftCorner.CornerRadius = UDim.new(0, 12)
leftCorner.Parent = shopLeftFrame

-- 左侧标题
local leftTitle = Instance.new('TextLabel')
leftTitle.Size = UDim2.new(1, -16, 0, 28)
leftTitle.BackgroundTransparency = 1
leftTitle.TextColor3 = Theme.Text
leftTitle.Font = Enum.Font.GothamBold
leftTitle.TextSize = 16
leftTitle.Text = 'Items'
leftTitle.TextXAlignment = Enum.TextXAlignment.Left
leftTitle.LayoutOrder = 0  -- 标题在最前
leftTitle.Parent = shopLeftFrame

-- 左侧面板布局（必须在标题和内容之前创建）
local leftLayout = Instance.new('UIListLayout')
leftLayout.Padding = UDim.new(0, 8)
leftLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
leftLayout.Parent = shopLeftFrame

-- 商品网格容器
local shopItemsFrame = Instance.new('Frame')
shopItemsFrame.Name = 'ItemsGrid'
shopItemsFrame.Size = UDim2.new(1, -24, 0, 350)
shopItemsFrame.BackgroundTransparency = 1
shopItemsFrame.LayoutOrder = 1  -- 商品网格在前
shopItemsFrame.Parent = shopLeftFrame

-- 商品网格布局（2列2行）
local shopItemsGrid = Instance.new('UIGridLayout')
shopItemsGrid.CellSize = UDim2.fromOffset(145, 160)
shopItemsGrid.CellPadding = UDim2.fromOffset(10, 10)
shopItemsGrid.SortOrder = Enum.SortOrder.LayoutOrder
shopItemsGrid.Parent = shopItemsFrame

-- 书页余额显示（商品网格下方，底部对齐）
local shopBalanceFrame = Instance.new('Frame')
shopBalanceFrame.Name = 'BalanceFrame'
shopBalanceFrame.Size = UDim2.new(1, -24, 0, 60)
shopBalanceFrame.BackgroundColor3 = Theme.Surface
shopBalanceFrame.BackgroundTransparency = 0.5
shopBalanceFrame.BorderSizePixel = 0
shopBalanceFrame.LayoutOrder = 999  -- 最后排列
shopBalanceFrame.Parent = shopLeftFrame

local balanceCorner = Instance.new('UICorner')
balanceCorner.CornerRadius = UDim.new(0, 10)
balanceCorner.Parent = shopBalanceFrame

local shopBalanceLabel = Instance.new('TextLabel')
shopBalanceLabel.Name = 'BalanceLabel'
shopBalanceLabel.Size = UDim2.new(1, 0, 1, 0)
shopBalanceLabel.BackgroundTransparency = 1
shopBalanceLabel.TextColor3 = Color3.fromRGB(255, 200, 50)  -- 黄色
shopBalanceLabel.Font = Enum.Font.GothamBold
shopBalanceLabel.TextSize = 22
shopBalanceLabel.Text = '0 Pages'
shopBalanceLabel.TextXAlignment = Enum.TextXAlignment.Center  -- 水平居中
shopBalanceLabel.TextYAlignment = Enum.TextYAlignment.Center   -- 垂直居中
shopBalanceLabel.Parent = shopBalanceFrame

-- 右侧商品详情区
local shopRightFrame = Instance.new('Frame')
shopRightFrame.Name = 'ShopRight'
shopRightFrame.Size = UDim2.new(1, -380, 1, -64)
shopRightFrame.Position = UDim2.new(1, -12, 0, 56)
shopRightFrame.AnchorPoint = Vector2.new(1, 0)
shopRightFrame.BackgroundColor3 = Theme.Background
shopRightFrame.BackgroundTransparency = 0.4
shopRightFrame.BorderSizePixel = 0
shopRightFrame.Parent = shopPanel

local rightCorner = Instance.new('UICorner')
rightCorner.CornerRadius = UDim.new(0, 12)
rightCorner.Parent = shopRightFrame

-- 右侧内容容器（垂直布局）
local detailContent = Instance.new('Frame')
detailContent.Name = 'DetailContent'
detailContent.Size = UDim2.new(1, -24, 1, -24)
detailContent.Position = UDim2.fromOffset(12, 12)
detailContent.BackgroundTransparency = 1
detailContent.Parent = shopRightFrame

local detailLayout = Instance.new('UIListLayout')
detailLayout.Padding = UDim.new(0, 8)
detailLayout.VerticalAlignment = Enum.VerticalAlignment.Top  -- 顶部开始布局
detailLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
detailLayout.SortOrder = Enum.SortOrder.LayoutOrder
detailLayout.Parent = detailContent

-- 选中商品状态
local selectedShopItem = nil

-- 设置当前模态面板
local function setActiveModal(nextModal)
    activeModal = nextModal
    local showModal = nextModal ~= nil

    modalBackdrop.Visible = showModal
    
    -- 直接从ScreenGui查找panel，避免IIFE闭包问题
    local sellPanelRef = screenGui:FindFirstChild('SellPanel')
    local objectivePanelRef = screenGui:FindFirstChild('ObjectivePanel')
    local shopPanelRef = screenGui:FindFirstChild('ShopPanel')
    local objectiveCloseBtnRef = screenGui:FindFirstChild('ObjectiveCloseButton')
    
    if shopPanelRef then shopPanelRef.Visible = nextModal == 'Shop' end
    if sellPanelRef then sellPanelRef.Visible = nextModal == 'Sell' end
    if objectivePanelRef then objectivePanelRef.Visible = nextModal == 'Objective' end
    -- 同步任务看板关闭按钮可见性
    if objectiveCloseBtnRef then objectiveCloseBtnRef.Visible = nextModal == 'Objective' end

    -- 打开/关闭UI面板时，同步鼠标状态
    syncMouseMode()
end

-- 商品详情展示（使用右侧容器）
-- 布局顺序：描述 → 名称 → 图标 → 参数区 → 按钮

-- 描述区（最上方）
local shopDetailDesc = Instance.new('TextLabel')
shopDetailDesc.Name = 'DetailDesc'
shopDetailDesc.Size = UDim2.new(1, 0, 0, 100)
shopDetailDesc.BackgroundTransparency = 1
shopDetailDesc.TextColor3 = Theme.Text
shopDetailDesc.Font = Theme.Font
shopDetailDesc.TextSize = 16
shopDetailDesc.TextWrapped = true
shopDetailDesc.TextXAlignment = Enum.TextXAlignment.Left
shopDetailDesc.TextYAlignment = Enum.TextYAlignment.Top
shopDetailDesc.Text = 'Click an item to view details'
shopDetailDesc.LayoutOrder = 1
shopDetailDesc.Parent = detailContent

-- 道具名称
local shopDetailName = Instance.new('TextLabel')
shopDetailName.Name = 'DetailName'
shopDetailName.Size = UDim2.new(1, 0, 0, 36)
shopDetailName.BackgroundTransparency = 1
shopDetailName.TextColor3 = Theme.Text
shopDetailName.Font = Enum.Font.GothamBold
shopDetailName.TextSize = 26
shopDetailName.Text = 'Select an item'
shopDetailName.TextXAlignment = Enum.TextXAlignment.Left
shopDetailName.LayoutOrder = 2
shopDetailName.Parent = detailContent

-- 详情图标
local shopDetailIcon = Instance.new('Frame')
shopDetailIcon.Name = 'DetailIcon'
shopDetailIcon.Size = UDim2.fromOffset(70, 70)
shopDetailIcon.BackgroundColor3 = Theme.Surface
shopDetailIcon.BackgroundTransparency = 0.5
shopDetailIcon.BorderSizePixel = 0
shopDetailIcon.LayoutOrder = 3
shopDetailIcon.Parent = detailContent

local iconCorner = Instance.new('UICorner')
iconCorner.CornerRadius = UDim.new(0, 10)
iconCorner.Parent = shopDetailIcon

local iconStroke = Instance.new('UIStroke')
iconStroke.Color = Theme.SubtleText
iconStroke.Transparency = 0.5
iconStroke.Thickness = 1
iconStroke.Parent = shopDetailIcon

-- 图标内的文字
local shopDetailIconLabel = Instance.new('TextLabel')
shopDetailIconLabel.Size = UDim2.new(1, 0, 1, 0)
shopDetailIconLabel.BackgroundTransparency = 1
shopDetailIconLabel.TextColor3 = Theme.Accent
shopDetailIconLabel.Font = Enum.Font.GothamBold
shopDetailIconLabel.TextSize = 36
shopDetailIconLabel.Text = '?'
shopDetailIconLabel.Parent = shopDetailIcon

-- 参数区背景
local paramsFrame = Instance.new('Frame')
paramsFrame.Name = 'ParamsFrame'
paramsFrame.Size = UDim2.new(1, 0, 0, 100)
paramsFrame.BackgroundColor3 = Theme.Surface
paramsFrame.BackgroundTransparency = 0.6
paramsFrame.BorderSizePixel = 0
paramsFrame.LayoutOrder = 4
paramsFrame.Parent = detailContent

local paramsCorner = Instance.new('UICorner')
paramsCorner.CornerRadius = UDim.new(0, 8)
paramsCorner.Parent = paramsFrame

-- 参数区内边距
local paramsPadding = Instance.new('UIPadding')
paramsPadding.PaddingTop = UDim.new(0, 8)
paramsPadding.PaddingLeft = UDim.new(0, 10)
paramsPadding.PaddingRight = UDim.new(0, 10)
paramsPadding.Parent = paramsFrame

-- 参数区布局
local paramsLayout = Instance.new('UIListLayout')
paramsLayout.Padding = UDim.new(0, 5)
paramsLayout.Parent = paramsFrame

local function makeDetailParam(text, color)
    local param = Instance.new('TextLabel')
    param.Size = UDim2.new(1, 0, 0, 20)
    param.BackgroundTransparency = 1
    param.TextColor3 = color or Theme.Text
    param.Font = Theme.Font
    param.TextSize = 15
    param.Text = text
    param.TextXAlignment = Enum.TextXAlignment.Left
    param.Parent = paramsFrame
    return param
end

-- 商品参数
local shopDetailPrice = makeDetailParam('')
local shopDetailStock = makeDetailParam('')
local shopDetailType = makeDetailParam('')
local shopDetailDurability = makeDetailParam('')

-- 库存标签
local shopInventoryLabel = Instance.new('TextLabel')
shopInventoryLabel.Name = 'InventoryLabel'
shopInventoryLabel.Size = UDim2.new(1, 0, 0, 20)
shopInventoryLabel.BackgroundTransparency = 1
shopInventoryLabel.TextColor3 = Color3.fromRGB(255, 200, 50)  -- 黄色
shopInventoryLabel.Font = Theme.Font
shopInventoryLabel.TextSize = 14
shopInventoryLabel.Text = 'Inventory: --'
shopInventoryLabel.TextXAlignment = Enum.TextXAlignment.Left
shopInventoryLabel.LayoutOrder = 5
shopInventoryLabel.RichText = true  -- 启用富文本，用于KG部分使用黄色
shopInventoryLabel.Parent = detailContent

-- 购买按钮（详情页最底部，直接Parent到detailContent）
local shopBuyButton = Instance.new('TextButton')
shopBuyButton.Name = 'BuyButton'
shopBuyButton.Size = UDim2.new(1, 0, 0, 52)
shopBuyButton.BackgroundColor3 = Color3.fromRGB(255, 200, 50)  -- 黄色
shopBuyButton.TextColor3 = Color3.fromRGB(40, 30, 20)  -- 深棕色文字
shopBuyButton.Font = Enum.Font.GothamBold
shopBuyButton.TextSize = 20
shopBuyButton.Text = 'Purchase'
shopBuyButton.AutoButtonColor = true
shopBuyButton.Visible = false
shopBuyButton.LayoutOrder = 100  -- 确保在最后
shopBuyButton.Parent = detailContent

local buyCorner = Instance.new('UICorner')
buyCorner.CornerRadius = UDim.new(0, 10)
buyCorner.Parent = shopBuyButton

-- 购买按钮阴影
local buyShadow = Instance.new('ImageLabel')
buyShadow.Size = UDim2.fromScale(1, 1)
buyShadow.Position = UDim2.fromOffset(0, 3)
buyShadow.BackgroundTransparency = 1
buyShadow.Image = 'rbxassetid://5554236805'
buyShadow.ImageColor3 = Color3.new(0, 0, 0)
buyShadow.ImageTransparency = 0.5
buyShadow.ScaleType = Enum.ScaleType.Slice
buyShadow.SliceCenter = Rect.new(23, 23, 277, 277)
buyShadow.Parent = shopBuyButton

-- 购买按钮交互效果
shopBuyButton.MouseEnter:Connect(function()
    local yellowColor = Color3.fromRGB(255, 200, 50)
    if shopBuyButton.BackgroundColor3 == yellowColor then
        local tween = TweenService:Create(shopBuyButton, TweenInfo.new(0.15), {
            Size = UDim2.new(1, 0, 0, 52)
        })
        tween:Play()
    end
end)

shopBuyButton.MouseLeave:Connect(function()
    local tween = TweenService:Create(shopBuyButton, TweenInfo.new(0.15), {
        Size = UDim2.new(1, 0, 0, 48)
    })
    tween:Play()
end)

-- 关闭按钮点击
shopCloseButton.MouseButton1Click:Connect(function()
    setActiveModal(nil)
end)

-- 更新商品详情显示
local function updateShopDetail(item)
    selectedShopItem = item
    local yellowColor = Color3.fromRGB(255, 200, 50)
    local darkBrown = Color3.fromRGB(40, 30, 20)
    if item then
        shopDetailName.Text = item.Name or 'Unknown Item'
        shopDetailIconLabel.Text = item.IconLabel or '?'
        shopDetailPrice.Text = string.format('Price: %d Pages', item.Price or 0)
        shopDetailPrice.TextColor3 = Color3.fromRGB(255, 255, 255)  -- 白色

        local stock = item.Stock or 0
        if stock <= 0 then
            shopDetailStock.Text = 'Stock: Out of stock'
            shopDetailStock.TextColor3 = Color3.fromRGB(255, 80, 80)
            shopBuyButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
            shopBuyButton.Text = 'Unavailable'
        else
            shopDetailStock.Text = string.format('Stock: %d', stock)
            shopDetailStock.TextColor3 = Color3.fromRGB(255, 255, 255)  -- 白色
            shopBuyButton.BackgroundColor3 = yellowColor
            shopBuyButton.TextColor3 = darkBrown
            shopBuyButton.Text = 'Purchase'
        end

        -- 道具类型
        local itemType = item.Type or 'misc'
        local typeText = 'Type: '
        if itemType == 'tool' then
            typeText = typeText .. 'Tool'
            shopDetailType.Text = typeText
            shopDetailType.TextColor3 = Color3.fromRGB(255, 255, 255)  -- 白色
            if item.Consumable then
                shopDetailDurability.Text = 'Special: Requires battery'
                shopDetailDurability.TextColor3 = Theme.Warning
            else
                shopDetailDurability.Text = 'Special: Non-consumable, has durability'
                shopDetailDurability.TextColor3 = Color3.fromRGB(255, 200, 50)  -- 黄色
            end
        elseif itemType == 'consumable' then
            typeText = typeText .. 'Consumable'
            shopDetailType.Text = typeText
            shopDetailType.TextColor3 = Color3.fromRGB(255, 255, 255)  -- 白色
            local healAmount = item.HealAmount or 50
            shopDetailDurability.Text = string.format('Special: Restores %d health', healAmount)
            shopDetailDurability.TextColor3 = Color3.fromRGB(80, 255, 120)
        else
            typeText = typeText .. 'Misc'
            shopDetailType.Text = typeText
            shopDetailType.TextColor3 = Color3.fromRGB(255, 255, 255)  -- 白色
            shopDetailDurability.Text = ''
        end

        -- 描述
        shopDetailDesc.Text = item.Description or 'No description'
        shopBuyButton.Visible = true
    else
        shopDetailName.Text = 'Select an item'
        shopDetailIconLabel.Text = '?'
        shopDetailPrice.Text = ''
        shopDetailStock.Text = ''
        shopDetailType.Text = ''
        shopDetailDurability.Text = ''
        shopDetailDesc.Text = 'Click an item to view details'
        shopBuyButton.Visible = false
    end
end

-- 购买按钮点击
shopBuyButton.MouseButton1Click:Connect(function()
    if selectedShopItem and selectedShopItem.Stock and selectedShopItem.Stock > 0 then
        Remotes.RunAction:FireServer({
            Type = 'RequestPurchaseItem',
            ItemId = selectedShopItem.Id,
        })
    end
end)

local sellPanel = createModalPanel('SellPanel', UDim2.fromOffset(460, 480))
local sellTitle = makeTextLabel(sellPanel, UDim2.new(1, 0, 0, 32), Theme.Text, 26, true)
sellTitle.Text = 'Salvage Exchange'

local sellPageLabel = makeTextLabel(sellPanel, UDim2.new(1, 0, 0, 24), Theme.SubtleText, 16, false)
sellPageLabel.Text = 'Team Pages: 0'

local sellItemsFrame = Instance.new('Frame')
sellItemsFrame.Size = UDim2.new(1, 0, 1, -160)
sellItemsFrame.BackgroundTransparency = 1
sellItemsFrame.Parent = sellPanel

local sellItemsList = Instance.new('UIListLayout')
sellItemsList.Padding = UDim.new(0, 8)
sellItemsList.Parent = sellItemsFrame

local sellCloseButton = makeButton(sellPanel, 'Close', 44, Theme.Warning)

local objectivePanel = createModalPanel('ObjectivePanel', UDim2.fromOffset(440, 400))
local objectiveTitle = makeTextLabel(objectivePanel, UDim2.new(1, 0, 0, 32), Theme.Text, 26, true)
objectiveTitle.Text = 'Book of Sand Board'
objectiveTitle.TextXAlignment = Enum.TextXAlignment.Center  -- 标题居中

-- 圆形进度指示器（LayoutOrder=1，在标题下面）- 透明背景
local circleProgressFrame = Instance.new('Frame')
circleProgressFrame.Name = 'CircleProgress'
circleProgressFrame.Size = UDim2.new(1, -20, 0, 110)
circleProgressFrame.BackgroundTransparency = 1
circleProgressFrame.LayoutOrder = 1
circleProgressFrame.Parent = objectivePanel

-- 圆形 - 透明背景
local circleFrame = Instance.new('Frame')
circleFrame.Name = 'Circle'
circleFrame.Size = UDim2.fromOffset(100, 100)
circleFrame.Position = UDim2.new(0.5, 0, 0, 5)
circleFrame.AnchorPoint = Vector2.new(0.5, 0)
circleFrame.BackgroundTransparency = 1  -- 透明背景
circleFrame.Parent = circleProgressFrame

local circleCorner = Instance.new('UICorner')
circleCorner.CornerRadius = UDim.new(1, 0)  -- 圆形
circleCorner.Parent = circleFrame

local circleStroke = Instance.new('UIStroke')
circleStroke.Name = 'CircleStroke'
circleStroke.Color = Color3.fromRGB(255, 200, 50)  -- 黄色边框
circleStroke.Thickness = 4
circleStroke.Parent = circleFrame

-- 圆形内百分比文字
local circlePercentLabel = Instance.new('TextLabel')
circlePercentLabel.Name = 'PercentLabel'
circlePercentLabel.Size = UDim2.new(1, 0, 1, 0)
circlePercentLabel.BackgroundTransparency = 1
circlePercentLabel.TextColor3 = Color3.fromRGB(255, 255, 255)  -- 白色，与黄色对比
circlePercentLabel.Font = Enum.Font.GothamBold
circlePercentLabel.TextSize = 28
circlePercentLabel.Text = '0%'
circlePercentLabel.Parent = circleFrame

-- Goal文案（圆形下面）- 居中显示 当前/总目标 Pages，加粗放大
local objectiveGoalLabel =
    makeTextLabel(objectivePanel, UDim2.new(1, 0, 0, 30), Color3.fromRGB(255, 200, 50), 22, true)  -- 高度30，字号22，加粗
objectiveGoalLabel.Text = '0 / 120 Pages'
objectiveGoalLabel.TextXAlignment = Enum.TextXAlignment.Center
objectiveGoalLabel.LayoutOrder = 2

-- 任务内容区域（留空）
local objectiveContent = Instance.new('Frame')
objectiveContent.Name = 'ObjectiveContent'
objectiveContent.Size = UDim2.new(1, -20, 0, 0)
objectiveContent.BackgroundTransparency = 1
objectiveContent.LayoutOrder = 3
objectiveContent.Parent = objectivePanel

local objectiveLayout = Instance.new('UIListLayout')
objectiveLayout.Padding = UDim.new(0, 8)
objectiveLayout.SortOrder = Enum.SortOrder.LayoutOrder
objectiveLayout.Parent = objectiveContent

-- 黄色关闭按钮（放到screenGui层，绝对定位在面板底部）
local objectiveCloseButton = makeButton(screenGui, 'Close', 44, Color3.fromRGB(255, 200, 50))
objectiveCloseButton.Name = 'ObjectiveCloseButton'
objectiveCloseButton.Size = UDim2.new(0, 120, 0, 36)
objectiveCloseButton.AnchorPoint = Vector2.new(0.5, 1)  -- 底部中点对齐
objectiveCloseButton.Position = UDim2.new(0.5, 0, 0.5, 195)  -- 在面板底部中间
objectiveCloseButton.ZIndex = 15  -- 在objectivePanel之上
objectiveCloseButton.Visible = false  -- 默认隐藏，只有打开任务看板时才显示

local function syncCampPanelVisibility()
    if isCampPanelCollapsed then
        panel.Visible = false
        collapseButton.Visible = false
        expandButton.Visible = isRunLaunched
    else
        panel.Visible = isRunLaunched and isCampPanelVisible
        collapseButton.Visible = isRunLaunched and isCampPanelVisible
        expandButton.Visible = false
    end
end

-- 折叠按钮点击事件
collapseButton.MouseButton1Click:Connect(function()
    isCampPanelCollapsed = true
    syncCampPanelVisibility()
end)

-- 展开按钮点击事件
expandButton.MouseButton1Click:Connect(function()
    isCampPanelCollapsed = false
    collapseButton.Text = '−'
    syncCampPanelVisibility()
end)

local function updateObjectiveUi()
    local clampedProgress = math.clamp(goalProgress, 0, 1)
    local percentValue = math.floor(clampedProgress * 100 + 0.5)
    -- 显示 当前/总目标 Pages 格式
    objectiveGoalLabel.Text = string.format('%d / %d Pages', teamPages, goalAmount)
    circlePercentLabel.Text = percentValue .. '%'
end

local function updatePageLabels()
    sellPageLabel.Text = string.format('Team %s: %d', PAGE_LABEL, teamPages)
    updateObjectiveUi()

    -- 更新左侧余额显示
    if shopBalanceLabel then
        shopBalanceLabel.Text = string.format('%d Pages', teamPages)
    end

    if inventorySummary then
        shopInventoryLabel.Text = string.format(
            'Inventory: %d total | <font color="rgb(255,200,50)">%d/%d KG</font> | %d value',
            inventorySummary.Count or 0,
            inventorySummary.Weight or 0,
            inventorySummary.Capacity or 0,
            inventorySummary.Value or 0
        )
    else
        shopInventoryLabel.Text = 'Inventory: --'
    end
end

local function showToast(message, tone)
    local color = Theme.Text
    if tone == 'Error' then
        color = Theme.Warning
    elseif tone == 'Success' then
        color = Color3.fromRGB(255, 200, 50)  -- 黄色
    end

    toastLabel.TextColor3 = color
    toastLabel.Text = message
    toastLabel.Visible = true

    local token = os.clock()
    toastLabel:SetAttribute('ToastToken', token)

    task.delay(2.5, function()
        if toastLabel:GetAttribute('ToastToken') == token then
            toastLabel.Visible = false
        end
    end)
end

local function showGoalBanner()
    goalBanner.Text = string.format('Goal reached! Team %s: %d', PAGE_LABEL, teamPages)
    goalBanner.Visible = true

    task.delay(3, function()
        goalBanner.Visible = false
    end)
end

local function showOceanSlowdown()
    isInOcean = true
    if oceanSlowdownTween then
        oceanSlowdownTween:Cancel()
        oceanSlowdownTween = nil
    end

    oceanSlowdownTween = TweenService:Create(
        oceanSlowdownOverlay,
        TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { BackgroundTransparency = 0.7 }
    )
    oceanSlowdownTween:Play()
end

local function hideOceanSlowdown()
    if not isInOcean then
        return
    end
    isInOcean = false

    if oceanSlowdownTween then
        oceanSlowdownTween:Cancel()
        oceanSlowdownTween = nil
    end

    oceanSlowdownTween = TweenService:Create(
        oceanSlowdownOverlay,
        TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        { BackgroundTransparency = 1 }
    )
    oceanSlowdownTween:Play()
end

local function showOceanSplash(message)
    showToast(message or 'Splash!', 'Success')

    oceanSplashOverlay.BackgroundTransparency = 1

    local flashIn = TweenService:Create(
        oceanSplashOverlay,
        TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {
            BackgroundTransparency = 0.82,
        }
    )
    local flashOut = TweenService:Create(
        oceanSplashOverlay,
        TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        {
            BackgroundTransparency = 1,
        }
    )

    flashIn:Play()
    flashIn.Completed:Connect(function()
        flashOut:Play()
    end)

    -- Also show sustained slowdown overlay
    showOceanSlowdown()
end

    -- 返回所有需要在IIFE外部访问的变量
    return {
        backpackSlots = backpackSlots, backpackCapacityLabel = backpackCapacityLabel,
        toastLabel = toastLabel, goalBanner = goalBanner, shopPanel = shopPanel, sellPanel = sellPanel, objectivePanel = objectivePanel,
        modalBackdrop = modalBackdrop, oceanSplashOverlay = oceanSplashOverlay, oceanSlowdownOverlay = oceanSlowdownOverlay,
        shopItemsFrame = shopItemsFrame, sellItemsFrame = sellItemsFrame, objectiveContent = objectiveContent,
        selectedShopItem = selectedShopItem, circlePercentLabel = circlePercentLabel,
        shopDetailName = shopDetailName, shopDetailIconLabel = shopDetailIconLabel, shopDetailPrice = shopDetailPrice,
        shopDetailStock = shopDetailStock, shopDetailType = shopDetailType, shopDetailDurability = shopDetailDurability,
        shopInventoryLabel = shopInventoryLabel, shopBuyButton = shopBuyButton,
        shopCloseButton = shopCloseButton, sellCloseButton = sellCloseButton, objectiveCloseButton = objectiveCloseButton,
        backpackPanel = backpackPanel,
        oceanSlowdownTween = oceanSlowdownTween,
        shopBalanceLabel = shopBalanceLabel,
        menuBackdrop = menuBackdrop,
        -- 辅助函数也需要暴露给IIFE外的代码使用
        makeButton = makeButton,
        makeTextLabel = makeTextLabel,
        clearLayoutChildren = clearLayoutChildren,
        updateShopDetail = updateShopDetail,
        syncCampPanelVisibility = syncCampPanelVisibility,
        buildFingerprintText = buildFingerprintText,
        buildSessionPhaseText = buildSessionPhaseText,
        buildMazeEntryText = buildMazeEntryText,
        objectiveLabel = objectiveLabel,
        inventoryLabel = inventoryLabel,
        inventoryDetailLabel = inventoryDetailLabel,
        playerStateLabel = playerStateLabel,
        rosterLabel = rosterLabel,
        mazeLabel = mazeLabel,
        guideLabel = guideLabel,
        updateEquipSlots = updateEquipSlots,
        updateBackpackSlots = updateBackpackSlots,
        updateHealthDisplay = updateHealthDisplay,
        equipSlots = equipSlots,
        statusLabel = statusLabel,
        updatePageLabels = updatePageLabels,
        setActiveModal = setActiveModal,
        showToast = showToast,
    }
end)()

-- 解包IIFE返回的UI组件
local backpackSlots       = _ui.backpackSlots
local backpackCapacityLabel = _ui.backpackCapacityLabel
local toastLabel          = _ui.toastLabel
local goalBanner          = _ui.goalBanner
local shopPanel           = _ui.shopPanel
local sellPanel           = _ui.sellPanel
local objectivePanel      = _ui.objectivePanel
local modalBackdrop       = _ui.modalBackdrop
local oceanSplashOverlay  = _ui.oceanSplashOverlay
local oceanSlowdownOverlay = _ui.oceanSlowdownOverlay
local shopItemsFrame      = _ui.shopItemsFrame
local sellItemsFrame      = _ui.sellItemsFrame
local objectiveContent    = _ui.objectiveContent
local selectedShopItem    = _ui.selectedShopItem
local circlePercentLabel   = _ui.circlePercentLabel
local shopDetailName      = _ui.shopDetailName
local shopDetailIconLabel = _ui.shopDetailIconLabel
local shopDetailPrice     = _ui.shopDetailPrice
local shopDetailStock     = _ui.shopDetailStock
local shopDetailType      = _ui.shopDetailType
local shopDetailDurability = _ui.shopDetailDurability
local shopInventoryLabel  = _ui.shopInventoryLabel
local shopBuyButton       = _ui.shopBuyButton
local shopCloseButton     = _ui.shopCloseButton
local sellCloseButton     = _ui.sellCloseButton
local objectiveCloseButton = _ui.objectiveCloseButton
local backpackPanel       = _ui.backpackPanel
local oceanSlowdownTween  = _ui.oceanSlowdownTween
local shopBalanceLabel    = _ui.shopBalanceLabel
local menuBackdrop        = _ui.menuBackdrop
-- 辅助函数解包
local makeButton = _ui.makeButton
local makeTextLabel = _ui.makeTextLabel
local clearLayoutChildren = _ui.clearLayoutChildren
local updateShopDetail = _ui.updateShopDetail
local syncCampPanelVisibility = _ui.syncCampPanelVisibility
local buildFingerprintText = _ui.buildFingerprintText
local buildSessionPhaseText = _ui.buildSessionPhaseText
local buildMazeEntryText = _ui.buildMazeEntryText
local objectiveLabel = _ui.objectiveLabel
local inventoryLabel = _ui.inventoryLabel
local inventoryDetailLabel = _ui.inventoryDetailLabel
local playerStateLabel = _ui.playerStateLabel
local rosterLabel = _ui.rosterLabel
local mazeLabel = _ui.mazeLabel
local guideLabel = _ui.guideLabel
local updateEquipSlots = _ui.updateEquipSlots
local updateBackpackSlots = _ui.updateBackpackSlots
local updateHealthDisplay = _ui.updateHealthDisplay
local statusLabel = _ui.statusLabel
local updatePageLabels = _ui.updatePageLabels
local setActiveModal = _ui.setActiveModal
local showToast = _ui.showToast

local function renderShopItems()
    clearLayoutChildren(shopItemsFrame)
    
    -- 保存当前选中状态，重新渲染后恢复
    local prevSelectedId = selectedShopItem and selectedShopItem.Id
    
    for _, item in ipairs(activeShopItems) do
        -- 创建商品卡片Frame - 无轮廓，棕色+黄色配色
        local cardFrame = Instance.new('Frame')
        cardFrame.Name = 'ShopItemCard'
        cardFrame.Size = UDim2.new(0.48, -6, 0, 140)
        cardFrame.BackgroundColor3 = Color3.fromRGB(110, 100, 76)  -- #6E644C 棕色背景（上半）
        cardFrame.BackgroundTransparency = 0
        cardFrame.BorderSizePixel = 0
        cardFrame.Parent = shopItemsFrame
        
        local cardCorner = Instance.new('UICorner')
        cardCorner.CornerRadius = UDim.new(0, 8)
        cardCorner.Parent = cardFrame
        
        -- 道具图标 - 占满上半部分
        local iconLabel = Instance.new('TextLabel')
        iconLabel.Name = 'IconLabel'
        iconLabel.Size = UDim2.new(1, 0, 0, 85)
        iconLabel.Position = UDim2.new(0, 0, 0, 0)
        iconLabel.BackgroundTransparency = 1
        iconLabel.TextColor3 = Color3.fromRGB(255, 200, 80)  -- #FFC850 亮黄色图标
        iconLabel.Font = Enum.Font.GothamBold
        iconLabel.TextSize = 48
        iconLabel.Text = item.IconLabel or '?'
        iconLabel.Parent = cardFrame
        
        -- 底部信息区域 - 黄色背景条
        local infoFrame = Instance.new('Frame')
        infoFrame.Name = 'InfoFrame'
        infoFrame.Size = UDim2.new(1, 0, 0, 55)
        infoFrame.Position = UDim2.new(0, 0, 1, 0)
        infoFrame.AnchorPoint = Vector2.new(0, 1)
        infoFrame.BackgroundColor3 = Color3.fromRGB(255, 200, 80)  -- #FFC850 黄色背景
        infoFrame.BackgroundTransparency = 0
        infoFrame.BorderSizePixel = 0
        infoFrame.Parent = cardFrame
        
        local infoCorner = Instance.new('UICorner')
        infoCorner.CornerRadius = UDim.new(0, 8)
        infoCorner.Parent = infoFrame
        
        -- 道具名称 - 只保留中文，25字号
        local nameLabel = Instance.new('TextLabel')
        nameLabel.Name = 'NameLabel'
        nameLabel.Size = UDim2.new(1, -8, 0, 28)
        nameLabel.Position = UDim2.new(0, 4, 0, 2)
        nameLabel.BackgroundTransparency = 1
        nameLabel.TextColor3 = Color3.fromRGB(60, 45, 25)  -- 深棕色文字
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextSize = 25  -- 第一行25字号
        nameLabel.Text = item.CnName or item.Name or '未知'
        nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
        nameLabel.Parent = infoFrame
        
        -- 价格行 - 英文，20字号
        local priceLabel = Instance.new('TextLabel')
        priceLabel.Name = 'PriceLabel'
        priceLabel.Size = UDim2.new(1, -8, 0, 16)
        priceLabel.Position = UDim2.new(0, 4, 0, 26)
        priceLabel.BackgroundTransparency = 1
        priceLabel.TextColor3 = Color3.fromRGB(60, 45, 25)  -- 深棕色文字
        priceLabel.Font = Enum.Font.GothamBold
        priceLabel.TextSize = 18
        priceLabel.Text = (item.Price or 0) .. ' Pages'
        priceLabel.Parent = infoFrame

        -- 点击事件
        cardFrame.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                updateShopDetail(item)
            end
        end)
        
        -- 悬停效果
        cardFrame.InputBegan:Connect(function()
            local tween = TweenService:Create(cardFrame, TweenInfo.new(0.1), {
                BackgroundColor3 = Color3.fromRGB(130, 120, 95)
            })
            tween:Play()
        end)
        
        cardFrame.InputEnded:Connect(function()
            local tween = TweenService:Create(cardFrame, TweenInfo.new(0.1), {
                BackgroundColor3 = Color3.fromRGB(110, 100, 76)
            })
            tween:Play()
        end)
    end
end

local function renderSellItems()
    clearLayoutChildren(sellItemsFrame)

    -- 重新添加UIListLayout（clearLayoutChildren会删除旧的，但布局需要重建）
    local listLayout = Instance.new('UIListLayout')
    listLayout.Padding = UDim.new(0, 8)
    listLayout.Parent = sellItemsFrame

    if #activeSalvageItems == 0 then
        local emptyLabel =
            makeTextLabel(sellItemsFrame, UDim2.new(1, 0, 0, 24), Theme.SubtleText, 16, false)
        emptyLabel.Text = 'No salvage items available.'
        return
    end

    for _, item in ipairs(activeSalvageItems) do
        local label = string.format('%s +%d %s', item.Name, item.Price, PAGE_LABEL)
        local button = makeButton(sellItemsFrame, label, 40, Theme.Accent)
        if item.Color then
            button.TextColor3 = item.Color
        end
        button.MouseButton1Click:Connect(function()
            Remotes.RunAction:FireServer({
                Type = 'RequestSellItem',
                ItemInstanceId = item.InstanceId,
            })
        end)
        
        -- 如果是之前选中的商品，恢复选中状态
        if prevSelectedId and item.Id == prevSelectedId then
            updateShopDetail(item)
        end
    end
end

local function renderObjectiveContent()
    clearLayoutChildren(objectiveContent)

    -- 重新添加UIListLayout
    local listLayout = Instance.new('UIListLayout')
    listLayout.Padding = UDim.new(0, 8)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = objectiveContent

    local descLabel = makeTextLabel(objectiveContent, UDim2.new(1, 0, 0, 80), Theme.Text, 15, false)
    descLabel.Text = 'Collect Pages of Sand from the wilderness and exchange them at the Salvage Terminal.'
    descLabel.TextYAlignment = Enum.TextYAlignment.Top
end

shopCloseButton.MouseButton1Click:Connect(function()
    setActiveModal(nil)
end)

sellCloseButton.MouseButton1Click:Connect(function()
    setActiveModal(nil)
end)

objectiveCloseButton.MouseButton1Click:Connect(function()
    setActiveModal(nil)
end)

syncMouseMode()
actionInputConnection = UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
    if gameProcessedEvent then
        return
    end

    if input.UserInputType ~= Enum.UserInputType.Keyboard then
        return
    end

    if input.KeyCode == Enum.KeyCode.LeftShift then
        if isRunLaunched then
            Remotes.RunAction:FireServer({
                Type = 'RequestSprintStart',
            })
        end
        return
    end

    if input.KeyCode == MOUSE_TOGGLE_KEY then
        isMouseVisible = not isMouseVisible
        if isMouseVisible then
            UserInputService.MouseIconEnabled = true
            UserInputService.MouseBehavior = Enum.MouseBehavior.Default
            isMouseFree = true
            syncMouseMode()
        else
            UserInputService.MouseIconEnabled = false
            ensureFirstPersonLock()
            isMouseFree = false
            syncMouseMode()
        end
        return
    end

    -- 数字键 1-4 快捷使用装备栏道具
    local slotIndex = nil
    if input.KeyCode == Enum.KeyCode.One then
        slotIndex = 1
    elseif input.KeyCode == Enum.KeyCode.Two then
        slotIndex = 2
    elseif input.KeyCode == Enum.KeyCode.Three then
        slotIndex = 3
    elseif input.KeyCode == Enum.KeyCode.Four then
        slotIndex = 4
    end

    if slotIndex then
        local item = inventorySummary and inventorySummary.EquipSlots and inventorySummary.EquipSlots[slotIndex]
        if item then
            if isBackpackOpen then
                -- 背包打开时，移动到背包
                Remotes.RunAction:FireServer({
                    Type = 'UnequipFromSlot',
                    SlotIndex = slotIndex,
                })
            else
                -- 背包关闭时，触发道具使用
                Remotes.RunAction:FireServer({
                    Type = 'UseEquipSlot',
                    SlotIndex = slotIndex,
                })
            end
        end
        return
    end

    if input.KeyCode == Enum.KeyCode.C then
        if isRunLaunched then
            isCampPanelVisible = not isCampPanelVisible
            syncCampPanelVisibility()
        end
        return
    end

    if input.KeyCode == Enum.KeyCode.U then
        -- 按 U 打开商店
        Remotes.RunAction:FireServer({
            Type = 'RequestOpenShop',
        })
        return
    end

    if input.KeyCode == Enum.KeyCode.X and isRunLaunched then
        Remotes.RunAction:FireServer({
            Type = 'RequestUnequipItem',
        })
        return
    end

    local slotIndexByKeyCode = {
        [Enum.KeyCode.One] = 1,
        [Enum.KeyCode.Two] = 2,
        [Enum.KeyCode.Three] = 3,
    }
    local slotIndex = slotIndexByKeyCode[input.KeyCode]
    if slotIndex ~= nil and isRunLaunched then
        local itemEntry = visibleBackpackItems[slotIndex]
        if itemEntry then
            Remotes.RunAction:FireServer({
                Type = 'RequestEquipItem',
                ItemInstanceId = itemEntry.InstanceId,
            })
        end
        return
    end

    if input.KeyCode ~= Enum.KeyCode.E or not isRunLaunched or not canRequestMazeEntry then
        return
    end

    Remotes.RunAction:FireServer({
        Type = 'RequestEnterMaze',
    })
end)

sprintInputEndedConnection = UserInputService.InputEnded:Connect(function(input, gameProcessedEvent)
    if gameProcessedEvent or input.UserInputType ~= Enum.UserInputType.Keyboard then
        return
    end

    if input.KeyCode ~= Enum.KeyCode.LeftShift or not isRunLaunched then
        return
    end

    Remotes.RunAction:FireServer({
        Type = 'RequestSprintStop',
    })
end)

Remotes.RunPrivateState.OnClientEvent:Connect(function(payload)
    if type(payload) ~= 'table' then
        return
    end

    if payload.Type == 'OpenShop' then
        activeShopItems = payload.Items or {}
        inventorySummary = payload.Inventory or inventorySummary
        if type(payload.TeamPages) == 'number' then
            teamPages = payload.TeamPages
        end
        updatePageLabels()
        renderShopItems()
        setActiveModal('Shop')
        return
    end

    if payload.Type == 'OpenSell' then
        activeSalvageItems = payload.Items or {}
        if type(payload.TeamPages) == 'number' then
            teamPages = payload.TeamPages
        end
        updatePageLabels()
        renderSellItems()
        setActiveModal('Sell')
        return
    end

    if payload.Type == 'OpenObjectiveBoard' then
        if type(payload.TeamPages) == 'number' then
            teamPages = payload.TeamPages
        end
        if type(payload.BookGoalAmount) == 'number' then
            goalAmount = payload.BookGoalAmount
        end
        if type(payload.BookGoalProgress) == 'number' then
            goalProgress = payload.BookGoalProgress
        end
        updatePageLabels()
        renderObjectiveContent()
        setActiveModal('Objective')
        return
    end

    if payload.Type == 'ShopResult' then
        warn('[client] ShopResult received:', payload.Success, 'ItemId:', payload.ItemId, 'ItemStock:', payload.ItemStock)
        
        -- [BUG FIX] 无论成功还是失败，都更新库存！
        if payload.ItemId and payload.ItemStock ~= nil then
            for _, item in ipairs(activeShopItems) do
                if item.Id == payload.ItemId then
                    item.Stock = payload.ItemStock
                    warn('[ShopResult] Updated item.Stock to:', payload.ItemStock)
                    -- 如果当前详情面板显示的是这个商品，刷新详情面板
                    warn('[ShopResult] selectedShopItem:', selectedShopItem, 'Id:', selectedShopItem and selectedShopItem.Id)
                    if selectedShopItem and selectedShopItem.Id == payload.ItemId then
                        selectedShopItem.Stock = payload.ItemStock
                        updateShopDetail(selectedShopItem)
                        warn('[ShopResult] Refreshed detail panel')
                    else
                        warn('[ShopResult] Detail panel NOT refreshed - selectedShopItem is nil or different item')
                    end
                    break
                end
            end
        end
        
        if payload.Success then
            warn('[client] Showing success toast')
            playUISound('Success')
            showToast('Purchase successful!', 'Success')
        else
            local reason = payload.Reason or 'Unknown'
            warn('[client] Showing error toast:', reason)
            playUISound('Error')
            if reason == 'InsufficientFunds' then
                showToast('Insufficient Pages!', 'Error')
            elseif reason == 'OverCapacity' or reason == 'InventoryFull' then
                showToast('Backpack is full!', 'Error')
            else
                showToast('Purchase failed!', 'Error')
            end
        end

        if type(payload.TeamPages) == 'number' then
            teamPages = payload.TeamPages
        end
        if payload.Inventory then
            inventorySummary = payload.Inventory
            warn('[client] ShopResult Inventory received:', 
                'Count=', inventorySummary.Count,
                'Weight=', inventorySummary.Weight,
                'Capacity=', inventorySummary.Capacity,
                'Value=', inventorySummary.Value)
            -- 更新背包UI
            updateBackpackSlots(
                inventorySummary.BackpackItems or {},
                inventorySummary.Weight or 0,
                inventorySummary.Capacity or 20
            )
            -- 更新装备栏
            updateEquipSlots(inventorySummary.EquipSlots or {})
        else
            warn('[client] ShopResult: No Inventory in payload!')
        end
        updatePageLabels()
        return
    end

    if payload.Type == 'SellResult' then
        if payload.Success then
            showToast('Sale complete.', 'Success')
        else
            showToast('Sale failed.', 'Error')
        end

        if type(payload.TeamPages) == 'number' then
            teamPages = payload.TeamPages
        end
        if payload.ItemInstanceId then
            for index, item in ipairs(activeSalvageItems) do
                if item.InstanceId == payload.ItemInstanceId then
                    table.remove(activeSalvageItems, index)
                    break
                end
            end
            renderSellItems()
        end
        updatePageLabels()
        return
    end

    if payload.Type == 'GoalReached' then
        if type(payload.TeamPages) == 'number' then
            teamPages = payload.TeamPages
        end
        showGoalBanner()
        return
    end

    if payload.Type == 'Toast' then
        if type(payload.Message) == 'string' then
            showToast(payload.Message, payload.Tone)
        end
        return
    end

    if payload.Type == 'OceanSplash' then
        showOceanSplash(payload.Message)
        return
    end

    if payload.Type == 'OceanExit' then
        hideOceanSlowdown()
        return
    end

    if payload.Type == 'OceanDamage' then
        showOceanSplash('Drowning!')
        return
    end
end)

Remotes.RunState.OnClientEvent:Connect(function(snapshot)
    local hasLaunched = snapshot.IsLaunched == true
    isRunLaunched = hasLaunched
    if type(snapshot.BuildFingerprint) == 'string' and snapshot.BuildFingerprint ~= '' then
        activeBuildFingerprint = snapshot.BuildFingerprint
    end
    if not hasLaunched then
        isCampPanelVisible = true
        isCampPanelCollapsed = false
        collapseButton.Text = '−'
    end

    if type(snapshot.TeamPages) == 'number' then
        teamPages = snapshot.TeamPages
    end
    if type(snapshot.BookGoalAmount) == 'number' then
        goalAmount = snapshot.BookGoalAmount
    end
    if type(snapshot.BookGoalProgress) == 'number' then
        goalProgress = snapshot.BookGoalProgress
    end
    menuBackdrop.Visible = not hasLaunched
    syncCampPanelVisibility()

    if not hasLaunched then
        syncMouseMode()
        canRequestMazeEntry = false
        visibleBackpackItems = {}
        heldItemController:applyInventory(nil)
        menuStatusLabel.Text = string.format(
            '%s\n%s\n%s\nMaze Entry: %s',
            snapshot.Status,
            buildFingerprintText(snapshot),
            buildSessionPhaseText(snapshot),
            buildMazeEntryText(snapshot)
        )
        singlePlayerButton.Active = false
        singlePlayerButton.AutoButtonColor = false
        singlePlayerButton.Text = string.format('Syncing %s...', TEMPLE_LABEL)
        inventoryLabel.Text = 'Inventory: --'
        inventoryDetailLabel.Text = ''
        playerStateLabel.Text = 'Health: --\nStamina: --\nState: --\nMovement: --'
        return
    end

    syncMouseMode()
    canRequestMazeEntry = snapshot.GateOpen == true

    statusLabel.Text = string.format(
        '%s\nArea: %s | Gate: %s | Maze: %s\nEntry: %s',
        buildSessionPhaseText(snapshot),
        snapshot.Area,
        snapshot.GateOpen and 'Open' or 'Closed',
        snapshot.MazeStatus or 'idle',
        buildMazeEntryText(snapshot)
    )

    objectiveLabel.Text = string.format('%s Objective: %s', SAND_BOOK_LABEL, snapshot.Objective)

    local inventory = snapshot.Inventory or {}
    inventorySummary = inventory
    visibleBackpackItems = inventory.BackpackItems or {}
    heldItemController:applyInventory(inventory)
    
    -- 更新装备栏和背包显示
    updateEquipSlots(inventory.EquipSlots or {})
    updateBackpackSlots(
        inventory.BackpackItems or {},
        inventory.Weight or 0,
        inventory.Capacity or 20
    )
    
    updatePageLabels()
    inventoryLabel.Text = string.format(
        'Inventory: %d total | %d backpack | %d held | %d/%d KG | %d value',
        inventory.Count or 0,
        inventory.BackpackCount or 0,
        inventory.HeldCount or 0,
        inventory.Weight or 0,
        inventory.Capacity or 0,
        inventory.Value or 0
    )

    local heldItem = inventory.HeldItem
    local inventoryDetailLines = {
        heldItem and string.format(
            'Held: %s | %d KG | %d value%s',
            heldItem.Name,
            heldItem.Weight,
            heldItem.Value,
            heldItem.Light and ' | Glow active' or ''
        ) or 'Held: Empty hands',
        'Backpack:',
    }
    if #visibleBackpackItems == 0 then
        table.insert(inventoryDetailLines, '- Empty')
    else
        for itemIndex = 1, math.min(#visibleBackpackItems, 3) do
            local itemEntry = visibleBackpackItems[itemIndex]
            table.insert(
                inventoryDetailLines,
                string.format(
                    '- [%d] %s | %d KG | %d value',
                    itemIndex,
                    itemEntry.Name,
                    itemEntry.Weight,
                    itemEntry.Value
                )
            )
        end
    end
    table.insert(inventoryDetailLines, '')
    table.insert(inventoryDetailLines, 'Keys: 1-3 equip listed item | X stow held item')
    inventoryDetailLabel.Text = table.concat(inventoryDetailLines, '\n')

    local playerState = snapshot.PlayerState or {}
    local movement = snapshot.Movement or {}
    
    -- 更新左上角生命值显示
    updateHealthDisplay(playerState.HealthPips or 0, playerState.MaxHealthPips or 2)
    
    playerStateLabel.Text = string.format(
        'Health: %d/%d pips\nStamina: %d/%d\nState: %s\nMovement: %s | Sprint: %s',
        playerState.HealthPips or 0,
        playerState.MaxHealthPips or 0,
        math.floor((playerState.CurrentStamina or 0) + 0.5),
        math.floor((playerState.MaxStamina or 0) + 0.5),
        playerState.IsDead and 'Dead' or 'Alive',
        movement.Mode or 'Walk',
        FormalLocomotion.formatStatus(playerState, movement)
    )

    local rosterLines = {}
    for _, rosterEntry in ipairs(snapshot.Roster) do
        local marker = rosterEntry.UserId == localPlayer.UserId and ' (You)' or ''
        table.insert(rosterLines, string.format('%s%s', rosterEntry.Name, marker))
    end

    rosterLabel.Text = string.format('%s roster:\n', TEMPLE_LABEL)
        .. table.concat(rosterLines, '\n')

    local mazeLines = {}
    local activeMazePlayers = snapshot.PlayersInMaze or {}
    if #activeMazePlayers > 0 then
        table.insert(mazeLines, 'In maze:')
        for _, entry in ipairs(activeMazePlayers) do
            table.insert(mazeLines, string.format('- %s', entry.Name))
        end
    end

    local returnedSummaries = snapshot.ReturnedPlayerSummaries or {}
    if #returnedSummaries > 0 then
        if #mazeLines > 0 then
            table.insert(mazeLines, '')
        end
        table.insert(mazeLines, 'Returned:')
        for _, entry in ipairs(returnedSummaries) do
            table.insert(
                mazeLines,
                string.format(
                    '- %s: %d value (%s)',
                    entry.Name,
                    entry.Value or 0,
                    entry.ReturnReason or 'unknown'
                )
            )
        end
    end

    mazeLabel.Text = #mazeLines > 0 and table.concat(mazeLines, '\n')
        or 'Maze summary:\n- No players have entered the maze yet.'
end)