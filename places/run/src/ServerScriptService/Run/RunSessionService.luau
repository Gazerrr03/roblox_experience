local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService('RunService')
local Workspace = game:GetService('Workspace')

local Packages = ReplicatedStorage:WaitForChild('Packages')
local Shared = require(Packages:WaitForChild('Shared'))

local SessionConfig = Shared.Config.SessionConfig
local Remotes = Shared.Network.Remotes.ensureScope(Shared.Network.Remotes.Scope.Run)
local CampMazeSessionContract = Shared.Session.CampMazeSessionContract
local MazeEntryAvailability = Shared.Session.MazeEntryAvailability
local SessionSeedPolicy = Shared.Session.SessionSeedPolicy
local ControlStateService = Shared.Runtime.ControlStateService
local FormalLocomotion = Shared.Runtime.FormalLocomotion
local InventoryService = Shared.Runtime.InventoryService
local PlayerService = Shared.Runtime.PlayerService
local PlayerStateService = Shared.Runtime.PlayerStateService
local TeleportInventoryHydrator = Shared.Runtime.TeleportInventoryHydrator

local RunSpawnPoint = require(script.Parent.RunSpawnPoint)
local RunStaticWorldContract = require(script.Parent.RunStaticWorldContract)
local RunToMazeTransition = require(script.Parent.RunToMazeTransition)
local RunWorldBuilder = require(script.Parent.RunWorldBuilder)

local RunSessionService = {}
RunSessionService.__index = RunSessionService

local DEFAULT_WORKSPACE_SHELL_NAMES = { 'Baseplate', 'SpawnLocation' }
local CAMP_SESSION_LOCK_WAIT_SECONDS = 0.05
local MAZE_ENTRY_REQUEST_COOLDOWN_SECONDS = 0.35
local MAZE_ENTRY_DISTANCE_BUFFER = 2
local TERMINAL_INTERACTION_DISTANCE_BUFFER = 2
local SNAPSHOT_INTERVAL_SECONDS = 0.25
local RUN_MAZE_GATE_RETURN_REASONS = table.freeze({
    early_return = true,
    extracted = true,
})
local INITIAL_TEMPLE_STATUS = 'Select Enter Temple to enter the temple.'
local BOOK_GOAL_AMOUNT = 120
local OCEAN_SPLASH_MESSAGE = 'Sea spray crashes over you.'
local SHOP_ITEMS = {
    {
        Id = 'temple_lantern',
        Name = 'Temple Lantern',
        Price = 18,
        Weight = 2,
        Value = 12,
        Light = {
            Brightness = 2,
            Range = 12,
            Color = Color3.fromRGB(255, 214, 153),
        },
    },
    {
        Id = 'sand_relic',
        Name = 'Sand Relic',
        Price = 24,
        Weight = 3,
        Value = 18,
        Color = Color3.fromRGB(224, 202, 152),
    },
    {
        Id = 'scribe_compass',
        Name = 'Scribe Compass',
        Price = 14,
        Weight = 1,
        Value = 9,
    },
}
local SHOP_ITEM_BY_ID = {}

for _, item in ipairs(SHOP_ITEMS) do
    SHOP_ITEM_BY_ID[item.Id] = item
end

table.freeze(SHOP_ITEMS)
table.freeze(SHOP_ITEM_BY_ID)

local function resolvePendingSpawnCFrame(self, pendingSpawnValue)
    if typeof(pendingSpawnValue) == 'CFrame' then
        return pendingSpawnValue
    end

    if type(pendingSpawnValue) == 'string' and self.World then
        return self.World:getSpawnCFrame(pendingSpawnValue)
    end

    error(string.format('Unknown run pending spawn target %q.', tostring(pendingSpawnValue)), 0)
end

local function bindCharacterTeleport(self, player)
    player.CharacterAdded:Connect(function(character)
        task.wait()
        if not character.Parent then
            return
        end

        if not self.World then
            return
        end

        local pendingSpawnValue = self.PendingSpawnByUserId[player.UserId]
        local targetCFrame = pendingSpawnValue
                and resolvePendingSpawnCFrame(self, pendingSpawnValue)
            or self.World.SpawnCFrame
        self.PendingSpawnByUserId[player.UserId] = nil
        character:PivotTo(targetCFrame)
        self:_applyMovementMode(player)
    end)
end

local function clearDefaultWorkspaceShell()
    for _, instanceName in ipairs(DEFAULT_WORKSPACE_SHELL_NAMES) do
        local instance = Workspace:FindFirstChild(instanceName)
        if instance then
            instance:Destroy()
        end
    end
end

local function cloneArray(input)
    local result = {}

    for index, entry in ipairs(input or {}) do
        result[index] = table.clone(entry)
    end

    return result
end

local function buildShopPayload()
    local payload = {}

    for _, item in ipairs(SHOP_ITEMS) do
        table.insert(payload, {
            Id = item.Id,
            Name = item.Name,
            Price = item.Price,
        })
    end

    return payload
end

local function getSellPrice(itemEntry)
    return math.max(1, math.floor((itemEntry.Value or 0) + 0.5))
end

local function buildSellPayload(inventorySummary)
    local items = {}

    local function insertItem(itemEntry)
        if not itemEntry then
            return
        end

        table.insert(items, {
            InstanceId = itemEntry.InstanceId,
            Name = itemEntry.Name,
            Price = getSellPrice(itemEntry),
            Color = itemEntry.Color,
        })
    end

    for _, itemEntry in ipairs(inventorySummary.BackpackItems or {}) do
        insertItem(itemEntry)
    end

    insertItem(inventorySummary.HeldItem)

    return items
end

local function removeItemFromSummary(summary, itemInstanceId)
    if summary.HeldItem and summary.HeldItem.InstanceId == itemInstanceId then
        local removed = summary.HeldItem
        summary.HeldItem = nil
        return removed
    end

    for index, itemEntry in ipairs(summary.BackpackItems or {}) do
        if itemEntry.InstanceId == itemInstanceId then
            local removed = itemEntry
            table.remove(summary.BackpackItems, index)
            return removed
        end
    end

    return nil
end

local function runWithCampSessionLock(self, callback)
    while self.CampSessionLock do
        task.wait(CAMP_SESSION_LOCK_WAIT_SECONDS)
    end

    self.CampSessionLock = true
    local results = table.pack(pcall(callback))
    self.CampSessionLock = false

    if not results[1] then
        error(results[2], 0)
    end

    return table.unpack(results, 2, results.n)
end

function RunSessionService.new(options)
    local runtimeOptions = options or {}
    local self = setmetatable({}, RunSessionService)

    self.Remotes = Remotes
    self.BuildFingerprint = RunStaticWorldContract.BuildFingerprint
    self.SessionData = {
        Seed = SessionConfig.DefaultSeed,
        Quota = SessionConfig.DefaultQuota,
        RunDurationSeconds = SessionConfig.DefaultRunDurationSeconds,
        InventoryCapacity = SessionConfig.InventoryCapacity,
    }
    self.CampSession = CampMazeSessionContract.newCampSession({})
    self.Status = INITIAL_TEMPLE_STATUS
    self.IsLaunched = false
    self.ShouldAutoLaunch = false
    self.GateOpen = false
    self.World = nil
    self.WorldInteractions = nil
    self.SnapshotThread = nil
    self.PendingSpawnByUserId = {}
    self.CampSessionLock = false
    self.HasAuthoritativeSessionSeed = false
    self.SessionSeedRandom = nil
    self.LastMazeEntryRequestAtByUserId = {}
    self.LastOceanSplashAtByUserId = {}
    self.MazeEntryMode = MazeEntryAvailability.Mode.Blocked
    self.MazeEntryReason =
        'Set SessionConfig.PlaceIds.Maze or SessionPlaceIdMaze before using the maze gate.'
    self.MazeEntryReasonCode = MazeEntryAvailability.ReasonCode.MazePlaceIdMissing
    self.TeamPages = 0
    self.BookGoalAmount = BOOK_GOAL_AMOUNT
    self.InventoryService = InventoryService.new(self.SessionData.InventoryCapacity)
    self.ControlStateService = ControlStateService.new()
    self.PlayerService = PlayerService.new()
    self.PlayerStateService = PlayerStateService.new()
    self.RunToMazeTransition = runtimeOptions.RunToMazeTransition or RunToMazeTransition.new()
    self.WorldBuilder = runtimeOptions.RunWorldBuilder or RunWorldBuilder

    return self
end

function RunSessionService:_addPlayerState(player)
    self.InventoryService:addPlayer(player)
    self.ControlStateService:addPlayer(player)
    self.PlayerStateService:addPlayer(player)
    self.PlayerService:addPlayer(player)
end

function RunSessionService:_removePlayerState(player)
    self.InventoryService:removePlayer(player)
    self.ControlStateService:removePlayer(player)
    self.PlayerService:removePlayer(player)
end

function RunSessionService:_handleOceanEntered(player)
    local now = os.clock()
    local lastSplashAt = self.LastOceanSplashAtByUserId[player.UserId]
    if
        lastSplashAt ~= nil
        and now - lastSplashAt < RunStaticWorldContract.OceanSplashCooldownSeconds
    then
        return
    end

    self.LastOceanSplashAtByUserId[player.UserId] = now
    self.Remotes.RunPrivateState:FireClient(player, {
        Type = 'OceanSplash',
        Message = OCEAN_SPLASH_MESSAGE,
        FutureEffect = 'DrownDamagePending',
    })
end

function RunSessionService:_getMovementSummaryFor(player)
    local playerState = self.PlayerService:getSummary(player)
    local controlState = self.ControlStateService:getSummary(player)
    return FormalLocomotion.summarize(playerState, controlState)
end

function RunSessionService:_applyMovementMode(player)
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass('Humanoid')
    if not humanoid then
        return
    end

    FormalLocomotion.applyToHumanoid(humanoid, self:_getMovementSummaryFor(player))
end

function RunSessionService:_syncPlayerMovement(player)
    local playerState = self.PlayerService:getSummary(player)
    local ok, controlState = self.ControlStateService:syncPlayerState(player, playerState)
    if ok and controlState then
        self.PlayerService:setSprinting(player, controlState.Mode == FormalLocomotion.Mode.Sprint)
    end

    self:_applyMovementMode(player)
end

function RunSessionService:_readTeleportData(player)
    local joinData = player:GetJoinData()
    return joinData and joinData.TeleportData
end

function RunSessionService:_applySessionConfig(incoming)
    if type(incoming) ~= 'table' then
        return
    end

    if type(incoming.Seed) == 'number' then
        self.SessionData.Seed = incoming.Seed
        self.HasAuthoritativeSessionSeed = true
    end
    if type(incoming.Quota) == 'number' then
        self.SessionData.Quota = incoming.Quota
    end
    if type(incoming.RunDurationSeconds) == 'number' then
        self.SessionData.RunDurationSeconds = incoming.RunDurationSeconds
    end
    if type(incoming.InventoryCapacity) == 'number' then
        self.SessionData.InventoryCapacity = incoming.InventoryCapacity
        self.InventoryService.Capacity = incoming.InventoryCapacity
    end
end

function RunSessionService:_hydratePlayerInventory(player, teleportData)
    return TeleportInventoryHydrator.hydratePlayerInventory(
        self.InventoryService,
        player,
        teleportData,
        CampMazeSessionContract.findPlayerInventory
    )
end

function RunSessionService:_syncCampSession()
    self.CampSession = CampMazeSessionContract.normalizeCampSession(self.CampSession)
    self.CampSession.GateOpen = self.GateOpen
end

function RunSessionService:_applyIncomingCampSession(teleportData)
    if type(teleportData) ~= 'table' then
        return nil, false
    end

    local incomingSession = teleportData.CampSession
    if type(incomingSession) ~= 'table' then
        return nil, false
    end

    local nextSession, accepted =
        CampMazeSessionContract.reconcileIncomingCampSession(self.CampSession, incomingSession)
    if not accepted then
        return nil, false
    end

    self.CampSession = nextSession
    self.GateOpen = self.CampSession.GateOpen
    self.ShouldAutoLaunch = true

    return teleportData, true
end

function RunSessionService:_loadSessionDataFromJoin()
    local players = Players:GetPlayers()
    if #players == 0 then
        return
    end

    local acceptedTeleportData = nil
    for _, player in ipairs(players) do
        local teleportData = self:_readTeleportData(player)
        local _, accepted = self:_applyIncomingCampSession(teleportData)
        if accepted then
            self:_applySessionConfig(teleportData.SessionConfig)
            acceptedTeleportData = teleportData
            break
        end
    end

    if not acceptedTeleportData then
        return
    end

    self:_applyReturnedPlayersFromTeleportData(players, acceptedTeleportData)
end

function RunSessionService:_getReturnStatusText(playerDisplayName, summary, teleportData)
    if RUN_MAZE_GATE_RETURN_REASONS[summary.ReturnReason] then
        return string.format(
            '%s returned to the maze gate with %d value (%s).',
            playerDisplayName,
            summary.Value or 0,
            summary.ReturnReason or 'unknown'
        )
    end

    if teleportData.MazeReturn and teleportData.MazeReturn.MazeCompleted == true then
        return string.format(
            '%s returned from the completed maze run with %d value.',
            playerDisplayName,
            summary.Value or 0
        )
    end

    return string.format(
        '%s returned from the maze with %d value (%s).',
        playerDisplayName,
        summary.Value or 0,
        summary.ReturnReason or 'unknown'
    )
end

function RunSessionService:_applyReturnedPlayersFromTeleportData(players, acceptedTeleportData)
    local returnedPlayers = {}
    for _, player in ipairs(players) do
        local teleportData = self:_readTeleportData(player) or acceptedTeleportData
        local returnSummary = CampMazeSessionContract.findReturnSummary(teleportData, player.UserId)
        if returnSummary then
            self.PendingSpawnByUserId[player.UserId] =
                self:_getReturnSpawnTargetForSummary(returnSummary)
            table.insert(returnedPlayers, {
                Player = player,
                Summary = returnSummary,
                TeleportData = teleportData,
            })
        end
    end

    if #returnedPlayers == 1 then
        local returnedPlayer = returnedPlayers[1]
        self.Status = self:_getReturnStatusText(
            returnedPlayer.Player.DisplayName,
            returnedPlayer.Summary,
            returnedPlayer.TeleportData
        )
    elseif #returnedPlayers > 1 then
        self.Status = 'The crew returned from the maze. Review the temple summaries together.'
    else
        self.Status = 'Temple is ready. Gather inside, then head outside when the group is ready.'
    end
end

function RunSessionService:_teleportCharactersToSpawn()
    if not self.World then
        return
    end

    for _, player in ipairs(Players:GetPlayers()) do
        local character = player.Character
        if character and character.Parent then
            local pendingSpawnValue = self.PendingSpawnByUserId[player.UserId]
            local targetCFrame = pendingSpawnValue
                    and resolvePendingSpawnCFrame(self, pendingSpawnValue)
                or self.World.SpawnCFrame
            self.PendingSpawnByUserId[player.UserId] = nil
            character:PivotTo(targetCFrame)
            self:_applyMovementMode(player)
        end
    end
end

function RunSessionService:_getReturnSpawnTargetForSummary(summary)
    if RUN_MAZE_GATE_RETURN_REASONS[summary.ReturnReason] then
        return RunSpawnPoint.Kind.MazeReturn
    end

    return RunSpawnPoint.Kind.Return
end

function RunSessionService:_rebuildWorld()
    clearDefaultWorkspaceShell()

    if self.WorldInteractions then
        self.WorldInteractions:disconnectAll()
        self.WorldInteractions = nil
    end

    self.World = self.WorldBuilder.build()
    if self.GateOpen then
        self.World:openGate()
    end

    self.WorldInteractions = self.World:bindInteractions({
        OnShop = function(player)
            if not self:_canManageInventory(player) then
                return
            end

            self:_openShop(player)
        end,
        OnSell = function(player)
            if not self:_canManageInventory(player) then
                return
            end

            self:_openSell(player)
        end,
        OnObjective = function(player)
            self:_openObjectiveBoard(player)
        end,
        OnLoadout = function(player)
            self:_setStatus(
                string.format(
                    '%s checked the loadout bench. Equipment setup is coming soon.',
                    player.DisplayName
                )
            )
        end,
        OnUgcLab = function(player)
            self:_setStatus(
                string.format(
                    '%s checked the UGC lab console. Creature forging is coming soon.',
                    player.DisplayName
                )
            )
        end,
        OnGate = function(player)
            self:_openGate(player)
        end,
        OnMazePortal = function(player)
            if self:_canProcessMazeEntryRequest(player) then
                self:_requestMazeEntry(player, false)
            end
        end,
        OnOceanEntered = function(player)
            self:_handleOceanEntered(player)
        end,
    })

    self:_teleportCharactersToSpawn()
end

function RunSessionService:_getPlayerArea(player)
    if not self.IsLaunched or not self.World then
        return 'Title Screen'
    end

    local character = player.Character
    local rootPart = character and character:FindFirstChild('HumanoidRootPart')
    if not rootPart then
        return self.GateOpen and 'Temple Threshold' or 'Temple Hall'
    end

    return self.World:getAreaForPosition(rootPart.Position)
end

function RunSessionService:_buildRoster()
    local roster = {}

    for _, player in ipairs(Players:GetPlayers()) do
        table.insert(roster, {
            Name = player.DisplayName,
            UserId = player.UserId,
        })
    end

    table.sort(roster, function(left, right)
        return left.Name < right.Name
    end)

    return roster
end

function RunSessionService:_getObjectiveFor(player)
    local area = self:_getPlayerArea(player)

    if not self.GateOpen then
        return 'Inspect the temple terminals and open the gate when the group is ready.'
    end

    if self.CampSession.MazeStatus == CampMazeSessionContract.MazeStatus.Completed then
        return 'The maze run is complete. Review the returned crew summaries in the temple.'
    end

    if self.CampSession.MazeStatus == CampMazeSessionContract.MazeStatus.Active then
        if area == 'Wilderness' then
            return 'A maze session is active. Use the gate outside to join the shared expedition.'
        end

        return 'Head outside and use the maze gate to join the active shared expedition.'
    end

    if area == 'Wilderness' then
        return 'Inspect the maze gate outside to open the first maze session.'
    end

    return 'Step outside to the wilderness clearing and inspect the maze gate.'
end

function RunSessionService:_setStatus(status)
    self.Status = status
    self:_broadcastSnapshot()
end

function RunSessionService:_getBookSnapshot()
    local progress = 0
    if self.BookGoalAmount > 0 then
        progress = math.clamp(self.TeamPages / self.BookGoalAmount, 0, 1)
    end

    return {
        TeamPages = self.TeamPages,
        BookGoalAmount = self.BookGoalAmount,
        BookGoalProgress = progress,
        BookGoalReached = self.TeamPages >= self.BookGoalAmount,
    }
end

function RunSessionService:_sendPrivate(player, payload)
    self.Remotes.RunPrivateState:FireClient(player, payload)
end

function RunSessionService:_broadcastPrivate(payload)
    for _, player in ipairs(Players:GetPlayers()) do
        self:_sendPrivate(player, payload)
    end
end

function RunSessionService:_toast(player, message, tone)
    self:_sendPrivate(player, {
        Type = 'Toast',
        Message = message,
        Tone = tone or 'Info',
    })
end

function RunSessionService:_openShop(player)
    self:_sendPrivate(player, {
        Type = 'OpenShop',
        Items = buildShopPayload(),
        TeamPages = self.TeamPages,
        Inventory = self.InventoryService:getSummary(player),
    })
end

function RunSessionService:_openSell(player)
    local inventorySummary = self.InventoryService:getSummary(player)
    self:_sendPrivate(player, {
        Type = 'OpenSell',
        Items = buildSellPayload(inventorySummary),
        TeamPages = self.TeamPages,
    })
end

function RunSessionService:_openObjectiveBoard(player)
    local snapshot = self:_getBookSnapshot()
    self:_sendPrivate(player, {
        Type = 'OpenObjectiveBoard',
        BookGoalAmount = snapshot.BookGoalAmount,
        BookGoalProgress = snapshot.BookGoalProgress,
        BookGoalReached = snapshot.BookGoalReached,
        TeamPages = snapshot.TeamPages,
    })
end

function RunSessionService:_handlePurchase(player, itemId)
    if not self:_canManageInventory(player) then
        return
    end
    if not self:_isPlayerNearTerminalPrompt(player, self.World and self.World.ShopPrompt) then
        self:_toast(player, 'Move closer to the shop terminal.', 'Error')
        return
    end

    local itemDef = SHOP_ITEM_BY_ID[itemId]
    if not itemDef then
        self:_toast(player, 'Unknown item.', 'Error')
        return
    end

    if self.TeamPages < itemDef.Price then
        self:_sendPrivate(player, {
            Type = 'ShopResult',
            Success = false,
            Reason = 'InsufficientFunds',
        })
        return
    end

    local ok, reason = self.InventoryService:pickup(player, itemDef)
    if not ok then
        self:_sendPrivate(player, {
            Type = 'ShopResult',
            Success = false,
            Reason = reason or 'InventoryFull',
        })
        return
    end

    local wasBelowGoal = self.TeamPages < self.BookGoalAmount
    self.TeamPages -= itemDef.Price

    self:_sendPrivate(player, {
        Type = 'ShopResult',
        Success = true,
        ItemId = itemDef.Id,
        TeamPages = self.TeamPages,
        Inventory = self.InventoryService:getSummary(player),
    })

    self:_broadcastSnapshot()

    if wasBelowGoal and self.TeamPages >= self.BookGoalAmount then
        local snapshot = self:_getBookSnapshot()
        self:_broadcastPrivate({
            Type = 'GoalReached',
            TeamPages = snapshot.TeamPages,
        })
    end
end

function RunSessionService:_handleSell(player, itemInstanceId)
    if not self:_canManageInventory(player) then
        return
    end
    if not self:_isPlayerNearTerminalPrompt(player, self.World and self.World.SellPrompt) then
        self:_toast(player, 'Move closer to the salvage terminal.', 'Error')
        return
    end

    if type(itemInstanceId) ~= 'number' then
        self:_toast(player, 'Invalid item.', 'Error')
        return
    end

    local inventorySummary = self.InventoryService:getSummary(player)
    local removedItem = removeItemFromSummary(inventorySummary, itemInstanceId)
    if not removedItem then
        self:_toast(player, 'Item not found.', 'Error')
        return
    end

    local ok, reason = self.InventoryService:loadSummary(player, inventorySummary)
    if not ok then
        self:_toast(
            player,
            string.format('Could not update inventory (%s).', tostring(reason)),
            'Error'
        )
        return
    end

    local reward = getSellPrice(removedItem)
    local wasBelowGoal = self.TeamPages < self.BookGoalAmount
    self.TeamPages += reward

    self:_sendPrivate(player, {
        Type = 'SellResult',
        Success = true,
        ItemInstanceId = itemInstanceId,
        Amount = reward,
        TeamPages = self.TeamPages,
    })

    self:_broadcastSnapshot()

    if wasBelowGoal and self.TeamPages >= self.BookGoalAmount then
        local snapshot = self:_getBookSnapshot()
        self:_broadcastPrivate({
            Type = 'GoalReached',
            TeamPages = snapshot.TeamPages,
        })
    end
end

function RunSessionService:_resolveMazeEntryAvailability()
    local availability = MazeEntryAvailability.evaluate({
        PlaceIds = SessionConfig.PlaceIds,
        PlaceId = game.PlaceId,
        GameId = game.GameId,
        IsStudio = RunService:IsStudio(),
    })

    self.MazeEntryMode = availability.Mode
    self.MazeEntryReason = availability.Reason
    self.MazeEntryReasonCode = availability.ReasonCode

    return availability
end

function RunSessionService:_broadcastSnapshot()
    local roster = self:_buildRoster()
    local activeMazeRoster = cloneArray(self.CampSession.PlayersInMaze)
    local returnedSummaries = cloneArray(self.CampSession.ReturnedPlayerSummaries)
    local mazeEntryAvailability = self:_resolveMazeEntryAvailability()
    local bookSnapshot = self:_getBookSnapshot()

    for _, player in ipairs(Players:GetPlayers()) do
        local playerSummary = self.PlayerService:getSummary(player)
        local playerStateSummary = if playerSummary and playerSummary.PlayerState ~= nil
            then playerSummary.PlayerState
            else self.PlayerStateService:getSummary(player)
        self.Remotes.RunState:FireClient(player, {
            IsLaunched = self.IsLaunched,
            Status = self.Status,
            BuildFingerprint = self.BuildFingerprint,
            Area = self:_getPlayerArea(player),
            GateOpen = self.GateOpen,
            Objective = self:_getObjectiveFor(player),
            Roster = roster,
            SessionId = self.CampSession.SessionId,
            MazeStatus = self.CampSession.MazeStatus,
            PlayersInMaze = activeMazeRoster,
            ReturnedPlayerSummaries = returnedSummaries,
            MazeEntryMode = mazeEntryAvailability.Mode,
            MazeEntryReason = mazeEntryAvailability.Reason,
            MazeEntryReasonCode = mazeEntryAvailability.ReasonCode,
            TeamPages = bookSnapshot.TeamPages,
            BookGoalAmount = bookSnapshot.BookGoalAmount,
            BookGoalProgress = bookSnapshot.BookGoalProgress,
            BookGoalReached = bookSnapshot.BookGoalReached,
            Inventory = self.InventoryService:getSummary(player),
            Movement = self:_getMovementSummaryFor(player),
            ControlState = self.ControlStateService:getSummary(player),
            PlayerState = playerStateSummary,
        })

        self.Remotes.RunPrivateState:FireClient(player, nil)
    end
end

function RunSessionService:_canManageInventory(player)
    if not self.IsLaunched then
        return false
    end

    if CampMazeSessionContract.isPlayerInMaze(self.CampSession, player.UserId) then
        self:_setStatus(
            string.format(
                '%s is already marked inside the maze and cannot change temple inventory.',
                player.DisplayName
            )
        )
        return false
    end

    return true
end

function RunSessionService:_equipItem(player, itemInstanceId)
    if not self:_canManageInventory(player) then
        return
    end

    local success, result = self.InventoryService:equip(player, itemInstanceId)
    if not success then
        self:_setStatus(
            string.format(
                '%s could not equip that item (%s).',
                player.DisplayName,
                tostring(result)
            )
        )
        return
    end

    self:_setStatus(string.format('%s equipped %s in the temple.', player.DisplayName, result.Name))
end

function RunSessionService:_unequipItem(player)
    if not self:_canManageInventory(player) then
        return
    end

    local success, result = self.InventoryService:unequip(player)
    if not success then
        self:_setStatus(
            string.format(
                '%s could not stow the held item (%s).',
                player.DisplayName,
                tostring(result)
            )
        )
        return
    end

    self:_setStatus(
        string.format('%s stowed %s back into the backpack.', player.DisplayName, result.Name)
    )
end

function RunSessionService:_openGate(player)
    if not self.World then
        return
    end

    if not self.GateOpen then
        self.GateOpen = true
        self:_syncCampSession()
        self.World:openGate()
        self:_setStatus(
            string.format(
                '%s opened the temple gate. The wilderness trail is now accessible.',
                player.DisplayName
            )
        )
        return
    end

    self:_setStatus(
        string.format(
            '%s checked the temple gate. The wilderness trail is already open.',
            player.DisplayName
        )
    )
end

function RunSessionService:_enterMaze(player)
    runWithCampSessionLock(self, function()
        if SessionConfig.PlaceIds.Maze == 0 then
            self:_setStatus(
                'Set SessionConfig.PlaceIds.Maze or SessionPlaceIdMaze before using the maze gate.'
            )
            return
        end

        if self.CampSession.MazeStatus == CampMazeSessionContract.MazeStatus.Completed then
            self:_setStatus('The maze session is already complete for this temple.')
            return
        end

        local result = self.RunToMazeTransition:enter({
            Player = player,
            CampSession = self.CampSession,
            GateOpen = self.GateOpen,
            SessionConfig = self.SessionData,
            PlayerInventory = self.InventoryService:getSummary(player),
            EnteringPlayer = {
                UserId = player.UserId,
                Name = player.DisplayName,
            },
            EntryReason = 'maze_gate',
        })
        if not result.Ok then
            self.CampSession = result.CurrentSession or self.CampSession
            self.MazeEntryMode = MazeEntryAvailability.Mode.Blocked
            self.MazeEntryReasonCode = result.ReasonCode or result.FailureCode
            self.MazeEntryReason = result.Reason
            self:_setStatus(
                string.format('%s could not enter the maze: %s', player.DisplayName, result.Reason)
            )
            return
        end

        self.MazeEntryMode = MazeEntryAvailability.Mode.Teleport
        self.MazeEntryReasonCode = result.ReasonCode
        self.MazeEntryReason = result.Reason
        self.CampSession = result.NextSession
        self:_setStatus(string.format('%s is entering the shared maze run.', player.DisplayName))
    end)
end

function RunSessionService:_isPlayerNearMazePrompt(player)
    return self:_isPlayerNearTerminalPrompt(
        player,
        self.World and self.World.MazePortal,
        MAZE_ENTRY_DISTANCE_BUFFER
    )
end

function RunSessionService:_isPlayerNearTerminalPrompt(player, terminalOrPrompt, distanceBuffer)
    if not terminalOrPrompt then
        return false
    end

    if type(terminalOrPrompt.isPlayerNear) == 'function' then
        return terminalOrPrompt:isPlayerNear(
            player,
            distanceBuffer or TERMINAL_INTERACTION_DISTANCE_BUFFER
        )
    end

    local prompt = terminalOrPrompt
    local promptPart = prompt.Parent
    if not promptPart or not promptPart:IsA('BasePart') then
        return false
    end

    local character = player.Character
    local rootPart = character and character:FindFirstChild('HumanoidRootPart')
    if not rootPart or not rootPart:IsA('BasePart') then
        return false
    end

    local maxDistance = prompt.MaxActivationDistance
        + (distanceBuffer or TERMINAL_INTERACTION_DISTANCE_BUFFER)
    return (rootPart.Position - promptPart.Position).Magnitude <= maxDistance
end

function RunSessionService:_requestMazeEntry(player, requireDistanceCheck)
    if not self.IsLaunched or not self.World then
        return
    end

    if not self.GateOpen then
        self:_setStatus(
            string.format(
                '%s checked the maze gate, but the temple gate is still closed.',
                player.DisplayName
            )
        )
        return
    end

    if requireDistanceCheck and not self:_isPlayerNearMazePrompt(player) then
        return
    end

    local availability = self:_resolveMazeEntryAvailability()
    if availability.Mode == MazeEntryAvailability.Mode.Teleport then
        self:_enterMaze(player)
        return
    end

    self:_setStatus(
        string.format(
            '%s could not enter the maze: %s (code=%s, gameId=%d, placeId=%d, mazePlaceId=%d)',
            player.DisplayName,
            availability.Reason,
            availability.ReasonCode or 'Unknown',
            game.GameId,
            game.PlaceId,
            SessionConfig.PlaceIds.Maze
        )
    )
end

function RunSessionService:_canProcessMazeEntryRequest(player)
    local now = os.clock()
    local previous = self.LastMazeEntryRequestAtByUserId[player.UserId]
    if previous and now - previous < MAZE_ENTRY_REQUEST_COOLDOWN_SECONDS then
        return false
    end

    self.LastMazeEntryRequestAtByUserId[player.UserId] = now
    return true
end

function RunSessionService:_launchRun(_player)
    if self.IsLaunched then
        return
    end

    self.GateOpen = self.CampSession.GateOpen == true
    self:_syncCampSession()

    self:_rebuildWorld()

    self.IsLaunched = true
    Players.CharacterAutoLoads = true

    for _, player in ipairs(Players:GetPlayers()) do
        player:LoadCharacter()
    end

    self:_startSnapshotLoop()
    if self.Status == INITIAL_TEMPLE_STATUS then
        self:_setStatus(
            'Temple is ready. Gather inside, then open the gate when you want to head out.'
        )
    else
        self:_broadcastSnapshot()
    end
end

function RunSessionService:_getPlayerUpdateContext(player)
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass('Humanoid')
    local rootPart = humanoid and humanoid.RootPart
    local currentPosition = rootPart and rootPart.Position or Vector3.zero

    return {
        CurrentPosition = currentPosition,
        InputState = {},
    }
end

function RunSessionService:_startSnapshotLoop()
    if self.SnapshotThread then
        return
    end

    self.SnapshotThread = task.spawn(function()
        local previousTick = os.clock()

        while true do
            task.wait(SNAPSHOT_INTERVAL_SECONDS)

            if self.IsLaunched then
                local currentTick = os.clock()
                local dt = currentTick - previousTick
                previousTick = currentTick

                for _, player in ipairs(Players:GetPlayers()) do
                    local context = self:_getPlayerUpdateContext(player)
                    self.PlayerService:update(player, dt, context)
                    self:_syncPlayerMovement(player)
                end

                self:_broadcastSnapshot()
            else
                previousTick = os.clock()
            end
        end
    end)
end

function RunSessionService:_setPlayerSprinting(player, isSprinting)
    if not self.IsLaunched then
        return
    end

    local playerState = self.PlayerService:getSummary(player)
    local success, result
    if isSprinting then
        success, result = self.ControlStateService:requestSprintStart(player, playerState)
    else
        success, result = self.ControlStateService:requestSprintStop(player)
    end

    if not success then
        if result == 'StaminaDepleted' then
            self:_setStatus(string.format('%s is too exhausted to sprint.', player.DisplayName))
        elseif result == 'Dead' then
            self:_setStatus(string.format('%s cannot sprint while dead.', player.DisplayName))
        end
        self:_syncPlayerMovement(player)
        return
    end

    self:_syncPlayerMovement(player)
end

function RunSessionService:_handlePlayerTeleportData(player)
    local teleportData = self:_readTeleportData(player)
    if not teleportData then
        return
    end

    local _, accepted = self:_applyIncomingCampSession(teleportData)
    if not accepted then
        return
    end

    self:_applySessionConfig(teleportData.SessionConfig)
    self:_hydratePlayerInventory(player, teleportData)

    local summary = CampMazeSessionContract.findReturnSummary(teleportData, player.UserId)
    if summary then
        self.PendingSpawnByUserId[player.UserId] = self:_getReturnSpawnTargetForSummary(summary)
        self.Status = self:_getReturnStatusText(player.DisplayName, summary, teleportData)
        return
    end

    self.CampSession = CampMazeSessionContract.prunePlayer(self.CampSession, player.UserId, {
        PreserveMazeEntry = CampMazeSessionContract.isPlayerInMaze(self.CampSession, player.UserId),
    })
    self.GateOpen = self.CampSession.GateOpen
    self.Status = string.format('%s joined the temple session.', player.DisplayName)
end

function RunSessionService:_ensureAuthoritativeSessionSeed()
    local seed, issuedNewSeed = SessionSeedPolicy.ensureAuthoritativeSeed({
        CurrentSeed = self.SessionData.Seed,
        DefaultSeed = SessionConfig.DefaultSeed,
        HasAuthoritativeSeed = self.HasAuthoritativeSessionSeed,
        RandomSource = self.SessionSeedRandom or Random.new(),
    })

    self.SessionData.Seed = seed
    if issuedNewSeed then
        self.HasAuthoritativeSessionSeed = true
    end
end

function RunSessionService:start()
    warn(string.format('[run-session] build=%s', self.BuildFingerprint))
    self:_loadSessionDataFromJoin()
    self:_ensureAuthoritativeSessionSeed()
    Players.CharacterAutoLoads = false

    for _, player in ipairs(Players:GetPlayers()) do
        bindCharacterTeleport(self, player)
        self:_addPlayerState(player)
        self:_hydratePlayerInventory(player, self:_readTeleportData(player))

        if player.Character then
            player.Character:Destroy()
        end
    end

    Players.PlayerAdded:Connect(function(player)
        bindCharacterTeleport(self, player)
        self:_addPlayerState(player)
        self:_handlePlayerTeleportData(player)

        if self.IsLaunched then
            player:LoadCharacter()
        end

        self:_broadcastSnapshot()
    end)

    Players.PlayerRemoving:Connect(function(player)
        self.LastMazeEntryRequestAtByUserId[player.UserId] = nil
        self.LastOceanSplashAtByUserId[player.UserId] = nil
        self.PendingSpawnByUserId[player.UserId] = nil
        self.CampSession = CampMazeSessionContract.prunePlayer(self.CampSession, player.UserId, {
            PreserveMazeEntry = CampMazeSessionContract.isPlayerInMaze(
                self.CampSession,
                player.UserId
            ),
        })
        self.GateOpen = self.CampSession.GateOpen
        self:_removePlayerState(player)
        self:_broadcastSnapshot()
    end)

    self.Remotes.RunAction.OnServerEvent:Connect(function(player, payload)
        if type(payload) ~= 'table' then
            return
        end

        if payload.Type == 'RequestLaunchRun' then
            self:_launchRun(player)
        elseif payload.Type == 'RequestEnterMaze' then
            if self:_canProcessMazeEntryRequest(player) then
                self:_requestMazeEntry(player, true)
            end
        elseif payload.Type == 'RequestPurchaseItem' then
            self:_handlePurchase(player, payload.ItemId)
        elseif payload.Type == 'RequestSellItem' then
            self:_handleSell(player, payload.ItemInstanceId)
        elseif payload.Type == 'RequestEquipItem' then
            self:_equipItem(player, payload.ItemInstanceId)
        elseif payload.Type == 'RequestUnequipItem' then
            self:_unequipItem(player)
        elseif payload.Type == 'RequestSprintStart' then
            self:_setPlayerSprinting(player, true)
        elseif payload.Type == 'RequestSprintStop' then
            self:_setPlayerSprinting(player, false)
        elseif payload.Type == 'RequestStartExpedition' then
            self:_setStatus(
                string.format(
                    '%s checked the old deploy action. Use the temple gate to head outside instead.',
                    player.DisplayName
                )
            )
        end
    end)

    self:_broadcastSnapshot()

    self:_launchRun(nil)
end

return RunSessionService
