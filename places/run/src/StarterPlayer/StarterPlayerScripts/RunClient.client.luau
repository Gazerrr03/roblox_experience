local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService('RunService')
local TweenService = game:GetService('TweenService')
local UserInputService = game:GetService('UserInputService')

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
local isMouseFree = false
local actionInputConnection
local sprintInputEndedConnection
local isMenuMouseUnlockBound = false
local visibleBackpackItems = {}
local MENU_MOUSE_UNLOCK_STEP = 'RunMenuMouseUnlock'
local MOUSE_TOGGLE_KEY = Enum.KeyCode.LeftAlt
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
    UserInputService.MouseBehavior = Enum.MouseBehavior.Default
    UserInputService.MouseIconEnabled = true
end

local function syncMouseMode()
    if not isRunLaunched or isMouseFree or activeModal ~= nil then
        releaseFirstPersonLockForMenu()
        bindMenuMouseUnlock()
        return
    end

    unbindMenuMouseUnlock()
    ensureFirstPersonLock()
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

local function resolveHostDisplayName(snapshot)
    local hostUserId = snapshot.HostUserId
    if type(hostUserId) ~= 'number' then
        return nil
    end

    for _, rosterEntry in ipairs(snapshot.Roster or {}) do
        if rosterEntry.UserId == hostUserId then
            if hostUserId == localPlayer.UserId then
                return 'You'
            end

            return rosterEntry.Name
        end
    end

    return if hostUserId == localPlayer.UserId then 'You' else string.format('User %d', hostUserId)
end

local function buildWaitingHostText(snapshot)
    local phase = snapshot.GamePhase or 'Playing'
    if phase ~= 'Waiting' then
        return 'Run has started.'
    end

    local hostDisplayName = resolveHostDisplayName(snapshot)
    if hostDisplayName == nil then
        return 'Waiting for a host assignment...'
    end

    if snapshot.HostUserId == localPlayer.UserId then
        return 'Host: You can start the run from the ship console.'
    end

    return string.format('Host: %s can start the run from the ship console.', hostDisplayName)
end

local menuBackdrop = Instance.new('Frame')
menuBackdrop.Name = 'StartMenu'
menuBackdrop.Size = UDim2.fromScale(1, 1)
menuBackdrop.BackgroundColor3 = Theme.Background
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
panel.BorderSizePixel = 0
panel.Visible = false
panel.Parent = screenGui

applyPanelStyle(panel, 16, 0.84)

local panelPadding = Instance.new('UIPadding')
panelPadding.PaddingTop = UDim.new(0, 18)
panelPadding.PaddingLeft = UDim.new(0, 18)
panelPadding.PaddingRight = UDim.new(0, 18)
panelPadding.PaddingBottom = UDim.new(0, 18)
panelPadding.Parent = panel

local list = Instance.new('UIListLayout')
list.Padding = UDim.new(0, 10)
list.Parent = panel

local title = makeTextLabel(panel, UDim2.new(1, 0, 0, 36), Theme.Text, 28, true)
title.Text = string.format('%s Status', TEMPLE_LABEL)

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
    modalList.Parent = modal

    return modal, modalList
end

local modalBackdrop = Instance.new('Frame')
modalBackdrop.Name = 'ModalBackdrop'
modalBackdrop.Size = UDim2.fromScale(1, 1)
modalBackdrop.BackgroundColor3 = Color3.new(0, 0, 0)
modalBackdrop.BackgroundTransparency = 0.45
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

local toastLabel = Instance.new('TextLabel')
toastLabel.Name = 'Toast'
toastLabel.AnchorPoint = Vector2.new(0.5, 0.5)
toastLabel.Position = UDim2.fromScale(0.5, 0.08)
toastLabel.Size = UDim2.fromOffset(420, 42)
toastLabel.BackgroundColor3 = Theme.Surface
toastLabel.TextColor3 = Theme.Text
toastLabel.TextSize = 18
toastLabel.Font = Theme.Font
toastLabel.Text = ''
toastLabel.Visible = false
toastLabel.Parent = screenGui
applyPanelStyle(toastLabel, 12, 0.88)

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

-- Watch HUD: shows game time and remaining round time
local watchFrame = Instance.new('Frame')
watchFrame.Name = 'WatchHud'
watchFrame.AnchorPoint = Vector2.new(1, 0)
watchFrame.Position = UDim2.new(1, -16, 0, 16)
watchFrame.Size = UDim2.fromOffset(130, 58)
watchFrame.BackgroundColor3 = Color3.fromRGB(12, 10, 8)
watchFrame.BackgroundTransparency = 0.15
watchFrame.BorderSizePixel = 0
watchFrame.Visible = false
watchFrame.Parent = screenGui
local watchCorner = Instance.new('UICorner')
watchCorner.CornerRadius = UDim.new(0, 10)
watchCorner.Parent = watchFrame
local watchStroke = Instance.new('UIStroke')
watchStroke.Color = Theme.Text
watchStroke.Transparency = 0.7
watchStroke.Thickness = 1
watchStroke.Parent = watchFrame

local watchClockIcon = Instance.new('TextLabel')
watchClockIcon.Name = 'ClockIcon'
watchClockIcon.Size = UDim2.fromOffset(16, 16)
watchClockIcon.Position = UDim2.fromOffset(10, 10)
watchClockIcon.BackgroundTransparency = 1
watchClockIcon.Font = Enum.Font.GothamBold
watchClockIcon.TextColor3 = Theme.Accent
watchClockIcon.TextSize = 14
watchClockIcon.Text = '\u{1F551}'
watchClockIcon.Parent = watchFrame

local watchTimeLabel = Instance.new('TextLabel')
watchTimeLabel.Name = 'GameTime'
watchTimeLabel.Size = UDim2.new(1, -36, 0, 22)
watchTimeLabel.Position = UDim2.fromOffset(30, 6)
watchTimeLabel.BackgroundTransparency = 1
watchTimeLabel.Font = Enum.Font.GothamBold
watchTimeLabel.TextColor3 = Theme.Text
watchTimeLabel.TextSize = 18
watchTimeLabel.TextXAlignment = Enum.TextXAlignment.Left
watchTimeLabel.TextYAlignment = Enum.TextYAlignment.Center
watchTimeLabel.Text = '07:00'
watchTimeLabel.Parent = watchFrame

local watchRemainLabel = Instance.new('TextLabel')
watchRemainLabel.Name = 'Remaining'
watchRemainLabel.Size = UDim2.new(1, -20, 0, 18)
watchRemainLabel.Position = UDim2.fromOffset(10, 34)
watchRemainLabel.BackgroundTransparency = 1
watchRemainLabel.Font = Theme.Font
watchRemainLabel.TextColor3 = Theme.SubtleText
watchRemainLabel.TextSize = 13
watchRemainLabel.TextXAlignment = Enum.TextXAlignment.Left
watchRemainLabel.TextYAlignment = Enum.TextYAlignment.Center
watchRemainLabel.Text = '\u{21BB} 15:00'
watchRemainLabel.Parent = watchFrame

local function formatGameTime(gameHour)
    local totalMinutes = math.floor(gameHour * 60)
    local h = math.floor(totalMinutes / 60)
    local m = totalMinutes % 60
    return string.format('%02d:%02d', h, m)
end

local function formatRemaining(seconds)
    local m = math.floor(seconds / 60)
    local s = math.floor(seconds % 60)
    return string.format('\u{21BB} %02d:%02d', m, s)
end

local todConnection = nil
local lastTodState = nil

local function updateWatch(todState)
    if not todState then
        watchFrame.Visible = false
        return
    end
    local gameHour = todState.GameHour or 7
    local remaining = todState.RoundTimeRemaining or 0
    watchTimeLabel.Text = formatGameTime(gameHour)
    watchRemainLabel.Text = formatRemaining(remaining)
    watchFrame.Visible = true
    -- Tint red when under 3 minutes
    if remaining < 180 then
        watchTimeLabel.TextColor3 = Color3.fromRGB(220, 80, 80)
        watchRemainLabel.TextColor3 = Color3.fromRGB(220, 80, 80)
    else
        watchTimeLabel.TextColor3 = Theme.Text
        watchRemainLabel.TextColor3 = Theme.SubtleText
    end
end

local function connectTODRemote()
    if todConnection then
        todConnection:Disconnect()
        todConnection = nil
    end
    local remoteFolder = ReplicatedStorage:WaitForChild('Remotes', 5)
    if not remoteFolder then
        return
    end
    local todRemote = remoteFolder:WaitForChild('TODState', 3)
    if not todRemote then
        return
    end
    todConnection = todRemote.OnClientEvent:Connect(function(todState)
        lastTodState = todState
        updateWatch(todState)
    end)
    if lastTodState then
        updateWatch(lastTodState)
    end
end

-- Connect to TODState when the remote is available
task.spawn(connectTODRemote)

local shopPanel = createModalPanel('ShopPanel', UDim2.fromOffset(460, 520))
local shopTitle = makeTextLabel(shopPanel, UDim2.new(1, 0, 0, 32), Theme.Text, 26, true)
shopTitle.Text = 'Temple Shop'

local shopPageLabel = makeTextLabel(shopPanel, UDim2.new(1, 0, 0, 24), Theme.SubtleText, 16, false)
shopPageLabel.Text = 'Team Pages: 0'

local shopInventoryLabel =
    makeTextLabel(shopPanel, UDim2.new(1, 0, 0, 24), Theme.SubtleText, 16, false)
shopInventoryLabel.Text = 'Inventory: --'

local shopItemsFrame = Instance.new('Frame')
shopItemsFrame.Size = UDim2.new(1, 0, 1, -210)
shopItemsFrame.BackgroundTransparency = 1
shopItemsFrame.Parent = shopPanel

local shopItemsList = Instance.new('UIListLayout')
shopItemsList.Padding = UDim.new(0, 8)
shopItemsList.Parent = shopItemsFrame

local shopCloseButton = makeButton(shopPanel, 'Close', 44, Theme.Warning)

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

local objectivePanel = createModalPanel('ObjectivePanel', UDim2.fromOffset(440, 360))
local objectiveTitle = makeTextLabel(objectivePanel, UDim2.new(1, 0, 0, 32), Theme.Text, 26, true)
objectiveTitle.Text = 'Book of Sand Board'

local objectiveGoalLabel =
    makeTextLabel(objectivePanel, UDim2.new(1, 0, 0, 24), Theme.SubtleText, 16, false)
objectiveGoalLabel.Text = 'Goal: 0 Pages'

local objectiveProgressLabel =
    makeTextLabel(objectivePanel, UDim2.new(1, 0, 0, 24), Theme.SubtleText, 16, false)
objectiveProgressLabel.Text = 'Progress: 0%'

local progressBarBack = Instance.new('Frame')
progressBarBack.Size = UDim2.new(1, 0, 0, 18)
progressBarBack.BackgroundColor3 = Theme.Background
progressBarBack.BorderSizePixel = 0
progressBarBack.Parent = objectivePanel

local progressBarFill = Instance.new('Frame')
progressBarFill.Size = UDim2.fromScale(0, 1)
progressBarFill.BackgroundColor3 = Theme.Accent
progressBarFill.BorderSizePixel = 0
progressBarFill.Parent = progressBarBack

local progressCorner = Instance.new('UICorner')
progressCorner.CornerRadius = UDim.new(0, 8)
progressCorner.Parent = progressBarBack

local progressFillCorner = Instance.new('UICorner')
progressFillCorner.CornerRadius = UDim.new(0, 8)
progressFillCorner.Parent = progressBarFill

local objectiveCloseButton = makeButton(objectivePanel, 'Close', 44, Theme.Warning)

local function syncCampPanelVisibility()
    panel.Visible = isRunLaunched and isCampPanelVisible
end

local function setActiveModal(nextModal)
    activeModal = nextModal
    local showModal = nextModal ~= nil

    modalBackdrop.Visible = showModal
    shopPanel.Visible = nextModal == 'Shop'
    sellPanel.Visible = nextModal == 'Sell'
    objectivePanel.Visible = nextModal == 'Objective'

    syncMouseMode()
end

local function updateObjectiveUi()
    local clampedProgress = math.clamp(goalProgress, 0, 1)
    objectiveGoalLabel.Text = string.format('Goal: %d %s', goalAmount, PAGE_LABEL)
    objectiveProgressLabel.Text =
        string.format('%s: %d%%', SAND_BOOK_PROGRESS_LABEL, math.floor(clampedProgress * 100 + 0.5))
    progressBarFill.Size = UDim2.fromScale(clampedProgress, 1)
end

local function updatePageLabels()
    shopPageLabel.Text = string.format('Team %s: %d', PAGE_LABEL, teamPages)
    sellPageLabel.Text = string.format('Team %s: %d', PAGE_LABEL, teamPages)
    updateObjectiveUi()

    if inventorySummary then
        shopInventoryLabel.Text = string.format(
            'Inventory: %d total | %d/%d KG | %d value',
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
        color = Theme.Accent
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

local function renderShopItems()
    clearLayoutChildren(shopItemsFrame)

    for _, item in ipairs(activeShopItems) do
        local label = string.format('%s - %d %s', item.Name, item.Price, PAGE_LABEL)
        local button = makeButton(shopItemsFrame, label, 40, Theme.Accent)
        button.MouseButton1Click:Connect(function()
            Remotes.RunAction:FireServer({
                Type = 'RequestPurchaseItem',
                ItemId = item.Id,
            })
        end)
    end
end

local function renderSellItems()
    clearLayoutChildren(sellItemsFrame)

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
    end
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
        isMouseFree = not isMouseFree
        syncMouseMode()
        return
    end

    if input.KeyCode == Enum.KeyCode.C then
        if isRunLaunched then
            isCampPanelVisible = not isCampPanelVisible
            syncCampPanelVisibility()
        end
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
        setActiveModal('Objective')
        return
    end

    if payload.Type == 'ShopResult' then
        if payload.Success then
            showToast('Purchase complete.', 'Success')
        else
            local reason = payload.Reason or 'Unknown'
            if reason == 'InsufficientFunds' then
                showToast('Not enough pages.', 'Error')
            elseif reason == 'OverCapacity' or reason == 'InventoryFull' then
                showToast('Inventory is full.', 'Error')
            else
                showToast('Purchase failed.', 'Error')
            end
        end

        if type(payload.TeamPages) == 'number' then
            teamPages = payload.TeamPages
        end
        if payload.Inventory then
            inventorySummary = payload.Inventory
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
            '%s\n%s\n%s\n%s\nMaze Entry: %s',
            snapshot.Status,
            buildFingerprintText(snapshot),
            buildSessionPhaseText(snapshot),
            buildWaitingHostText(snapshot),
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
        '%s\n%s\n%s\n%s\nArea: %s | Gate: %s | Maze: %s\nEntry: %s',
        snapshot.Status,
        buildFingerprintText(snapshot),
        buildSessionPhaseText(snapshot),
        buildWaitingHostText(snapshot),
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
        local markerParts = {}
        if rosterEntry.UserId == localPlayer.UserId then
            table.insert(markerParts, 'You')
        end
        if rosterEntry.UserId == snapshot.HostUserId then
            table.insert(markerParts, 'Host')
        end
        local marker = if #markerParts > 0
            then string.format(' (%s)', table.concat(markerParts, ', '))
            else ''
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
