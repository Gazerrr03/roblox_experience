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
panel.Size = UDim2.fromOffset(420, 430)
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

local title = makeTextLabel(panel, UDim2.new(1, 0, 0, 36), Theme.Text, 28, true)
title.Text = 'Maze Status'

local statusLabel = makeTextLabel(panel, UDim2.new(1, 0, 0, 78), Theme.SubtleText, 18, false)
statusLabel.Text = 'Waiting for maze snapshot...'

local objectiveLabel = makeTextLabel(panel, UDim2.new(1, 0, 0, 66), Theme.Accent, 18, false)
objectiveLabel.Text = 'Objective: --'

local promptLabel = makeTextLabel(panel, UDim2.new(1, 0, 0, 66), Theme.Text, 16, false)
promptLabel.Text =
    'In-world prompts:\n- Expedition Console\n- Loot pickups\n- Return To Camp\n- Settlement Pad'

local inventoryLabel = makeTextLabel(panel, UDim2.new(1, 0, 0, 44), Theme.Warning, 16, false)
inventoryLabel.Text = 'Inventory: --'

local rosterLabel = makeTextLabel(panel, UDim2.new(1, 0, 0, 94), Theme.SubtleText, 16, false)
rosterLabel.Text = ''

local returnedLabel = makeTextLabel(panel, UDim2.new(1, 0, 0, 104), Theme.SubtleText, 16, false)
returnedLabel.Text = ''

Remotes.PrivateState.OnClientEvent:Connect(function()
    -- The first maze HUD does not surface per-player private state yet.
end)

Remotes.RunSnapshot.OnClientEvent:Connect(function(snapshot)
    if snapshot.IsLaunched ~= true then
        return
    end

    statusLabel.Text = string.format(
        '%s\nArea: %s | Phase: %s | Maze: %s%s',
        snapshot.Status or 'Maze ready.',
        snapshot.Area or 'Unknown',
        snapshot.State or 'Camp',
        snapshot.MazeStatus or 'active',
        snapshot.IsDirectBoot and ' | Direct Boot' or ''
    )

    objectiveLabel.Text = string.format('Objective: %s', snapshot.Objective or '--')

    local inventory = snapshot.Inventory or {}
    inventoryLabel.Text = string.format(
        'Inventory: %d items | %d weight | %d value',
        inventory.Count or 0,
        inventory.Weight or 0,
        inventory.Value or 0
    )

    local rosterLines = { 'Crew:' }
    for _, rosterEntry in ipairs(snapshot.Roster or {}) do
        local youMarker = rosterEntry.UserId == localPlayer.UserId and ' (You)' or ''
        local stateMarker = rosterEntry.InMaze == false and ' - Returned' or ' - Active'
        table.insert(
            rosterLines,
            string.format('- %s%s%s', rosterEntry.Name, youMarker, stateMarker)
        )
    end
    rosterLabel.Text = table.concat(rosterLines, '\n')

    local returnedLines = { 'Returned summaries:' }
    local returned = snapshot.ReturnedPlayerSummaries or {}
    if #returned == 0 then
        table.insert(returnedLines, '- No one has returned yet.')
    else
        for _, entry in ipairs(returned) do
            table.insert(
                returnedLines,
                string.format(
                    '- %s: %d value (%s)',
                    entry.Name,
                    entry.Value or 0,
                    entry.ReturnReason or 'unknown'
                )
            )
        end
    end
    returnedLabel.Text = table.concat(returnedLines, '\n')
end)
