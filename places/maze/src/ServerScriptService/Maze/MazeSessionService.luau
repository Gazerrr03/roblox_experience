local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local TeleportService = game:GetService('TeleportService')

local Packages = ReplicatedStorage:WaitForChild('Packages')
local Shared = require(Packages:WaitForChild('Shared'))
local Gameplay = require(Packages:WaitForChild('Gameplay'))

local SessionConfig = Shared.Config.SessionConfig
local RunState = Shared.Enums.RunState
local Remotes = Shared.Network.Remotes.ensure()
local CampMazeSessionContract = Shared.Session.CampMazeSessionContract
local InventoryService = Shared.Runtime.InventoryService
local MonsterService = Shared.Runtime.MonsterService
local RoleService = Shared.Runtime.RoleService

local MazeWorldBuilder = require(script.Parent.MazeWorldBuilder)

local MazeSessionService = {}
MazeSessionService.__index = MazeSessionService

local EXTRACTION_DELAY_SECONDS = 2

local function bindCharacterTeleport(self, player)
    player.CharacterAdded:Connect(function(character)
        task.wait()
        if self.World and character.Parent then
            character:PivotTo(self.World.SpawnCFrame)
        end
    end)
end

function MazeSessionService.new()
    local self = setmetatable({}, MazeSessionService)

    self.Remotes = Remotes
    self.SessionData = {
        Seed = SessionConfig.DefaultSeed,
        Quota = SessionConfig.DefaultQuota,
        RunDurationSeconds = SessionConfig.DefaultRunDurationSeconds,
        InventoryCapacity = SessionConfig.InventoryCapacity,
    }
    self.CampSession = CampMazeSessionContract.newCampSession({
        MazeAccessCode = 'local-debug-maze',
        MazeStatus = CampMazeSessionContract.MazeStatus.Active,
    })
    self.Status = 'Direct boot: use the expedition console to begin the maze run.'
    self.IsDirectBoot = true
    self.IsLaunched = false
    self.IsCompleted = false
    self.World = nil
    self.SnapshotThread = nil
    self.InventoryService = InventoryService.new(self.SessionData.InventoryCapacity)
    self.RoleService = RoleService.new(Gameplay.Config.Roles)
    self.StateMachine = Gameplay.Session.SessionStateMachine.new(RunState.Camp)
    self.MonsterService = MonsterService.new(Gameplay.Config.Monsters[1], function()
        return self.StateMachine.Current == RunState.Expedition
    end)

    return self
end

function MazeSessionService:_readTeleportData(player)
    local joinData = player:GetJoinData()
    return joinData and joinData.TeleportData
end

function MazeSessionService:_loadSessionDataFromJoin()
    local players = Players:GetPlayers()
    if #players == 0 then
        return
    end

    local teleportData = self:_readTeleportData(players[1])
    local incoming = teleportData and teleportData.SessionConfig
    if type(incoming) == 'table' then
        if type(incoming.Seed) == 'number' then
            self.SessionData.Seed = incoming.Seed
        end
        if type(incoming.Quota) == 'number' then
            self.SessionData.Quota = incoming.Quota
        end
        if type(incoming.RunDurationSeconds) == 'number' then
            self.SessionData.RunDurationSeconds = incoming.RunDurationSeconds
        end
        if type(incoming.InventoryCapacity) == 'number' then
            self.SessionData.InventoryCapacity = incoming.InventoryCapacity
        end
    end

    if type(teleportData) == 'table' and type(teleportData.CampSession) == 'table' then
        self.CampSession = CampMazeSessionContract.normalizeCampSession(teleportData.CampSession)
        self.IsDirectBoot = false
        self.Status = 'Maze session is ready. Use the expedition console to deploy the crew.'
    end

    self.InventoryService = InventoryService.new(self.SessionData.InventoryCapacity)
end

function MazeSessionService:_addPlayerState(player)
    self.InventoryService:addPlayer(player)
    self.RoleService:assignPlayer(player)
end

function MazeSessionService:_removePlayerState(player)
    self.InventoryService:removePlayer(player)
    self.RoleService:removePlayer(player)
end

function MazeSessionService:_buildVisibleRoster(player)
    local rosterByUserId = self.RoleService:getVisibleRoster(player)
    local roster = {}

    for _, entry in pairs(rosterByUserId) do
        table.insert(roster, entry)
    end

    table.sort(roster, function(left, right)
        return left.Name < right.Name
    end)

    return roster
end

function MazeSessionService:_setStatus(status)
    self.Status = status
    self:_broadcastSnapshot()
end

function MazeSessionService:_getPlayerArea(player)
    if not self.IsLaunched or not self.World then
        return 'Maze Spawn'
    end

    local character = player.Character
    local rootPart = character and character:FindFirstChild('HumanoidRootPart')
    if not rootPart then
        return 'Maze Spawn'
    end

    local room = self.World.FindRoomByPosition(rootPart.Position)
    if not room then
        return 'Maze Spawn'
    end

    return string.format('%s Room', room.Kind)
end

function MazeSessionService:_getObjectiveFor()
    if self.StateMachine.Current == RunState.Camp then
        return 'Use the expedition console to deploy into the maze, or return to camp.'
    end

    if self.StateMachine.Current == RunState.Expedition then
        return 'Collect loot and reach the settlement pad at the extraction room.'
    end

    if self.StateMachine.Current == RunState.Extraction then
        return 'Settlement is underway. Hold position while the camp prepares your return.'
    end

    return 'Returning the crew to camp.'
end

function MazeSessionService:_broadcastSnapshot()
    for _, player in ipairs(Players:GetPlayers()) do
        self.Remotes.RunSnapshot:FireClient(player, {
            IsLaunched = self.IsLaunched,
            Status = self.Status,
            Area = self:_getPlayerArea(player),
            Objective = self:_getObjectiveFor(),
            State = self.StateMachine.Current,
            Inventory = self.InventoryService:getSummary(player),
            Roster = self:_buildVisibleRoster(player),
            SessionId = self.CampSession.SessionId,
            MazeAccessCode = self.CampSession.MazeAccessCode,
            MazeStatus = self.CampSession.MazeStatus,
            IsDirectBoot = self.IsDirectBoot,
        })

        self.Remotes.PrivateState:FireClient(player, self.RoleService:getPrivateState(player))
    end
end

function MazeSessionService:_rebuildWorld()
    self.World = MazeWorldBuilder.build(self.SessionData.Seed, SessionConfig.ProcGen)
    self:_bindWorldInteractions()
end

function MazeSessionService:_bindWorldInteractions()
    self.World.DeployPrompt.Triggered:Connect(function(player)
        self:_deployCrew(player)
    end)

    self.World.ReturnPrompt.Triggered:Connect(function(player)
        self:_returnPlayerToCamp(player, 'early_return')
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

function MazeSessionService:_deployCrew(player)
    if self.StateMachine.Current ~= RunState.Camp then
        self:_setStatus(
            string.format(
                '%s checked the expedition console, but the run is already active.',
                player.DisplayName
            )
        )
        return
    end

    self.StateMachine:transition(RunState.Expedition)
    self.MonsterService:spawn(self.World.PatrolPoints)
    self:_setStatus(string.format('%s deployed the crew into the maze.', player.DisplayName))
end

function MazeSessionService:_pickupLoot(player, roomId)
    if self.StateMachine.Current ~= RunState.Expedition then
        self:_setStatus('Loot can only be collected during the expedition phase.')
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

function MazeSessionService:_canReturnToCamp()
    return SessionConfig.PlaceIds.Run ~= 0 and self.CampSession.CampAccessCode ~= 'local-debug-camp'
end

function MazeSessionService:_teleportToCamp(players, summaries, mazeCompleted)
    if not self:_canReturnToCamp() then
        self:_setStatus(
            'Camp return is unavailable in direct boot. Set SessionConfig.PlaceIds.Run and enter from camp.'
        )
        return false
    end

    local nextCampSession = self.CampSession
    for _, summary in ipairs(summaries) do
        nextCampSession =
            CampMazeSessionContract.applyReturn(nextCampSession, summary, mazeCompleted)
    end

    local teleportData = CampMazeSessionContract.buildMazeToCampTeleportData({
        SessionConfig = self.SessionData,
        CampSession = nextCampSession,
        Summaries = summaries,
        MazeCompleted = mazeCompleted,
    })

    local success, message = pcall(function()
        TeleportService:TeleportToPrivateServer(
            SessionConfig.PlaceIds.Run,
            nextCampSession.CampAccessCode,
            players,
            nil,
            teleportData
        )
    end)

    if not success then
        self:_setStatus(string.format('Camp return failed: %s', tostring(message)))
        return false
    end

    self.CampSession = nextCampSession
    if mazeCompleted then
        self.IsCompleted = true
    end

    return true
end

function MazeSessionService:_buildSummaryFor(player, returnReason, isSettled)
    local inventorySummary = self.InventoryService:getSummary(player)
    self.InventoryService:deposit(player)

    return CampMazeSessionContract.buildReturnSummary({
        UserId = player.UserId,
        Name = player.DisplayName,
        ReturnReason = returnReason,
        Value = inventorySummary.Value,
        ItemCount = inventorySummary.Count,
        Weight = inventorySummary.Weight,
        WasExtracted = returnReason == 'extracted' or returnReason == 'settled',
        WasSettled = isSettled == true,
    })
end

function MazeSessionService:_returnPlayerToCamp(player, returnReason)
    if self.IsCompleted then
        return
    end

    local summary = self:_buildSummaryFor(player, returnReason, false)
    if self:_teleportToCamp({ player }, { summary }, false) then
        self:_setStatus(
            string.format(
                '%s is returning to camp with %d value.',
                player.DisplayName,
                summary.Value
            )
        )
    end
end

function MazeSessionService:_completeSettlement(player)
    if self.IsCompleted then
        return
    end

    if self.StateMachine.Current == RunState.Extraction then
        self.StateMachine:transition(RunState.Settlement)
    end

    local players = Players:GetPlayers()
    local summaries = {}

    for _, currentPlayer in ipairs(players) do
        table.insert(summaries, self:_buildSummaryFor(currentPlayer, 'settled', true))
    end

    if self:_teleportToCamp(players, summaries, true) then
        self:_setStatus(
            string.format(
                '%s completed settlement. Returning the crew to camp.',
                player.DisplayName
            )
        )
    end
end

function MazeSessionService:_startExtraction(player)
    if self.StateMachine.Current ~= RunState.Expedition then
        self:_setStatus('The settlement pad is only available during the expedition phase.')
        return
    end

    self.StateMachine:transition(RunState.Extraction)
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

    self:_startSnapshotLoop()
    self:_broadcastSnapshot()
end

function MazeSessionService:_startSnapshotLoop()
    if self.SnapshotThread then
        return
    end

    self.SnapshotThread = task.spawn(function()
        while true do
            task.wait(1)

            if self.IsLaunched then
                self:_broadcastSnapshot()
            end
        end
    end)
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

        self:_broadcastSnapshot()
    end)

    Players.PlayerRemoving:Connect(function(player)
        self:_removePlayerState(player)
        self:_broadcastSnapshot()
    end)

    self:_launchMaze()
end

return MazeSessionService
