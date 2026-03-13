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
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local panel = Instance.new('Frame')
panel.Name = 'Panel'
panel.AnchorPoint = Vector2.new(0, 0)
panel.Position = UDim2.fromScale(0.03, 0.05)
panel.Size = UDim2.fromOffset(380, 300)
panel.BackgroundColor3 = Theme.Background
panel.BorderSizePixel = 0
panel.Parent = screenGui

local padding = Instance.new('UIPadding')
padding.PaddingTop = UDim.new(0, 18)
padding.PaddingLeft = UDim.new(0, 18)
padding.PaddingRight = UDim.new(0, 18)
padding.PaddingBottom = UDim.new(0, 18)
padding.Parent = panel

local list = Instance.new('UIListLayout')
list.Padding = UDim.new(0, 10)
list.Parent = panel

local function makeLabel(height, color, textSize)
    local label = Instance.new('TextLabel')
    label.Size = UDim2.new(1, 0, 0, height)
    label.BackgroundTransparency = 1
    label.Font = Theme.Font
    label.TextColor3 = color
    label.TextSize = textSize
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Top
    label.TextWrapped = true
    return label
end

local title = makeLabel(36, Theme.Text, 28)
title.Text = 'Run Control'
title.Parent = panel

local statusLabel = makeLabel(48, Theme.SubtleText, 18)
statusLabel.Text = 'Waiting for run snapshot...'
statusLabel.Parent = panel

local privateRoleLabel = makeLabel(40, Theme.Accent, 18)
privateRoleLabel.Text = 'Role: --'
privateRoleLabel.Parent = panel

local inventoryLabel = makeLabel(42, Theme.Text, 18)
inventoryLabel.Text = 'Inventory: --'
inventoryLabel.Parent = panel

local rosterLabel = makeLabel(100, Theme.SubtleText, 16)
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

deployButton.MouseButton1Click:Connect(function()
    Remotes.RunAction:FireServer({
        Type = 'RequestStartExpedition',
    })
end)

Remotes.PrivateState.OnClientEvent:Connect(function(privateState)
    if not privateState then
        return
    end

    privateRoleLabel.Text = string.format('Role: %s', privateState.PrivateRole)
end)

Remotes.RunSnapshot.OnClientEvent:Connect(function(snapshot)
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
        table.insert(rosterLines, string.format('%s · %s', rosterEntry.Name, rosterEntry.PublicRole))
    end

    table.sort(rosterLines)
    rosterLabel.Text = 'Visible roster:\n' .. table.concat(rosterLines, '\n')

    local inCamp = snapshot.State == 'Camp'
    deployButton.Visible = true
    deployButton.AutoButtonColor = inCamp
    deployButton.BackgroundColor3 = inCamp and Theme.Accent or Theme.Surface
    deployButton.Text = inCamp and 'Deploy Crew' or 'Crew Already Deployed'
end)
