local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild('PlayerGui')

local Packages = ReplicatedStorage:WaitForChild('Packages')
local Shared = require(Packages:WaitForChild('Shared'))
local UI = require(Packages:WaitForChild('UI'))

local Remotes = Shared.Network.Remotes.ensure()
local Theme = UI.Hud.Theme

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
eyebrow.Text = 'EXPEDITION PROTOTYPE'

local menuTitle = makeTextLabel(menuPanel, UDim2.new(1, 0, 0, 72), Theme.Text, 34, true)
menuTitle.Text = 'Choose how you enter the run'

local menuBody = makeTextLabel(menuPanel, UDim2.new(1, 0, 0, 70), Theme.SubtleText, 18, false)
menuBody.Text =
    'Start from a dedicated title screen, then launch into the current run only when you are ready.'

local singlePlayerButton = Instance.new('TextButton')
singlePlayerButton.Size = UDim2.new(1, 0, 0, 52)
singlePlayerButton.BackgroundColor3 = Theme.Accent
singlePlayerButton.TextColor3 = Theme.Background
singlePlayerButton.Font = Enum.Font.GothamBold
singlePlayerButton.TextSize = 20
singlePlayerButton.Text = 'Single Player'
singlePlayerButton.Parent = menuPanel

local singlePlayerCorner = Instance.new('UICorner')
singlePlayerCorner.CornerRadius = UDim.new(0, 12)
singlePlayerCorner.Parent = singlePlayerButton

local menuStatusLabel =
    makeTextLabel(menuPanel, UDim2.new(1, 0, 0, 48), Theme.SubtleText, 16, false)
menuStatusLabel.Text = 'Preparing launch options...'

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

makePlaceholder('Multiplayer (Soon)')
makePlaceholder('Settings (Soon)')

local panel = Instance.new('Frame')
panel.Name = 'RunPanel'
panel.AnchorPoint = Vector2.new(0, 0)
panel.Position = UDim2.fromScale(0.03, 0.05)
panel.Size = UDim2.fromOffset(380, 300)
panel.BackgroundColor3 = Theme.Background
panel.BorderSizePixel = 0
panel.Visible = false
panel.Parent = screenGui

local panelPadding = Instance.new('UIPadding')
panelPadding.PaddingTop = UDim.new(0, 18)
panelPadding.PaddingLeft = UDim.new(0, 18)
panelPadding.PaddingRight = UDim.new(0, 18)
panelPadding.PaddingBottom = UDim.new(0, 18)
panelPadding.Parent = panel

local list = Instance.new('UIListLayout')
list.Padding = UDim.new(0, 10)
list.Parent = panel

local function makeHudLabel(height, color, textSize, bold)
    local label = Instance.new('TextLabel')
    label.Size = UDim2.new(1, 0, 0, height)
    label.BackgroundTransparency = 1
    label.Font = bold and Enum.Font.GothamBold or Theme.Font
    label.TextColor3 = color
    label.TextSize = textSize
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Top
    label.TextWrapped = true
    return label
end

local title = makeHudLabel(36, Theme.Text, 28, true)
title.Text = 'Run Control'
title.Parent = panel

local statusLabel = makeHudLabel(48, Theme.SubtleText, 18, false)
statusLabel.Text = 'Waiting for run snapshot...'
statusLabel.Parent = panel

local privateRoleLabel = makeHudLabel(40, Theme.Accent, 18, false)
privateRoleLabel.Text = 'Role: --'
privateRoleLabel.Parent = panel

local inventoryLabel = makeHudLabel(42, Theme.Text, 18, false)
inventoryLabel.Text = 'Inventory: --'
inventoryLabel.Parent = panel

local rosterLabel = makeHudLabel(100, Theme.SubtleText, 16, false)
rosterLabel.Text = ''
rosterLabel.Parent = panel

local deployButton = Instance.new('TextButton')
deployButton.Size = UDim2.new(1, 0, 0, 44)
deployButton.BackgroundColor3 = Theme.Accent
deployButton.TextColor3 = Theme.Background
deployButton.Font = Theme.Font
deployButton.TextSize = 18
deployButton.Text = 'Deploy Crew'
deployButton.Parent = panel

local deployCorner = Instance.new('UICorner')
deployCorner.CornerRadius = UDim.new(0, 10)
deployCorner.Parent = deployButton

singlePlayerButton.MouseButton1Click:Connect(function()
    singlePlayerButton.AutoButtonColor = false
    singlePlayerButton.Active = false
    singlePlayerButton.Text = 'Launching...'

    Remotes.RunAction:FireServer({
        Type = 'RequestLaunchRun',
    })
end)

deployButton.MouseButton1Click:Connect(function()
    Remotes.RunAction:FireServer({
        Type = 'RequestStartExpedition',
    })
end)

Remotes.PrivateState.OnClientEvent:Connect(function(privateState)
    if not privateState then
        privateRoleLabel.Text = 'Role: --'
        return
    end

    privateRoleLabel.Text = string.format('Role: %s', privateState.PrivateRole)
end)

Remotes.RunSnapshot.OnClientEvent:Connect(function(snapshot)
    local hasLaunched = snapshot.IsLaunched == true

    menuBackdrop.Visible = not hasLaunched
    panel.Visible = hasLaunched

    if not hasLaunched then
        menuStatusLabel.Text = snapshot.Status
        singlePlayerButton.Active = true
        singlePlayerButton.AutoButtonColor = true
        singlePlayerButton.Text = 'Single Player'
        return
    end

    statusLabel.Text = string.format(
        '%s\nState: %s | Time: %ds | Quota: %d/%d',
        snapshot.Status,
        snapshot.State,
        snapshot.TimeRemaining,
        snapshot.TeamDepositedValue,
        snapshot.Quota
    )

    inventoryLabel.Text = string.format(
        'Inventory: %d items | %d weight | %d value',
        snapshot.Inventory.Count,
        snapshot.Inventory.Weight,
        snapshot.Inventory.Value
    )

    local rosterLines = {}
    for _, rosterEntry in pairs(snapshot.Roster) do
        table.insert(
            rosterLines,
            string.format('%s · %s', rosterEntry.Name, rosterEntry.PublicRole)
        )
    end

    table.sort(rosterLines)
    rosterLabel.Text = 'Visible roster:\n' .. table.concat(rosterLines, '\n')

    local inCamp = snapshot.State == 'Camp'
    deployButton.Visible = true
    deployButton.AutoButtonColor = inCamp
    deployButton.BackgroundColor3 = inCamp and Theme.Accent or Theme.Surface
    deployButton.Text = inCamp and 'Deploy Crew' or 'Crew Already Deployed'
end)
