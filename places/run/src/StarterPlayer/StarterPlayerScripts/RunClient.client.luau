local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService('RunService')
local UserInputService = game:GetService('UserInputService')

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild('PlayerGui')

local Packages = ReplicatedStorage:WaitForChild('Packages')
local Shared = require(Packages:WaitForChild('Shared'))
local UI = require(Packages:WaitForChild('UI'))

local Remotes = Shared.Network.Remotes.ensure()
local FormalLocomotion = Shared.Runtime.FormalLocomotion
local Theme = UI.Hud.Theme

local disconnectFirstPersonLock
local ensureFirstPersonLock
local canRequestMazeEntry = false
local isRunLaunched = false
local isCampPanelVisible = true
local actionInputConnection
local sprintInputEndedConnection
local isMenuMouseUnlockBound = false
local MENU_MOUSE_UNLOCK_STEP = 'RunMenuMouseUnlock'
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

local function buildMazeEntryText(snapshot)
    local mode = snapshot.MazeEntryMode or 'Blocked'
    local reasonCode = snapshot.MazeEntryReasonCode or 'Unknown'
    local reason = snapshot.MazeEntryReason
    if type(reason) == 'string' and reason ~= '' then
        return string.format('%s [%s] (%s)', mode, reasonCode, reason)
    end

    return string.format('%s [%s]', mode, reasonCode)
end

local menuBackdrop = Instance.new('Frame')
menuBackdrop.Name = 'StartMenu'
menuBackdrop.Size = UDim2.fromScale(1, 1)
menuBackdrop.BackgroundColor3 = Theme.Background
menuBackdrop.Parent = screenGui

local menuPanel = Instance.new('Frame')
menuPanel.Name = 'Panel'
menuPanel.AnchorPoint = Vector2.new(0.5, 0.5)
menuPanel.Position = UDim2.fromScale(0.5, 0.5)
menuPanel.Size = UDim2.fromOffset(520, 360)
menuPanel.BackgroundColor3 = Theme.Surface
menuPanel.BorderSizePixel = 0
menuPanel.Parent = menuBackdrop

local menuCorner = Instance.new('UICorner')
menuCorner.CornerRadius = UDim.new(0, 18)
menuCorner.Parent = menuPanel

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
eyebrow.Text = 'CAMP STAGING PROTOTYPE'

local menuTitle = makeTextLabel(menuPanel, UDim2.new(1, 0, 0, 72), Theme.Text, 34, true)
menuTitle.Text = 'Enter the expedition camp'

local menuBody = makeTextLabel(menuPanel, UDim2.new(1, 0, 0, 78), Theme.SubtleText, 18, false)
menuBody.Text =
    'Start inside the camp house, meet up with the crew, and open the main gate when you are ready to step into the wilderness and the shared maze gate.'

local singlePlayerButton = Instance.new('TextButton')
singlePlayerButton.Size = UDim2.new(1, 0, 0, 52)
singlePlayerButton.BackgroundColor3 = Theme.Accent
singlePlayerButton.TextColor3 = Theme.Background
singlePlayerButton.Font = Enum.Font.GothamBold
singlePlayerButton.TextSize = 20
singlePlayerButton.Text = 'Enter Camp'
singlePlayerButton.Parent = menuPanel

local singlePlayerCorner = Instance.new('UICorner')
singlePlayerCorner.CornerRadius = UDim.new(0, 12)
singlePlayerCorner.Parent = singlePlayerButton

local menuStatusLabel =
    makeTextLabel(menuPanel, UDim2.new(1, 0, 0, 52), Theme.SubtleText, 16, false)
menuStatusLabel.Text = 'Preparing camp access...'

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

makePlaceholder('Shop Terminal (Soon)')
makePlaceholder('Shared Maze Gate')

local panel = Instance.new('Frame')
panel.Name = 'CampPanel'
panel.AnchorPoint = Vector2.new(0, 0)
panel.Position = UDim2.fromScale(0.03, 0.05)
panel.Size = UDim2.fromOffset(440, 500)
panel.BackgroundColor3 = Theme.Background
panel.BorderSizePixel = 0
panel.Visible = false
panel.Parent = screenGui

local panelCorner = Instance.new('UICorner')
panelCorner.CornerRadius = UDim.new(0, 16)
panelCorner.Parent = panel

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
title.Text = 'Camp Status'

local statusLabel = makeTextLabel(panel, UDim2.new(1, 0, 0, 70), Theme.SubtleText, 18, false)
statusLabel.Text = 'Waiting for camp snapshot...'

local objectiveLabel = makeTextLabel(panel, UDim2.new(1, 0, 0, 64), Theme.Accent, 18, false)
objectiveLabel.Text = 'Objective: --'

local guideLabel = makeTextLabel(panel, UDim2.new(1, 0, 0, 60), Theme.Text, 16, false)
guideLabel.Text =
    'In-world prompts:\n- Shop Terminal (Soon)\n- Loadout Bench (Soon)\n- Camp Gate / Shared Maze Gate\nKeyboard: Hold LeftShift to sprint, tap C to toggle Camp Status'

local playerStateLabel = makeTextLabel(panel, UDim2.new(1, 0, 0, 86), Theme.Warning, 16, false)
playerStateLabel.Text = 'Health: --\nStamina: --\nState: --\nMovement: --'

local rosterLabel = makeTextLabel(panel, UDim2.new(1, 0, 0, 90), Theme.SubtleText, 16, false)
rosterLabel.Text = ''

local mazeLabel = makeTextLabel(panel, UDim2.new(1, 0, 0, 96), Theme.SubtleText, 16, false)
mazeLabel.Text = ''

local function syncCampPanelVisibility()
    panel.Visible = isRunLaunched and isCampPanelVisible
end

releaseFirstPersonLockForMenu()
bindMenuMouseUnlock()
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

    if input.KeyCode == Enum.KeyCode.C then
        if isRunLaunched then
            isCampPanelVisible = not isCampPanelVisible
            syncCampPanelVisibility()
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

singlePlayerButton.MouseButton1Click:Connect(function()
    singlePlayerButton.AutoButtonColor = false
    singlePlayerButton.Active = false
    singlePlayerButton.Text = 'Entering Camp...'

    Remotes.RunAction:FireServer({
        Type = 'RequestLaunchRun',
    })
end)

Remotes.PrivateState.OnClientEvent:Connect(function()
    -- Private role data is intentionally unused in the camp staging run.
end)

Remotes.RunSnapshot.OnClientEvent:Connect(function(snapshot)
    local hasLaunched = snapshot.IsLaunched == true
    isRunLaunched = hasLaunched
    if not hasLaunched then
        isCampPanelVisible = true
    end

    menuBackdrop.Visible = not hasLaunched
    syncCampPanelVisibility()

    if not hasLaunched then
        releaseFirstPersonLockForMenu()
        bindMenuMouseUnlock()
        canRequestMazeEntry = false
        menuStatusLabel.Text =
            string.format('%s\nMaze Entry: %s', snapshot.Status, buildMazeEntryText(snapshot))
        singlePlayerButton.Active = true
        singlePlayerButton.AutoButtonColor = true
        singlePlayerButton.Text = 'Single Player'
        playerStateLabel.Text = 'Health: --\nStamina: --\nState: --\nMovement: --'
        return
    end

    unbindMenuMouseUnlock()
    ensureFirstPersonLock()
    canRequestMazeEntry = snapshot.GateOpen == true

    statusLabel.Text = string.format(
        '%s\nArea: %s | Gate: %s | Maze: %s\nEntry: %s',
        snapshot.Status,
        snapshot.Area,
        snapshot.GateOpen and 'Open' or 'Closed',
        snapshot.MazeStatus or 'idle',
        buildMazeEntryText(snapshot)
    )

    objectiveLabel.Text = string.format('Objective: %s', snapshot.Objective)

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
        local marker = rosterEntry.UserId == localPlayer.UserId and ' (You)' or ''
        table.insert(rosterLines, string.format('%s%s', rosterEntry.Name, marker))
    end

    rosterLabel.Text = 'Camp roster:\n' .. table.concat(rosterLines, '\n')

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
