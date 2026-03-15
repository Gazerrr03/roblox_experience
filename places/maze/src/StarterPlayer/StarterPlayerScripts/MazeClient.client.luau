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
screenGui.Name = 'MazeHud'
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

local panel = Instance.new('Frame')
panel.Name = 'MazePanel'
panel.AnchorPoint = Vector2.new(0, 0)
panel.Position = UDim2.fromScale(0.03, 0.05)
panel.Size = UDim2.fromOffset(440, 400)
panel.BackgroundColor3 = Theme.Background
panel.BorderSizePixel = 0
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

local eyebrow = makeTextLabel(panel, UDim2.new(1, 0, 0, 20), Theme.Accent, 16, true)
eyebrow.Text = 'SHARED MAZE SESSION'

local title = makeTextLabel(panel, UDim2.new(1, 0, 0, 36), Theme.Text, 28, true)
title.Text = 'Maze Status'

local statusLabel = makeTextLabel(panel, UDim2.new(1, 0, 0, 70), Theme.SubtleText, 18, false)
statusLabel.Text = 'Waiting for maze snapshot...'

local objectiveLabel = makeTextLabel(panel, UDim2.new(1, 0, 0, 64), Theme.Accent, 18, false)
objectiveLabel.Text = 'Objective: --'

local inventoryLabel = makeTextLabel(panel, UDim2.new(1, 0, 0, 48), Theme.Text, 16, false)
inventoryLabel.Text = 'Inventory: --'

local guideLabel = makeTextLabel(panel, UDim2.new(1, 0, 0, 72), Theme.Text, 16, false)
guideLabel.Text =
    'In-world prompts:\n- Expedition Console\n- Camp Return\n- Settlement Pad\n- Loot pickups in marked rooms'

local rosterLabel = makeTextLabel(panel, UDim2.new(1, 0, 0, 90), Theme.SubtleText, 16, false)
rosterLabel.Text = ''

Remotes.PrivateState.OnClientEvent:Connect(function(privateState)
    if type(privateState) ~= 'table' then
        return
    end

    guideLabel.Text = string.format(
        'In-world prompts:\n- Expedition Console\n- Camp Return\n- Settlement Pad\n- Loot pickups in marked rooms\n\nPrivate role: %s',
        privateState.PrivateRole or '--'
    )
end)

Remotes.RunSnapshot.OnClientEvent:Connect(function(snapshot)
    statusLabel.Text = string.format(
        '%s\nArea: %s | State: %s',
        snapshot.Status,
        snapshot.Area or '--',
        snapshot.State or '--'
    )

    objectiveLabel.Text = string.format('Objective: %s', snapshot.Objective or '--')

    local inventory = snapshot.Inventory or { Weight = 0, Count = 0, Value = 0 }
    inventoryLabel.Text = string.format(
        'Inventory: %d items | weight %d | value %d',
        inventory.Count or 0,
        inventory.Weight or 0,
        inventory.Value or 0
    )

    local rosterLines = {}
    for _, rosterEntry in ipairs(snapshot.Roster or {}) do
        local marker = rosterEntry.UserId == localPlayer.UserId and ' (You)' or ''
        local roleText = rosterEntry.PublicRole and string.format(' - %s', rosterEntry.PublicRole)
            or ''
        table.insert(rosterLines, string.format('%s%s%s', rosterEntry.Name, marker, roleText))
    end

    rosterLabel.Text = 'Crew in maze:\n' .. table.concat(rosterLines, '\n')
end)
