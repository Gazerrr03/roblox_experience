local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild('PlayerGui')

local Packages = ReplicatedStorage:WaitForChild('Packages')
local Shared = require(Packages:WaitForChild('Shared'))
local UI = require(Packages:WaitForChild('UI'))

local Theme = UI.Hud.Theme
local Remotes = Shared.Network.Remotes.ensure()

Shared.Client.FirstPersonController.start(localPlayer)

local screenGui = Instance.new('ScreenGui')
screenGui.Name = 'LobbyHud'
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local frame = Instance.new('Frame')
frame.Name = 'Panel'
frame.AnchorPoint = Vector2.new(0, 0.5)
frame.Position = UDim2.fromScale(0.03, 0.5)
frame.Size = UDim2.fromOffset(360, 340)
frame.BackgroundColor3 = Theme.Background
frame.BorderSizePixel = 0
frame.Parent = screenGui

local padding = Instance.new('UIPadding')
padding.PaddingLeft = UDim.new(0, 20)
padding.PaddingRight = UDim.new(0, 20)
padding.PaddingTop = UDim.new(0, 18)
padding.PaddingBottom = UDim.new(0, 18)
padding.Parent = frame

local list = Instance.new('UIListLayout')
list.Padding = UDim.new(0, 12)
list.Parent = frame

local function makeLabel(size, color)
    local label = Instance.new('TextLabel')
    label.BackgroundTransparency = 1
    label.Size = size
    label.Font = Theme.Font
    label.TextColor3 = color
    label.TextWrapped = true
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Top
    return label
end

local title = makeLabel(UDim2.new(1, 0, 0, 42), Theme.Text)
title.TextSize = 28
title.Text = 'Crew Lobby'
title.Parent = frame

local statusLabel = makeLabel(UDim2.new(1, 0, 0, 44), Theme.SubtleText)
statusLabel.TextSize = 18
statusLabel.Text = 'Waiting for lobby state...'
statusLabel.Parent = frame

local rosterLabel = makeLabel(UDim2.new(1, 0, 0, 150), Theme.Text)
rosterLabel.TextSize = 18
rosterLabel.Text = ''
rosterLabel.Parent = frame

local readyButton = Instance.new('TextButton')
readyButton.Size = UDim2.new(1, 0, 0, 44)
readyButton.BackgroundColor3 = Theme.Accent
readyButton.TextColor3 = Theme.Background
readyButton.Font = Theme.Font
readyButton.TextSize = 18
readyButton.Text = 'Toggle Ready'
readyButton.Parent = frame

local startButton = Instance.new('TextButton')
startButton.Size = UDim2.new(1, 0, 0, 44)
startButton.BackgroundColor3 = Theme.Warning
startButton.TextColor3 = Theme.Background
startButton.Font = Theme.Font
startButton.TextSize = 18
startButton.Text = 'Start Run'
startButton.Parent = frame

local hintLabel = makeLabel(UDim2.new(1, 0, 0, 60), Theme.SubtleText)
hintLabel.TextSize = 16
hintLabel.Text =
    'Fill SessionConfig.PlaceIds.Run or SessionPlaceIdRun before teleporting from the lobby.'
hintLabel.Parent = frame

local localReady = false

readyButton.MouseButton1Click:Connect(function()
    localReady = not localReady
    Remotes.LobbyAction:FireServer({
        Type = 'ToggleReady',
        Ready = localReady,
    })
end)

startButton.MouseButton1Click:Connect(function()
    Remotes.LobbyAction:FireServer({
        Type = 'StartRun',
    })
end)

Remotes.LobbyState.OnClientEvent:Connect(function(snapshot)
    local lines = {}

    statusLabel.Text = string.format('%s\nSeed: %s', snapshot.Status, tostring(snapshot.Seed))

    for _, playerEntry in ipairs(snapshot.Players) do
        local readyGlyph = playerEntry.Ready and '[READY]' or '[WAIT]'
        table.insert(lines, string.format('%s %s', readyGlyph, playerEntry.Name))

        if playerEntry.UserId == localPlayer.UserId then
            localReady = playerEntry.Ready
        end
    end

    rosterLabel.Text = table.concat(lines, '\n')
    readyButton.Text = localReady and 'Unready' or 'Ready Up'
    startButton.AutoButtonColor = snapshot.CanStart
    startButton.BackgroundColor3 = snapshot.CanStart and Theme.Warning or Theme.Surface
end)
