local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Workspace = game:GetService('Workspace')

local DEFAULT_WORKSPACE_SHELL_NAMES = { 'Baseplate', 'SpawnLocation' }
local EXTRACTION_DELAY_SECONDS = 2

local Packages = ReplicatedStorage:WaitForChild('Packages')
local Shared = Packages:WaitForChild('Shared')
local Gameplay = require(Packages:WaitForChild('Gameplay'))

local SessionConfig = require(Shared:WaitForChild('Config'):WaitForChild('SessionConfig'))
local InventoryService = require(Shared:WaitForChild('Runtime'):WaitForChild('InventoryService'))
local MonsterService = require(Shared:WaitForChild('Runtime'):WaitForChild('MonsterService'))

local MazeWorldBuilder = require(script.Parent.MazeWorldBuilder)

local MazeSessionService = {}
MazeSessionService.__index = MazeSessionService

local function clearDefaultWorkspaceShell()
    for _, instanceName in ipairs(DEFAULT_WORKSPACE_SHELL_NAMES) do
        local instance = Workspace:FindFirstChild(instanceName)
        if instance then
            instance:Destroy()
        end
    end
end

local function bindCharacterTeleport(self, player)
    player.CharacterAdded:Connect(function(character)
        task.wait()
        if not self.World or not character.Parent then
            return
        end

        local targetCFrame = self.World.SpawnCFrame
        if not self.RunTracker:isPlayerActive(player.UserId) then
            targetCFrame = self.World.ReturnHoldCFrame
        end

        character:PivotTo(targetCFrame)
    end)
end

function MazeSessionService.new()
    local self = setmetatable({}, MazeSessionService)

    self.SessionData = {
        Seed = SessionConfig.DefaultSeed,
        InventoryCapacity = SessionConfig.InventoryCapacity,
    }
    self.Status = 'Direct boot: use the expedition console to begin the maze run.'
    self.World = nil
    self.IsLaunched = false
    self.RunTracker = Gameplay.Session.MazeRunTracker.new()
    self.InventoryService = InventoryService.new(self.SessionData.InventoryCapacity)
    self.MonsterService = MonsterService.new(Gameplay.Config.Monsters[1], function()
        return self.RunTracker:getState() == 'Expedition'
    end, function(player)
        return self.RunTracker:isPlayerActive(player.UserId)
    end)

    return self
end

function MazeSessionService:_loadSessionDataFromJoin()
    local players = Players:GetPlayers()
    if #players == 0 then
        return
    end

    local joinData = players[1]:GetJoinData()
    local teleportData = joinData and joinData.TeleportData
    local incoming = teleportData and teleportData.SessionConfig

    if type(incoming) ~= 'table' then
        return
    end

    if type(incoming.Seed) == 'number' then
        self.SessionData.Seed = incoming.Seed
    end

    if type(incoming.InventoryCapacity) == 'number' then
        self.SessionData.InventoryCapacity = incoming.InventoryCapacity
    end

    self.InventoryService = InventoryService.new(self.SessionData.InventoryCapacity)
end

function MazeSessionService:_addPlayerState(player)
    local added = self.RunTracker:addPlayer({
        UserId = player.UserId,
        Name = player.DisplayName,
    })

    if not added then
        return
    end

    self.InventoryService:addPlayer(player)
end

function MazeSessionService:_removePlayerState(player)
    self.RunTracker:removePlayer(player.UserId)
    self.InventoryService:removePlayer(player)
end

function MazeSessionService:_setStatus(status)
    self.Status = status
    print(string.format('[Maze] %s', status))
end

function MazeSessionService:_rebuildWorld()
    clearDefaultWorkspaceShell()
    self.World = MazeWorldBuilder.build(self.SessionData.Seed, SessionConfig.ProcGen)
    self:_bindWorldInteractions()
end

function MazeSessionService:_bindWorldInteractions()
    self.World.DeployPrompt.Triggered:Connect(function(player)
        self:_deployCrew(player)
    end)

    self.World.ReturnPrompt.Triggered:Connect(function(player)
        self:_returnPlayer(player)
    end)

    self.World.ExtractionPrompt.Triggered:Connect(function(player)
        self:_startExtraction(player)
    end)

    for roomId, lootEntry in pairs(self.World.LootPrompts) do
        lootEntry.Prompt.Triggered:Connect(function(player)
            self:_pickupLoot(player, roomId)
        end)
    end
end

function MazeSessionService:_buildSummaryFor(player, returnReason, wasSettled)
    local inventorySummary = self.InventoryService:getSummary(player)
    self.InventoryService:deposit(player)

    return {
        UserId = player.UserId,
        Name = player.DisplayName,
        ReturnReason = returnReason,
        Value = inventorySummary.Value,
        ItemCount = inventorySummary.Count,
        Weight = inventorySummary.Weight,
        WasExtracted = returnReason == 'extracted' or returnReason == 'settled',
        WasSettled = wasSettled == true,
    }
end

function MazeSessionService:_deployCrew(player)
    local started, reason = self.RunTracker:beginExpedition()
    if not started then
        if reason == 'InvalidState' then
            self:_setStatus(
                string.format(
                    '%s checked the expedition console, but the maze run is already active.',
                    player.DisplayName
                )
            )
        end
        return
    end

    self.MonsterService:spawn(self.World.PatrolPoints)
    self:_setStatus(string.format('%s deployed the crew into the maze.', player.DisplayName))
end

function MazeSessionService:_pickupLoot(player, roomId)
    if self.RunTracker:getState() ~= 'Expedition' then
        self:_setStatus('Loot can only be collected during the expedition phase.')
        return
    end

    if not self.RunTracker:isPlayerActive(player.UserId) then
        self:_setStatus(
            string.format(
                '%s has already returned and cannot collect more loot.',
                player.DisplayName
            )
        )
        return
    end

    local lootEntry = self.World.LootPrompts[roomId]
    if not lootEntry or lootEntry.Collected then
        return
    end

    local success, reason = self.InventoryService:pickup(player, lootEntry.ItemDef)
    if not success then
        self:_setStatus(
            string.format(
                '%s could not carry %s (%s).',
                player.DisplayName,
                lootEntry.ItemDef.Name,
                tostring(reason)
            )
        )
        return
    end

    lootEntry.Collected = true
    local promptPart = lootEntry.Prompt.Parent
    if promptPart then
        promptPart:Destroy()
    end

    local inventorySummary = self.InventoryService:getSummary(player)
    self:_setStatus(
        string.format(
            '%s collected %s. Inventory value now %d.',
            player.DisplayName,
            lootEntry.ItemDef.Name,
            inventorySummary.Value
        )
    )
end

function MazeSessionService:_returnPlayer(player)
    local currentState = self.RunTracker:getState()
    if currentState == 'Camp' then
        self:_setStatus('Return is available after the expedition begins.')
        return
    end

    if currentState == 'Settlement' then
        self:_setStatus('Settlement is already complete.')
        return
    end

    local recorded, reason =
        self.RunTracker:recordReturn(self:_buildSummaryFor(player, 'early_return', false))
    if not recorded then
        if reason == 'MissingActivePlayer' then
            self:_setStatus(string.format('%s already returned to camp.', player.DisplayName))
        end
        return
    end

    local character = player.Character
    if character and character.Parent then
        character:PivotTo(self.World.ReturnHoldCFrame)
    end

    local summaries = self.RunTracker:getReturnedSummaries()
    local summary = summaries[#summaries]
    self:_setStatus(
        string.format('%s returned early with %d value.', player.DisplayName, summary.Value)
    )
end

function MazeSessionService:_completeSettlement(player)
    if self.RunTracker:getState() ~= 'Extraction' then
        return
    end

    local summaries = {}
    for _, currentPlayer in ipairs(Players:GetPlayers()) do
        if self.RunTracker:isPlayerActive(currentPlayer.UserId) then
            table.insert(summaries, self:_buildSummaryFor(currentPlayer, 'settled', true))
        end
    end

    local completed, reason = self.RunTracker:completeSettlement(summaries)
    if not completed then
        self:_setStatus(string.format('Settlement failed: %s', tostring(reason)))
        return
    end

    self.MonsterService:destroy()

    for _, currentPlayer in ipairs(Players:GetPlayers()) do
        if currentPlayer.Character and currentPlayer.Character.Parent then
            currentPlayer.Character:PivotTo(self.World.ReturnHoldCFrame)
        end
    end

    self:_setStatus(
        string.format(
            '%s completed settlement. Maze results are ready for camp handoff.',
            player.DisplayName
        )
    )
end

function MazeSessionService:_startExtraction(player)
    if self.RunTracker:getState() ~= 'Expedition' then
        self:_setStatus('The settlement pad is only available during the expedition phase.')
        return
    end

    if not self.RunTracker:isPlayerActive(player.UserId) then
        self:_setStatus(string.format('%s already returned to camp.', player.DisplayName))
        return
    end

    local started, reason = self.RunTracker:beginExtraction()
    if not started then
        self:_setStatus(string.format('Extraction could not start: %s', tostring(reason)))
        return
    end

    self:_setStatus(
        string.format('%s activated the settlement pad. Hold tight.', player.DisplayName)
    )

    task.delay(EXTRACTION_DELAY_SECONDS, function()
        self:_completeSettlement(player)
    end)
end

function MazeSessionService:_launchMaze()
    if self.IsLaunched then
        return
    end

    self.IsLaunched = true
    Players.CharacterAutoLoads = true

    self:_rebuildWorld()

    for _, player in ipairs(Players:GetPlayers()) do
        player:LoadCharacter()
    end
end

function MazeSessionService:start()
    self:_loadSessionDataFromJoin()
    Players.CharacterAutoLoads = false

    for _, player in ipairs(Players:GetPlayers()) do
        bindCharacterTeleport(self, player)
        self:_addPlayerState(player)

        if player.Character then
            player.Character:Destroy()
        end
    end

    Players.PlayerAdded:Connect(function(player)
        bindCharacterTeleport(self, player)
        self:_addPlayerState(player)

        if self.IsLaunched then
            player:LoadCharacter()
            self:_setStatus(string.format('%s joined the shared maze session.', player.DisplayName))
        end
    end)

    Players.PlayerRemoving:Connect(function(player)
        self:_removePlayerState(player)
    end)

    self:_launchMaze()
end

return MazeSessionService
