local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService('RunService')
local UserInputService = game:GetService('UserInputService')

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild('PlayerGui')

local Packages = ReplicatedStorage:WaitForChild('Packages')
local GameplayPackage = Packages:WaitForChild('Gameplay')
local SharedPackage = Packages:WaitForChild('Shared')
local UIPackage = Packages:WaitForChild('UI')

local ItemPresentation =
    require(GameplayPackage:WaitForChild('Config'):WaitForChild('ItemPresentation'))
local FormalLocomotion =
    require(SharedPackage:WaitForChild('Runtime'):WaitForChild('FormalLocomotion'))
local HeldToolVisual = require(SharedPackage:WaitForChild('Client'):WaitForChild('HeldToolVisual'))
local HeldItemController =
    require(SharedPackage:WaitForChild('Client'):WaitForChild('HeldItemController'))
local FirstPersonController =
    require(SharedPackage:WaitForChild('Client'):WaitForChild('FirstPersonController'))
local RemotesModule = require(SharedPackage:WaitForChild('Network'):WaitForChild('Remotes'))
local Theme = require(UIPackage:WaitForChild('Hud'):WaitForChild('Theme'))
local heldItemController = HeldItemController.new(localPlayer)
local REMOTE_WAIT_TIMEOUT_SECONDS = 10
local WAITING_STATUS_TEXT = '正在等待迷宫状态同步...'
local INITIAL_DIAGNOSTIC_TEXT = '诊断信息：正在等待启动信号...'
local REMOTE_WAIT_TIMEOUT_TEXT =
    '仍在等待服务端快照。可能是 remote 还没准备好，或者迷宫启动失败了。'

FirstPersonController.start(localPlayer)

local Remotes
local actionInputConnection
local sprintInputEndedConnection
local visibleBackpackItems = {}
local didReceiveInitialSnapshot = false
local lastToolUseRequestAt = -math.huge
local heldToolCooldownSeconds = 0.2
local mazeInventoryForSwing: { [string]: any }? = nil

local function presentationIconSuffix(itemEntry: { [string]: any }?)
    if type(itemEntry) ~= 'table' then
        return ''
    end
    local uri = ItemPresentation.formatIconContentId(itemEntry.IconAssetId)
    if uri ~= '' then
        return ' | 2D 图标'
    end
    return ''
end

local function localizeSessionPhase(sessionPhase)
    local labels = {
        MazeActive = '迷宫进行中',
        RunIntermission = '本轮完成',
        FinalDebrief = '最终结算',
        SessionClosed = '会话关闭',
        RunPrep = '准备阶段',
        RunField = '外场阶段',
    }
    return labels[sessionPhase] or tostring(sessionPhase or '迷宫进行中')
end

local function localizeLoopState(state)
    local labels = {
        Staging = '准备中',
        Expedition = '探索中',
        Extraction = '撤离中',
        Settlement = '结算中',
        Completed = '已完成',
        Camp = '营地',
    }
    return labels[state] or tostring(state or '探索中')
end

local function localizeMazeStatus(mazeStatus)
    local labels = {
        active = '进行中',
        completed = '已完成',
        idle = '未开始',
    }
    return labels[mazeStatus] or tostring(mazeStatus or '进行中')
end

local function localizeBuildSource(source)
    local labels = {
        ContentHarness = '内容测试场',
        DirectBootDefault = '本地直启',
        JoinDataMergedBeforeBuild = '进场前合并',
        JoinDataMergedAfterBuild = '进场后合并',
    }
    return labels[source] or tostring(source or '内容测试场')
end

local function localizeReturnReason(reason)
    local labels = {
        returned = '已返回',
        death = '死亡',
        settled = '强制结算',
        timeout = '超时',
    }
    return labels[reason] or tostring(reason or '未知')
end

local function localizeRoomArea(areaText)
    local labels = {
        ['Maze Staging'] = '迷宫准备区',
        ['Loot Room'] = '战利品房',
        ['Camp Room'] = '营地区',
        ['Monster Room'] = '怪物房',
    }
    return labels[areaText] or tostring(areaText or '未知区域')
end

local function localizeMovementStatus(status)
    local labels = {
        Disabled = '不可行动',
        Ready = '可冲刺',
        Recovering = '恢复中',
    }
    return labels[status] or tostring(status or '未知')
end

local function readBootstrapDiagnostic()
    local failed = ReplicatedStorage:GetAttribute('MazeBootstrapFailed')
    local phase = ReplicatedStorage:GetAttribute('MazeBootstrapPhase')
    local err = ReplicatedStorage:GetAttribute('MazeBootstrapError')
    if failed ~= true and phase == nil and err == nil then
        return nil
    end

    local lines = {}
    if phase ~= nil then
        table.insert(lines, string.format('阶段：%s', tostring(phase)))
    end
    if err ~= nil then
        table.insert(lines, string.format('错误：%s', tostring(err)))
    end

    if #lines == 0 then
        return nil
    end

    return table.concat(lines, '\n')
end

local screenGui = Instance.new('ScreenGui')
screenGui.Name = 'MazeHud'
screenGui.IgnoreGuiInset = true
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

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

local function formatGameTimeMaze(gameHour)
    local totalMinutes = math.floor(gameHour * 60)
    local h = math.floor(totalMinutes / 60)
    local m = totalMinutes % 60
    return string.format('%02d:%02d', h, m)
end

local function formatRemainingMaze(seconds)
    local m = math.floor(seconds / 60)
    local s = math.floor(seconds % 60)
    return string.format('\u{21BB} %02d:%02d', m, s)
end

local _todConnectionMaze = nil
local lastTodStateMaze = nil

local function updateWatchMaze(todState)
    if not todState then
        watchFrame.Visible = false
        return
    end
    local gameHour = todState.GameHour or 7
    local remaining = todState.RoundTimeRemaining or 0
    watchTimeLabel.Text = formatGameTimeMaze(gameHour)
    watchRemainLabel.Text = formatRemainingMaze(remaining)
    watchFrame.Visible = true
    if remaining < 180 then
        watchTimeLabel.TextColor3 = Color3.fromRGB(220, 80, 80)
        watchRemainLabel.TextColor3 = Color3.fromRGB(220, 80, 80)
    else
        watchTimeLabel.TextColor3 = Theme.Text
        watchRemainLabel.TextColor3 = Theme.SubtleText
    end
end

task.spawn(function()
    local remoteFolder = ReplicatedStorage:WaitForChild('Remotes', 5)
    if not remoteFolder then
        return
    end
    local todRemote = remoteFolder:WaitForChild('TODState', 3)
    if not todRemote then
        return
    end
    _todConnectionMaze = todRemote.OnClientEvent:Connect(function(todState)
        lastTodStateMaze = todState
        updateWatchMaze(todState)
    end)
    if lastTodStateMaze then
        updateWatchMaze(lastTodStateMaze)
    end
end)

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

local function applyPanelStyle(frame, cornerRadius, backgroundTransparency)
    frame.BackgroundColor3 = Theme.Background
    frame.BackgroundTransparency = backgroundTransparency or 0.18
    frame.BorderSizePixel = 0

    local corner = Instance.new('UICorner')
    corner.CornerRadius = UDim.new(0, cornerRadius or 14)
    corner.Parent = frame

    local stroke = Instance.new('UIStroke')
    stroke.Color = Theme.Text
    stroke.Transparency = 0.72
    stroke.Thickness = 1
    stroke.Parent = frame
end

local function makePanel(parent, name, position, size, anchorPoint, transparency)
    local frame = Instance.new('Frame')
    frame.Name = name
    frame.AnchorPoint = anchorPoint or Vector2.zero
    frame.Position = position
    frame.Size = size
    frame.Parent = parent
    applyPanelStyle(frame, 14, transparency)
    return frame
end

local function makeSectionTitle(parent, text)
    local label = makeTextLabel(parent, UDim2.new(1, 0, 0, 18), Theme.SubtleText, 12, true)
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.Text = text
    return label
end

local function makeDivider(parent)
    local divider = Instance.new('Frame')
    divider.Size = UDim2.new(1, 0, 0, 1)
    divider.BackgroundColor3 = Theme.Text
    divider.BackgroundTransparency = 0.82
    divider.BorderSizePixel = 0
    divider.Parent = parent
    return divider
end

local function buildQuickSlotGlyph(itemEntry)
    if type(itemEntry) ~= 'table' then
        return ''
    end

    local toolCategory = itemEntry.ToolCategory
    if toolCategory == 'Flashlight' then
        return '灯'
    elseif toolCategory == 'Crowbar' then
        return '撬'
    elseif toolCategory == 'Potion' then
        return '药'
    end

    local itemCategory = itemEntry.ItemCategory
    if itemCategory == 'Loot' then
        return '资'
    elseif itemCategory == 'Clue' then
        return '线'
    elseif itemCategory == 'Tool' then
        return '工'
    end

    return '包'
end

local function truncateText(text, maxLength)
    local value = tostring(text or '')
    if #value <= maxLength then
        return value
    end

    return string.sub(value, 1, math.max(0, maxLength - 1)) .. '…'
end

local topHudFrame = Instance.new('Frame')
topHudFrame.Name = 'TopHud'
topHudFrame.AnchorPoint = Vector2.zero
topHudFrame.Position = UDim2.new(0, 16, 0, 16)
topHudFrame.Size = UDim2.fromOffset(380, 190)
topHudFrame.BackgroundTransparency = 1
topHudFrame.Parent = screenGui

local healthPanel = makePanel(
    topHudFrame,
    'HealthPanel',
    UDim2.fromOffset(0, 0),
    UDim2.fromOffset(130, 76),
    Vector2.zero,
    0.16
)
local healthTitle = makeSectionTitle(healthPanel, '生命')
healthTitle.Position = UDim2.fromOffset(12, 8)
local healthValueLabel =
    makeTextLabel(healthPanel, UDim2.new(1, -24, 0, 18), Theme.SubtleText, 13, false)
healthValueLabel.Position = UDim2.fromOffset(12, 52)
healthValueLabel.Text = '等待同步'

local healthHearts = {}
for index = 1, 4 do
    local heart = makeTextLabel(healthPanel, UDim2.fromOffset(22, 26), Theme.Warning, 24, true)
    heart.Position = UDim2.fromOffset(12 + (index - 1) * 24, 22)
    heart.TextXAlignment = Enum.TextXAlignment.Center
    heart.TextYAlignment = Enum.TextYAlignment.Center
    heart.Text = '♥'
    heart.Visible = false
    healthHearts[index] = heart
end

local staminaPanel = makePanel(
    topHudFrame,
    'StaminaPanel',
    UDim2.fromOffset(142, 0),
    UDim2.fromOffset(238, 76),
    Vector2.zero,
    0.16
)
local staminaTitle = makeSectionTitle(staminaPanel, '体力 / 冲刺')
staminaTitle.Position = UDim2.fromOffset(12, 8)
local staminaValueLabel =
    makeTextLabel(staminaPanel, UDim2.new(1, -24, 0, 18), Theme.Text, 16, true)
staminaValueLabel.Position = UDim2.fromOffset(12, 24)
staminaValueLabel.Text = '-- / --'

local staminaTrack = Instance.new('Frame')
staminaTrack.Name = 'StaminaTrack'
staminaTrack.Size = UDim2.new(1, -24, 0, 12)
staminaTrack.Position = UDim2.fromOffset(12, 48)
staminaTrack.BackgroundColor3 = Theme.Surface
staminaTrack.BackgroundTransparency = 0.25
staminaTrack.BorderSizePixel = 0
staminaTrack.Parent = staminaPanel
local staminaTrackCorner = Instance.new('UICorner')
staminaTrackCorner.CornerRadius = UDim.new(0, 6)
staminaTrackCorner.Parent = staminaTrack

local staminaFill = Instance.new('Frame')
staminaFill.Name = 'StaminaFill'
staminaFill.Size = UDim2.new(0, 0, 1, 0)
staminaFill.BackgroundColor3 = Theme.Accent
staminaFill.BorderSizePixel = 0
staminaFill.Parent = staminaTrack
local staminaFillCorner = Instance.new('UICorner')
staminaFillCorner.CornerRadius = UDim.new(0, 6)
staminaFillCorner.Parent = staminaFill

local staminaStatusLabel =
    makeTextLabel(staminaPanel, UDim2.new(1, -24, 0, 16), Theme.SubtleText, 13, false)
staminaStatusLabel.Position = UDim2.fromOffset(12, 62)
staminaStatusLabel.Text = '等待同步'

local statusPanel = makePanel(
    topHudFrame,
    'StatusPanel',
    UDim2.fromOffset(0, 88),
    UDim2.fromOffset(380, 102),
    Vector2.zero,
    0.16
)
local statusAreaLabel =
    makeTextLabel(statusPanel, UDim2.new(1, -24, 0, 18), Theme.SubtleText, 13, true)
statusAreaLabel.Position = UDim2.fromOffset(12, 10)
statusAreaLabel.Text = '区域：等待同步'

local statusSummaryLabel =
    makeTextLabel(statusPanel, UDim2.new(1, -24, 0, 24), Theme.Text, 20, true)
statusSummaryLabel.Position = UDim2.fromOffset(12, 28)
statusSummaryLabel.Text = WAITING_STATUS_TEXT
statusSummaryLabel.TextYAlignment = Enum.TextYAlignment.Center

local objectiveSummaryLabel =
    makeTextLabel(statusPanel, UDim2.new(1, -24, 0, 18), Theme.Accent, 15, false)
objectiveSummaryLabel.Position = UDim2.fromOffset(12, 58)
objectiveSummaryLabel.Text = '目标：--'

local heldStatusLabel =
    makeTextLabel(statusPanel, UDim2.new(1, -24, 0, 16), Theme.SubtleText, 13, false)
heldStatusLabel.Position = UDim2.fromOffset(12, 78)
heldStatusLabel.Text = '当前手持：空手'

local panel = makePanel(
    screenGui,
    'MazePanel',
    UDim2.new(0, 16, 0, 220),
    UDim2.fromOffset(360, 382),
    Vector2.zero,
    0.1
)

local panelPadding = Instance.new('UIPadding')
panelPadding.PaddingTop = UDim.new(0, 16)
panelPadding.PaddingLeft = UDim.new(0, 16)
panelPadding.PaddingRight = UDim.new(0, 16)
panelPadding.PaddingBottom = UDim.new(0, 16)
panelPadding.Parent = panel

local list = Instance.new('UIListLayout')
list.Padding = UDim.new(0, 10)
list.Parent = panel

local title = makeTextLabel(panel, UDim2.new(1, 0, 0, 24), Theme.Text, 22, true)
title.Text = '详细信息'
title.TextYAlignment = Enum.TextYAlignment.Center

local statusLabel = makeTextLabel(panel, UDim2.new(1, 0, 0, 56), Theme.SubtleText, 16, false)
statusLabel.Text = WAITING_STATUS_TEXT

local diagnosticLabel = makeTextLabel(panel, UDim2.new(1, 0, 0, 64), Theme.Warning, 15, false)
diagnosticLabel.Text = INITIAL_DIAGNOSTIC_TEXT

local function showSnapshotTimeout(fallbackDiagnosticText)
    local diagnostic = readBootstrapDiagnostic()
    statusLabel.Text = string.format('%s\n%s', WAITING_STATUS_TEXT, REMOTE_WAIT_TIMEOUT_TEXT)
    statusSummaryLabel.Text = '迷宫还没准备好'
    statusAreaLabel.Text = '区域：等待同步'
    objectiveSummaryLabel.Text = '目标：等待服务端状态'
    heldStatusLabel.Text = '当前手持：空手'
    diagnosticLabel.Text = diagnostic or fallbackDiagnosticText
end

task.delay(REMOTE_WAIT_TIMEOUT_SECONDS, function()
    if didReceiveInitialSnapshot then
        diagnosticLabel.Text = ''
        return
    end

    showSnapshotTimeout('诊断信息：客户端还没有收到任何迷宫启动属性。')
end)

makeDivider(panel)

local objectiveLabel = makeTextLabel(panel, UDim2.new(1, 0, 0, 50), Theme.Accent, 16, false)
objectiveLabel.Text = '目标：--'

local promptLabel = makeTextLabel(panel, UDim2.new(1, 0, 0, 72), Theme.Text, 14, false)
promptLabel.Text =
    '交互：拾取战利品 / 开关门 / 返回\n按键：1-3 装备 | F 使用 | X 收起 | Shift 冲刺'

if RunService:IsStudio() then
    promptLabel.Text ..= '\nStudio 调试：H 轻伤 | J 重伤'
end

makeDivider(panel)

local inventoryLabel = makeTextLabel(panel, UDim2.new(1, 0, 0, 40), Theme.Warning, 15, false)
inventoryLabel.Text = '背包：--'

local inventoryDetailLabel = makeTextLabel(panel, UDim2.new(1, 0, 0, 102), Theme.Text, 14, false)
inventoryDetailLabel.Text = ''

makeDivider(panel)

local playerStateLabel = makeTextLabel(panel, UDim2.new(1, 0, 0, 72), Theme.Warning, 15, false)
playerStateLabel.Text = '生命：--\n体力：--\n状态：--\n移动：--'

local rosterLabel = makeTextLabel(panel, UDim2.new(1, 0, 0, 78), Theme.SubtleText, 14, false)
rosterLabel.Text = ''

local returnedLabel = makeTextLabel(panel, UDim2.new(1, 0, 0, 86), Theme.SubtleText, 14, false)
returnedLabel.Text = ''

local quickbarPanel = makePanel(
    screenGui,
    'QuickbarPanel',
    UDim2.new(1, -18, 0.5, -84),
    UDim2.fromOffset(94, 244),
    Vector2.new(1, 0.5),
    0.08
)
local quickbarPadding = Instance.new('UIPadding')
quickbarPadding.PaddingTop = UDim.new(0, 10)
quickbarPadding.PaddingLeft = UDim.new(0, 10)
quickbarPadding.PaddingRight = UDim.new(0, 10)
quickbarPadding.PaddingBottom = UDim.new(0, 10)
quickbarPadding.Parent = quickbarPanel
local quickbarTitle = makeSectionTitle(quickbarPanel, '快捷栏')
quickbarTitle.Position = UDim2.fromOffset(0, 0)

local quickbarSlots = {}
for slotIndex = 1, 3 do
    local slotFrame = makePanel(
        quickbarPanel,
        string.format('QuickSlot_%d', slotIndex),
        UDim2.fromOffset(0, 24 + (slotIndex - 1) * 68),
        UDim2.fromOffset(74, 58),
        Vector2.zero,
        0.02
    )
    slotFrame.BackgroundTransparency = 0.02

    local keyLabel = makeTextLabel(slotFrame, UDim2.fromOffset(18, 16), Theme.SubtleText, 12, true)
    keyLabel.Position = UDim2.fromOffset(8, 6)
    keyLabel.Text = tostring(slotIndex)
    keyLabel.TextXAlignment = Enum.TextXAlignment.Center
    keyLabel.TextYAlignment = Enum.TextYAlignment.Center

    local glyphLabel = makeTextLabel(slotFrame, UDim2.fromOffset(54, 24), Theme.Accent, 24, true)
    glyphLabel.Position = UDim2.fromOffset(10, 18)
    glyphLabel.Text = '—'
    glyphLabel.TextXAlignment = Enum.TextXAlignment.Center
    glyphLabel.TextYAlignment = Enum.TextYAlignment.Center

    local nameLabel = makeTextLabel(slotFrame, UDim2.new(1, -16, 0, 16), Theme.Text, 12, false)
    nameLabel.Position = UDim2.fromOffset(8, 40)
    nameLabel.TextXAlignment = Enum.TextXAlignment.Center
    nameLabel.TextYAlignment = Enum.TextYAlignment.Center
    nameLabel.Text = '空'

    quickbarSlots[slotIndex] = {
        Frame = slotFrame,
        Glyph = glyphLabel,
        Name = nameLabel,
    }
end

local hintsPanel = makePanel(
    screenGui,
    'HintsPanel',
    UDim2.new(0.5, 0, 1, -16),
    UDim2.fromOffset(426, 70),
    Vector2.new(0.5, 1),
    0.08
)
local hintsTitle = makeSectionTitle(hintsPanel, '常用按键')
hintsTitle.Position = UDim2.fromOffset(14, 8)

local hintsLabel = makeTextLabel(hintsPanel, UDim2.new(1, -28, 0, 36), Theme.Text, 14, false)
hintsLabel.Position = UDim2.fromOffset(14, 26)
hintsLabel.Text = 'Shift 冲刺   F 使用工具   X 收起手持   1-3 快速装备'
hintsLabel.TextYAlignment = Enum.TextYAlignment.Center

local function updateHealthDisplay(currentHealthPips, maxHealthPips)
    local maxPips = math.clamp(math.floor(tonumber(maxHealthPips) or 0), 0, #healthHearts)
    local currentPips = math.clamp(math.floor(tonumber(currentHealthPips) or 0), 0, maxPips)

    for index, heart in ipairs(healthHearts) do
        heart.Visible = index <= math.max(maxPips, 1)
        heart.TextColor3 = if index <= currentPips then Theme.Warning else Theme.SubtleText
        heart.TextTransparency = if index <= currentPips then 0 else 0.35
    end

    healthValueLabel.Text = string.format('%d / %d 格', currentPips, math.max(maxPips, 1))
end

local function updateStaminaDisplay(currentStamina, maxStamina, movementStatus, isSprinting)
    local currentValue = math.max(0, tonumber(currentStamina) or 0)
    local maxValue = math.max(1, tonumber(maxStamina) or 1)
    local ratio = math.clamp(currentValue / maxValue, 0, 1)

    staminaValueLabel.Text =
        string.format('%d / %d', math.floor(currentValue + 0.5), math.floor(maxValue + 0.5))
    staminaFill.Size = UDim2.new(ratio, 0, 1, 0)
    if ratio >= 0.6 then
        staminaFill.BackgroundColor3 = Theme.Accent
    elseif ratio >= 0.25 then
        staminaFill.BackgroundColor3 = Theme.Warning
    else
        staminaFill.BackgroundColor3 = Color3.fromRGB(220, 80, 80)
    end

    staminaStatusLabel.Text =
        string.format('%s%s', movementStatus, isSprinting and ' | 正在冲刺' or '')
end

local function updateQuickbarDisplay(inventory)
    local backpackItems = if type(inventory) == 'table' then inventory.BackpackItems or {} else {}
    for slotIndex, slot in ipairs(quickbarSlots) do
        local itemEntry = backpackItems[slotIndex]
        if itemEntry then
            slot.Glyph.Text = buildQuickSlotGlyph(itemEntry)
            slot.Glyph.TextColor3 = Theme.Accent
            slot.Name.Text = truncateText(itemEntry.Name or itemEntry.ItemCategory or '物品', 5)
            slot.Name.TextColor3 = Theme.Text
        else
            slot.Glyph.Text = '—'
            slot.Glyph.TextColor3 = Theme.SubtleText
            slot.Name.Text = '空'
            slot.Name.TextColor3 = Theme.SubtleText
        end
    end
end

actionInputConnection = UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
    if gameProcessedEvent or input.UserInputType ~= Enum.UserInputType.Keyboard then
        return
    end

    if Remotes == nil then
        return
    end

    if input.KeyCode == Enum.KeyCode.LeftShift then
        Remotes.MazeAction:FireServer({
            Type = 'RequestSprintStart',
        })
        return
    end

    -- === 新增：监听 F 键并发送 RequestUseTool ===
    if input.KeyCode == Enum.KeyCode.F then
        local now = os.clock()
        if now - lastToolUseRequestAt < heldToolCooldownSeconds then
            return
        end

        lastToolUseRequestAt = now
        local heldForSwing = mazeInventoryForSwing and mazeInventoryForSwing.HeldItem
        if heldForSwing and heldForSwing.ToolCategory == 'Crowbar' then
            HeldToolVisual.playCrowbarSwingFeedback(localPlayer.Character)
        end
        Remotes.MazeAction:FireServer({
            Type = 'RequestUseTool',
        })
        return
    end

    if RunService:IsStudio() and input.KeyCode == Enum.KeyCode.H then
        Remotes.MazeAction:FireServer({
            Type = 'RequestDebugLightDamage',
        })
        return
    end

    if RunService:IsStudio() and input.KeyCode == Enum.KeyCode.J then
        Remotes.MazeAction:FireServer({
            Type = 'RequestDebugHeavyDamage',
        })
        return
    end

    if input.KeyCode == Enum.KeyCode.X then
        Remotes.MazeAction:FireServer({
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
    if slotIndex == nil then
        return
    end

    local itemEntry = visibleBackpackItems[slotIndex]
    if not itemEntry then
        return
    end

    Remotes.MazeAction:FireServer({
        Type = 'RequestEquipItem',
        ItemInstanceId = itemEntry.InstanceId,
    })
end)

sprintInputEndedConnection = UserInputService.InputEnded:Connect(function(input, gameProcessedEvent)
    if gameProcessedEvent or input.UserInputType ~= Enum.UserInputType.Keyboard then
        return
    end
    if Remotes == nil then
        return
    end

    if input.KeyCode ~= Enum.KeyCode.LeftShift then
        return
    end

    Remotes.MazeAction:FireServer({
        Type = 'RequestSprintStop',
    })
end)

script.Destroying:Connect(function()
    if actionInputConnection then
        actionInputConnection:Disconnect()
        actionInputConnection = nil
    end

    if sprintInputEndedConnection then
        sprintInputEndedConnection:Disconnect()
        sprintInputEndedConnection = nil
    end
    if _todConnectionMaze then
        _todConnectionMaze:Disconnect()
        _todConnectionMaze = nil
    end

    heldItemController:destroy()
end)

local function connectMazeRemotes(remotes)
    remotes.MazePrivateState.OnClientEvent:Connect(function()
        -- The first maze HUD does not surface per-player private state yet.
    end)

    remotes.MazeState.OnClientEvent:Connect(function(snapshot)
        if snapshot.IsLaunched ~= true then
            return
        end

        didReceiveInitialSnapshot = true
        diagnosticLabel.Text = ''
        local diagnosticSeed = snapshot.WorldBuildSeed ~= nil and tostring(snapshot.WorldBuildSeed)
            or '--'
        local diagnosticDirect = snapshot.WorldBuildIsDirectBoot == true and '是' or '否'
        local diagnosticSource = localizeBuildSource(snapshot.WorldBuildSource)
        local localizedArea = localizeRoomArea(snapshot.Area)
        local localizedLoopState = localizeLoopState(snapshot.State)
        local localizedSessionPhase = localizeSessionPhase(snapshot.SessionPhase)
        local localizedMazeStatus = localizeMazeStatus(snapshot.MazeStatus)
        statusLabel.Text = string.format(
            '%s\n区域：%s | 流程：%s | 会话：%s | 迷宫：%s%s\n构建来源：%s | 种子：%s | 直启：%s',
            snapshot.Status or '迷宫已准备就绪。',
            localizedArea,
            localizedLoopState,
            localizedSessionPhase,
            localizedMazeStatus,
            snapshot.IsDirectBoot and ' | 本地直启' or '',
            diagnosticSource,
            diagnosticSeed,
            diagnosticDirect
        )
        statusAreaLabel.Text = string.format('区域：%s', localizedArea)
        statusSummaryLabel.Text =
            string.format('%s | %s', localizedLoopState, localizedSessionPhase)
        objectiveSummaryLabel.Text = string.format('目标：%s', snapshot.Objective or '--')

        objectiveLabel.Text = string.format('目标：%s', snapshot.Objective or '--')

        local inventory = snapshot.Inventory or {}
        mazeInventoryForSwing = inventory
        visibleBackpackItems = inventory.BackpackItems or {}
        heldItemController:applyInventory(inventory)
        updateQuickbarDisplay(inventory)
        inventoryLabel.Text = string.format(
            '背包：共 %d 件 | 战利品 %d | 线索 %d | 工具 %d | 槽位 %d/%d',
            inventory.Count or 0,
            inventory.LootCount or 0,
            inventory.ClueCount or 0,
            inventory.ToolCount or 0,
            inventory.Count or 0,
            inventory.Capacity or 0
        )

        local heldItem = inventory.HeldItem
        if heldItem and type(heldItem.CooldownSeconds) == 'number' then
            heldToolCooldownSeconds = math.max(heldItem.CooldownSeconds, 0)
        else
            heldToolCooldownSeconds = 0.2
        end
        heldStatusLabel.Text = heldItem
                and string.format(
                    '当前手持：%s%s',
                    heldItem.Name,
                    heldItem.Light and ' | 发光中' or ''
                )
            or '当前手持：空手'

        local detailLines = {
            heldItem and string.format(
                '当前手持：%s | %s%s%s',
                heldItem.Name,
                heldItem.ItemCategory or '战利品',
                heldItem.Light and ' | 发光中' or '',
                presentationIconSuffix(heldItem)
            ) or '当前手持：空手',
            '背包内容：',
        }

        if #visibleBackpackItems == 0 then
            table.insert(detailLines, '- 空')
        else
            for itemIndex = 1, math.min(#visibleBackpackItems, 3) do
                local itemEntry = visibleBackpackItems[itemIndex]
                table.insert(
                    detailLines,
                    string.format(
                        '- [%d] %s | %s%s',
                        itemIndex,
                        itemEntry.Name,
                        itemEntry.ItemCategory or '战利品',
                        presentationIconSuffix(itemEntry)
                    )
                )
            end
        end

        table.insert(detailLines, '')
        table.insert(detailLines, '按键：1-3 装备列表物品 | X 收起当前手持')
        inventoryDetailLabel.Text = table.concat(detailLines, '\n')

        local playerState = snapshot.PlayerState or {}
        local movement = snapshot.Movement or {}
        local movementStatus =
            localizeMovementStatus(FormalLocomotion.formatStatus(playerState, movement))
        updateHealthDisplay(playerState.HealthPips or 0, playerState.MaxHealthPips or 0)
        updateStaminaDisplay(
            playerState.CurrentStamina or 0,
            playerState.MaxStamina or 0,
            movementStatus,
            movement.Mode == 'Sprint'
        )
        playerStateLabel.Text = string.format(
            '生命：%d/%d 格\n体力：%d/%d\n状态：%s\n移动：%s | 冲刺：%s',
            playerState.HealthPips or 0,
            playerState.MaxHealthPips or 0,
            math.floor((playerState.CurrentStamina or 0) + 0.5),
            math.floor((playerState.MaxStamina or 0) + 0.5),
            playerState.IsDead and '已死亡' or '存活',
            movement.Mode == 'Sprint' and '冲刺' or '行走',
            movementStatus
        )

        local rosterLines = { '队伍：' }
        for _, rosterEntry in ipairs(snapshot.Roster or {}) do
            local youMarker = rosterEntry.UserId == localPlayer.UserId and ' (你)' or ''
            local stateMarker = rosterEntry.InMaze == false and ' - 已返回' or ' - 仍在迷宫'
            table.insert(
                rosterLines,
                string.format('- %s%s%s', rosterEntry.Name, youMarker, stateMarker)
            )
        end
        rosterLabel.Text = table.concat(rosterLines, '\n')

        local returnedLines = { '返回记录：' }
        local returned = snapshot.ReturnedPlayerSummaries or {}
        if #returned == 0 then
            table.insert(returnedLines, '- 还没有人返回。')
        else
            for _, entry in ipairs(returned) do
                table.insert(
                    returnedLines,
                    string.format(
                        '- %s：%d 件战利品（%s）',
                        entry.Name,
                        entry.LootItemCount or entry.MissionCount or 0,
                        localizeReturnReason(entry.ReturnReason)
                    )
                )
            end
        end
        returnedLabel.Text = table.concat(returnedLines, '\n')
    end)
end

task.spawn(function()
    local ok, resolvedRemotes = pcall(function()
        return RemotesModule.waitForScope(RemotesModule.Scope.Maze, REMOTE_WAIT_TIMEOUT_SECONDS)
    end)

    if not ok then
        showSnapshotTimeout(
            '诊断信息：超时前没有等到 remotes，接下来会继续无限等待。'
        )
        resolvedRemotes = RemotesModule.waitForScope(RemotesModule.Scope.Maze)
    end

    Remotes = resolvedRemotes
    connectMazeRemotes(Remotes)
end)
