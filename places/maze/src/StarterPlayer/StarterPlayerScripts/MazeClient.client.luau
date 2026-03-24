local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService('RunService')
local UserInputService = game:GetService('UserInputService')

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild('PlayerGui')

local Packages = ReplicatedStorage:WaitForChild('Packages')
local Shared = require(Packages:WaitForChild('Shared'))
local UI = require(Packages:WaitForChild('UI'))

local FormalLocomotion = Shared.Runtime.FormalLocomotion
local Theme = UI.Hud.Theme
local REMOTE_WAIT_TIMEOUT_SECONDS = 10
local WAITING_STATUS_TEXT = 'Waiting for maze snapshot...'
local INITIAL_DIAGNOSTIC_TEXT = 'Diagnostic: waiting for bootstrap signal...'
local REMOTE_WAIT_TIMEOUT_TEXT =
    'Still waiting for the server snapshot. Remotes may be late or the maze server bootstrap may have failed.'

Shared.Client.FirstPersonController.start(localPlayer)

local Remotes
local actionInputConnection
local sprintInputEndedConnection
local visibleBackpackItems = {}
local didReceiveInitialSnapshot = false

local function readBootstrapDiagnostic()
    local failed = ReplicatedStorage:GetAttribute('MazeBootstrapFailed')
    local phase = ReplicatedStorage:GetAttribute('MazeBootstrapPhase')
    local err = ReplicatedStorage:GetAttribute('MazeBootstrapError')
    if failed ~= true and phase == nil and err == nil then
        return nil
    end

    local lines = {}
    if phase ~= nil then
        table.insert(lines, string.format('Phase: %s', tostring(phase)))
    end
    if err ~= nil then
        table.insert(lines, string.format('Error: %s', tostring(err)))
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
panel.Size = UDim2.fromOffset(440, 560)
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
statusLabel.Text = WAITING_STATUS_TEXT

local diagnosticLabel = makeTextLabel(panel, UDim2.new(1, 0, 0, 88), Theme.Warning, 16, false)
diagnosticLabel.Text = INITIAL_DIAGNOSTIC_TEXT

local function showSnapshotTimeout(fallbackDiagnosticText)
    local diagnostic = readBootstrapDiagnostic()
    statusLabel.Text = string.format('%s\n%s', WAITING_STATUS_TEXT, REMOTE_WAIT_TIMEOUT_TEXT)
    diagnosticLabel.Text = diagnostic or fallbackDiagnosticText
end

task.delay(REMOTE_WAIT_TIMEOUT_SECONDS, function()
    if didReceiveInitialSnapshot then
        diagnosticLabel.Text = ''
        return
    end

    showSnapshotTimeout('Diagnostic: no maze bootstrap attributes reached the client.')
end)

local objectiveLabel = makeTextLabel(panel, UDim2.new(1, 0, 0, 66), Theme.Accent, 18, false)
objectiveLabel.Text = 'Objective: --'

local promptLabel = makeTextLabel(panel, UDim2.new(1, 0, 0, 66), Theme.Text, 16, false)
promptLabel.Text =
    'In-world prompts:\n- Loot pickups\n- Blue/Gold return markers -> Run Entrance\n- Double Door controls\nKeyboard: Hold LeftShift to sprint'

if RunService:IsStudio() then
    promptLabel.Text ..= '\nStudio debug: H light damage | J heavy damage'
end

local inventoryLabel = makeTextLabel(panel, UDim2.new(1, 0, 0, 44), Theme.Warning, 16, false)
inventoryLabel.Text = 'Inventory: --'

local inventoryDetailLabel = makeTextLabel(panel, UDim2.new(1, 0, 0, 126), Theme.Text, 15, false)
inventoryDetailLabel.Text = ''

local playerStateLabel = makeTextLabel(panel, UDim2.new(1, 0, 0, 86), Theme.Warning, 16, false)
playerStateLabel.Text = 'Health: --\nStamina: --\nState: --\nMovement: --'

local rosterLabel = makeTextLabel(panel, UDim2.new(1, 0, 0, 94), Theme.SubtleText, 16, false)
rosterLabel.Text = ''

local returnedLabel = makeTextLabel(panel, UDim2.new(1, 0, 0, 104), Theme.SubtleText, 16, false)
returnedLabel.Text = ''

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
        visibleBackpackItems = inventory.BackpackItems or {}
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
        local detailLines = {
            heldItem and string.format(
                'Held: %s | %d KG | %d value',
                heldItem.Name,
                heldItem.Weight,
                heldItem.Value
            ) or 'Held: Empty hands',
            'Backpack:',
        }

        if #visibleBackpackItems == 0 then
            table.insert(detailLines, '- Empty')
        else
            for itemIndex = 1, math.min(#visibleBackpackItems, 3) do
                local itemEntry = visibleBackpackItems[itemIndex]
                table.insert(
                    detailLines,
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

        table.insert(detailLines, '')
        table.insert(detailLines, 'Keys: 1-3 equip listed item | X unequip held item')
        inventoryDetailLabel.Text = table.concat(detailLines, '\n')

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
end

task.spawn(function()
    local ok, resolvedRemotes = pcall(function()
        return Shared.Network.Remotes.waitForScope(
            Shared.Network.Remotes.Scope.Maze,
            REMOTE_WAIT_TIMEOUT_SECONDS
        )
    end)

    if not ok then
        showSnapshotTimeout(
            'Diagnostic: remotes did not appear before timeout; waiting indefinitely now.'
        )
        resolvedRemotes = Shared.Network.Remotes.waitForScope(Shared.Network.Remotes.Scope.Maze)
    end

    Remotes = resolvedRemotes
    connectMazeRemotes(Remotes)
end)
