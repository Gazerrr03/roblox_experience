local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService('RunService')
local UserInputService = game:GetService('UserInputService')

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild('PlayerGui')

local Packages = ReplicatedStorage:WaitForChild('Packages')
local Gameplay = require(Packages:WaitForChild('Gameplay'))
local Shared = require(Packages:WaitForChild('Shared'))
local UI = require(Packages:WaitForChild('UI'))
local ItemPresentation = Gameplay.Config.ItemPresentation

local FormalLocomotion = Shared.Runtime.FormalLocomotion
local HeldToolVisual = Shared.Client.HeldToolVisual
local heldItemController = Shared.Client.HeldItemController.new(localPlayer)
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
local lastToolUseRequestAt = -math.huge
local heldToolCooldownSeconds = 0.2
local mazeInventoryForSwing: { [string]: any }? = nil

local function presentationIconSuffix(itemEntry: { [string]: any }?)
    if type(itemEntry) ~= 'table' then
        return ''
    end
    local uri = ItemPresentation.formatIconContentId(itemEntry.IconAssetId)
    if uri ~= '' then
        return ' | 2D icon'
    end
    return ''
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

local promptLabel = makeTextLabel(panel, UDim2.new(1, 0, 0, 86), Theme.Text, 16, false)
-- === 修改：加上了按 F 键使用道具的提示 ===
promptLabel.Text =
    'In-world prompts:\n- Loot pickups\n- Blue/Gold return markers -> Run Entrance\n- Double Door controls\nKeyboard: Hold LeftShift to sprint\nKeyboard: Press F to use held tool'

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
        local diagnosticDirect = snapshot.WorldBuildIsDirectBoot == true and 'true' or 'false'
        local diagnosticSource = snapshot.WorldBuildSource or 'Pending'
        statusLabel.Text = string.format(
            '%s\nArea: %s | Expedition: %s | Session: %s | Maze: %s%s\nBuild: %s | Seed: %s | Direct: %s',
            snapshot.Status or 'Maze ready.',
            snapshot.Area or 'Unknown',
            snapshot.State or 'Camp',
            snapshot.SessionPhase or 'MazeActive',
            snapshot.MazeStatus or 'active',
            snapshot.IsDirectBoot and ' | Direct Boot' or '',
            diagnosticSource,
            diagnosticSeed,
            diagnosticDirect
        )

        objectiveLabel.Text = string.format('Objective: %s', snapshot.Objective or '--')

        local inventory = snapshot.Inventory or {}
        mazeInventoryForSwing = inventory
        visibleBackpackItems = inventory.BackpackItems or {}
        heldItemController:applyInventory(inventory)
        inventoryLabel.Text = string.format(
            'Inventory: %d total | %d loot | %d clue | %d tool | %d/%d slots',
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

        local detailLines = {
            heldItem and string.format(
                'Held: %s | %s%s%s',
                heldItem.Name,
                heldItem.ItemCategory or 'Loot',
                heldItem.Light and ' | Glow active' or '',
                presentationIconSuffix(heldItem)
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
                        '- [%d] %s | %s%s',
                        itemIndex,
                        itemEntry.Name,
                        itemEntry.ItemCategory or 'Loot',
                        presentationIconSuffix(itemEntry)
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
                        '- %s: %d loot item(s) (%s)',
                        entry.Name,
                        entry.LootItemCount or entry.MissionCount or 0,
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
