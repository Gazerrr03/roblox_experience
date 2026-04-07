local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService('RunService')
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
local SAND_BOOK_LABEL = 'Book of Sand'

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
    if not isRunLaunched or isMouseFree then
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
eyebrow.Text = 'TEMPLE STAGING PROTOTYPE'

local menuTitle = makeTextLabel(menuPanel, UDim2.new(1, 0, 0, 72), Theme.Text, 34, true)
menuTitle.Text = string.format('Enter the %s', TEMPLE_LABEL)

local menuBody = makeTextLabel(menuPanel, UDim2.new(1, 0, 0, 78), Theme.SubtleText, 18, false)
menuBody.Text =
    'Start inside the temple hall, meet up with the crew, and open the main gate when you are ready to step into the wilderness and the shared maze gate.'

local singlePlayerButton = Instance.new('TextButton')
singlePlayerButton.Size = UDim2.new(1, 0, 0, 52)
singlePlayerButton.BackgroundColor3 = Theme.Accent
singlePlayerButton.TextColor3 = Theme.Background
singlePlayerButton.Font = Enum.Font.GothamBold
singlePlayerButton.TextSize = 20
singlePlayerButton.Text = string.format('Enter %s', TEMPLE_LABEL)
singlePlayerButton.Parent = menuPanel

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
    'In-world prompts:\n- %s Shop (Soon)\n- Loadout Bench (Soon)\n- %s Gate / Shared Maze Gate\nKeyboard: Hold LeftShift to sprint, tap C to toggle %s Status, %s to free mouse, 1-3 to equip, X to stow',
    TEMPLE_LABEL,
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

local function syncCampPanelVisibility()
    panel.Visible = isRunLaunched and isCampPanelVisible
end

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

singlePlayerButton.MouseButton1Click:Connect(function()
    singlePlayerButton.AutoButtonColor = false
    singlePlayerButton.Active = false
    singlePlayerButton.Text = string.format('Entering %s...', TEMPLE_LABEL)

    Remotes.RunAction:FireServer({
        Type = 'RequestLaunchRun',
    })
end)

Remotes.RunPrivateState.OnClientEvent:Connect(function()
    -- Private role data is intentionally unused in the camp staging run.
end)

Remotes.RunState.OnClientEvent:Connect(function(snapshot)
    local hasLaunched = snapshot.IsLaunched == true
    isRunLaunched = hasLaunched
    if not hasLaunched then
        isCampPanelVisible = true
    end

    menuBackdrop.Visible = not hasLaunched
    syncCampPanelVisibility()

    if not hasLaunched then
        syncMouseMode()
        canRequestMazeEntry = false
        visibleBackpackItems = {}
        heldItemController:applyInventory(nil)
        menuStatusLabel.Text =
            string.format('%s\nMaze Entry: %s', snapshot.Status, buildMazeEntryText(snapshot))
        singlePlayerButton.Active = true
        singlePlayerButton.AutoButtonColor = true
        singlePlayerButton.Text = string.format('Enter %s', TEMPLE_LABEL)
        inventoryLabel.Text = 'Inventory: --'
        inventoryDetailLabel.Text = ''
        playerStateLabel.Text = 'Health: --\nStamina: --\nState: --\nMovement: --'
        return
    end

    syncMouseMode()
    canRequestMazeEntry = snapshot.GateOpen == true

    statusLabel.Text = string.format(
        '%s\nArea: %s | Gate: %s | Maze: %s\nEntry: %s',
        snapshot.Status,
        snapshot.Area,
        snapshot.GateOpen and 'Open' or 'Closed',
        snapshot.MazeStatus or 'idle',
        buildMazeEntryText(snapshot)
    )

    objectiveLabel.Text = string.format('%s Objective: %s', SAND_BOOK_LABEL, snapshot.Objective)

    local inventory = snapshot.Inventory or {}
    visibleBackpackItems = inventory.BackpackItems or {}
    heldItemController:applyInventory(inventory)
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
        local marker = rosterEntry.UserId == localPlayer.UserId and ' (You)' or ''
        table.insert(rosterLines, string.format('%s%s', rosterEntry.Name, marker))
    end

    rosterLabel.Text = string.format('%s roster:\n', TEMPLE_LABEL) .. table.concat(rosterLines, '\n')

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
