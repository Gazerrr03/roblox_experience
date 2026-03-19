local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService('RunService')
local TeleportService = game:GetService('TeleportService')
local Workspace = game:GetService('Workspace')

local DEFAULT_WORKSPACE_SHELL_NAMES = { 'Baseplate', 'SpawnLocation' }
local CAMP_SESSION_LOCK_WAIT_SECONDS = 0.05
local SNAPSHOT_INTERVAL_SECONDS = 0.25
local CORPSE_COLOR = Color3.fromRGB(92, 92, 92)
local CORPSE_MATERIAL = Enum.Material.Slate
local CORPSE_SIZE = Vector3.new(4, 1.2, 2)
local CORPSE_VERTICAL_OFFSET = -2.4

local Packages = ReplicatedStorage:WaitForChild('Packages')
local Shared = require(Packages:WaitForChild('Shared'))
local Gameplay = require(Packages:WaitForChild('Gameplay'))
local SharedPackage = Packages:WaitForChild('Shared')

local SessionConfig = Shared.Config.SessionConfig
local CampMazeSessionContract = Shared.Session.CampMazeSessionContract
local Remotes = Shared.Network.Remotes.ensure()
local InventoryService =
    require(SharedPackage:WaitForChild('Runtime'):WaitForChild('InventoryService'))
local MonsterService = require(SharedPackage:WaitForChild('Runtime'):WaitForChild('MonsterService'))
local ControlStateService = Shared.Runtime.ControlStateService
local FormalLocomotion = Shared.Runtime.FormalLocomotion
local PlayerStateService = Shared.Runtime.PlayerStateService

local MazeWorldBuilder = require(script.Parent.MazeWorldBuilder)

local DEBUG_DAMAGE_BY_ACTION = {
    RequestDebugLightDamage = Gameplay.PlayerState.DamageKind.Light,
    RequestDebugHeavyDamage = Gameplay.PlayerState.DamageKind.Heavy,
}

local MazeSessionService = {}
MazeSessionService.__index = MazeSessionService

local function mergeSummaries(existingSummaries, nextSummaries)
    local summariesByUserId = {}

    for _, summary in ipairs(existingSummaries or {}) do
        summariesByUserId[summary.UserId] = table.clone(summary)
    end

    for _, summary in ipairs(nextSummaries or {}) do
        summariesByUserId[summary.UserId] = table.clone(summary)
    end

    local merged = {}
    for _, summary in pairs(summariesByUserId) do
        table.insert(merged, summary)
    end

    table.sort(merged, function(left, right)
        return left.UserId < right.UserId
    end)

    return merged
end

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
        self:_applyMovementMode(player)
    end)
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

function MazeSessionService.new()
    local self = setmetatable({}, MazeSessionService)

    self.SessionData = {
        Seed = SessionConfig.DefaultSeed,
        Quota = SessionConfig.DefaultQuota,
        RunDurationSeconds = SessionConfig.DefaultRunDurationSeconds,
        InventoryCapacity = SessionConfig.InventoryCapacity,
    }
    self.Remotes = Remotes
    self.CampSession = CampMazeSessionContract.newCampSession({
        MazeAccessCode = 'local-debug-maze',
        MazeStatus = CampMazeSessionContract.MazeStatus.Active,
    })
    self.Status = 'Direct boot: maze session is live. Explore, loot, and find an extraction point.'
    self.World = nil
    self.IsDirectBoot = true
    self.IsLaunched = false
    self.SnapshotThread = nil
    self.CampSessionLock = false
    self.RunTracker = Gameplay.Session.MazeRunTracker.new()
    self.InventoryService = InventoryService.new(self.SessionData.InventoryCapacity)
    self.ControlStateService = ControlStateService.new()
    self.PlayerStateService = PlayerStateService.new()
    self.MonsterService = MonsterService.new(Gameplay.Config.Monsters[1], function()
        return self.RunTracker:getState() == 'Expedition'
    end, function(player)
        return self.RunTracker:isPlayerActive(player.UserId)
    end, function(fromPosition, toPosition)
        if not self.World or not self.World.CanTraverseBetweenPositions then
            return true
        end

        return self.World.CanTraverseBetweenPositions(fromPosition, toPosition)
    end)
    self.CorpsesByUserId = {}

    return self
end

function MazeSessionService:_readTeleportData(player)
    local joinData = player:GetJoinData()
    return joinData and joinData.TeleportData
end

function MazeSessionService:_mergeTeleportData(teleportData, resetInventoryService)
    if type(teleportData) ~= 'table' then
        return false
    end

    local incomingSession = teleportData.CampSession
    if type(incomingSession) ~= 'table' then
        return false
    end

    local nextSession, accepted =
        CampMazeSessionContract.reconcileIncomingCampSession(self.CampSession, incomingSession)
    if not accepted then
        return false
    end

    local incoming = teleportData.SessionConfig
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

    self.CampSession = nextSession
    self.IsDirectBoot = false
    self.Status = 'Maze session is live. Explore, loot, and find an extraction point.'

    if resetInventoryService == true then
        self.InventoryService = InventoryService.new(self.SessionData.InventoryCapacity)
    end

    return true
end

function MazeSessionService:_loadSessionDataFromJoin()
    local players = Players:GetPlayers()
    if #players == 0 then
        return
    end

    for _, player in ipairs(players) do
        local merged = self:_mergeTeleportData(self:_readTeleportData(player), true)
        if merged then
            return
        end
    end
end

function MazeSessionService:_handlePlayerTeleportData(player)
    self:_mergeTeleportData(self:_readTeleportData(player), false)
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
    self.CampSession = CampMazeSessionContract.markPlayerEntered(self.CampSession, {
        UserId = player.UserId,
        Name = player.DisplayName,
    })
    self.ControlStateService:addPlayer(player)
    self.PlayerStateService:addPlayer(player)
end

function MazeSessionService:_removePlayerState(player)
    self.RunTracker:removePlayer(player.UserId)
    self.InventoryService:removePlayer(player)
    self.CampSession = CampMazeSessionContract.prunePlayer(self.CampSession, player.UserId, {
        PreserveReturnSummary = true,
    })
    self.ControlStateService:removePlayer(player)
    self.PlayerStateService:removePlayer(player)
end

function MazeSessionService:_getMovementSummaryFor(player)
    local playerState = self.PlayerStateService:getSummary(player)
    local controlState = self.ControlStateService:getSummary(player)
    return FormalLocomotion.summarize(playerState, controlState)
end

function MazeSessionService:_applyMovementMode(player)
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass('Humanoid')
    if not humanoid then
        return
    end

    FormalLocomotion.applyToHumanoid(humanoid, self:_getMovementSummaryFor(player))
end

function MazeSessionService:_syncPlayerMovement(player)
    local playerState = self.PlayerStateService:getSummary(player)
    local ok, controlState = self.ControlStateService:syncPlayerState(player, playerState)
    if ok and controlState then
        self.PlayerStateService:setSprinting(
            player,
            controlState.Mode == FormalLocomotion.Mode.Sprint
        )
    end

    self:_applyMovementMode(player)
end

function MazeSessionService:_clearPlayerMovement(player)
    self.ControlStateService:requestSprintStop(player)
    self.PlayerStateService:setSprinting(player, false)
    self:_applyMovementMode(player)
end

function MazeSessionService:_getMazeStatus()
    if self.RunTracker.IsCompleted then
        return CampMazeSessionContract.MazeStatus.Completed
    end

    return CampMazeSessionContract.MazeStatus.Active
end

function MazeSessionService:_buildRoster()
    local roster = {}

    for _, player in ipairs(Players:GetPlayers()) do
        table.insert(roster, {
            Name = player.DisplayName,
            UserId = player.UserId,
            InMaze = self.RunTracker:isPlayerActive(player.UserId),
        })
    end

    table.sort(roster, function(left, right)
        return left.Name < right.Name
    end)

    return roster
end

function MazeSessionService:_getPlayerArea(player)
    if not self.IsLaunched or not self.World then
        return 'Maze Staging'
    end

    local character = player.Character
    local rootPart = character and character:FindFirstChild('HumanoidRootPart')
    if not rootPart then
        return 'Maze Staging'
    end

    local room = self.World.FindRoomByPosition(rootPart.Position)
    if not room then
        return 'Maze Staging'
    end

    return string.format('%s Room', room.Kind)
end

function MazeSessionService:_getObjectiveFor()
    if self.RunTracker.IsCompleted then
        return 'The maze run is complete. Review the returned summaries back in camp.'
    end

    return 'Collect loot, avoid the monster, and reach a maze exit to return to camp.'
end

function MazeSessionService:_broadcastSnapshot()
    if not self.IsLaunched then
        return
    end

    local roster = self:_buildRoster()
    local returnedSummaries = mergeSummaries(
        self.CampSession.ReturnedPlayerSummaries,
        self.RunTracker:getReturnedSummaries()
    )
    local mazeStatus = self:_getMazeStatus()

    for _, player in ipairs(Players:GetPlayers()) do
        self.Remotes.RunSnapshot:FireClient(player, {
            IsLaunched = true,
            Status = self.Status,
            Area = self:_getPlayerArea(player),
            Objective = self:_getObjectiveFor(),
            State = self.RunTracker:getState(),
            Inventory = self.InventoryService:getSummary(player),
            Movement = self:_getMovementSummaryFor(player),
            ControlState = self.ControlStateService:getSummary(player),
            PlayerState = self.PlayerStateService:getSummary(player),
            Roster = roster,
            SessionId = self.CampSession.SessionId,
            MazeAccessCode = self.CampSession.MazeAccessCode,
            MazeStatus = mazeStatus,
            ReturnedPlayerSummaries = returnedSummaries,
            IsDirectBoot = self.IsDirectBoot,
        })

        self.Remotes.PrivateState:FireClient(player, nil)
    end
end

function MazeSessionService:_setStatus(status)
    self.Status = status
    print(string.format('[Maze] %s', status))
    self:_broadcastSnapshot()
end

function MazeSessionService:_rebuildWorld()
    clearDefaultWorkspaceShell()
    self.World = MazeWorldBuilder.build(self.SessionData.Seed, SessionConfig.ProcGen)
    self:_bindWorldInteractions()
end

function MazeSessionService:_bindWorldInteractions()
    for extractionNodeId, extractionNode in pairs(self.World.ExtractionNodes or {}) do
        extractionNode.Prompt.Triggered:Connect(function(player)
            self:_extractPlayer(player, extractionNodeId)
        end)
    end

    for roomId, lootEntry in pairs(self.World.LootNodes or {}) do
        lootEntry.Prompt.Triggered:Connect(function(player)
            self:_pickupLoot(player, roomId)
        end)
    end

    for doorwayId, doorway in pairs(self.World.Doorways or {}) do
        if doorway.Prompt then
            doorway.Prompt.Triggered:Connect(function(player)
                self:_toggleDoor(player, doorwayId)
            end)
        end
    end
end

function MazeSessionService:_toggleDoor(player, doorwayId)
    if not self.World or not self.World.ToggleDoor then
        return
    end

    local toggled = self.World.ToggleDoor(doorwayId)
    if not toggled then
        return
    end

    local doorway = self.World.Doorways and self.World.Doorways[doorwayId]
    if doorway then
        local stateText = doorway.IsOpen and 'opened' or 'closed'
        self:_setStatus(
            string.format('%s %s a concrete double door.', player.DisplayName, stateText)
        )
    end
end

function MazeSessionService:_buildSummaryFor(player, returnReason, wasSettled)
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
        WasSettled = wasSettled == true,
    })
end

function MazeSessionService:_canReturnToCamp()
    return SessionConfig.PlaceIds.Run ~= 0 and self.CampSession.CampAccessCode ~= 'local-debug-camp'
end

function MazeSessionService:_teleportToCamp(players, summaries, mazeCompleted)
    return runWithCampSessionLock(self, function()
        if not self:_canReturnToCamp() then
            self:_setStatus(
                'Camp return is unavailable in direct boot. Set SessionConfig.PlaceIds.Run and enter from camp.'
            )
            return false
        end

        -- Teleports yield, so keep the camp-side handoff serialized per maze server.
        local mergedSummaries = mergeSummaries(self.RunTracker:getReturnedSummaries(), summaries)
        local nextCampSession = self.CampSession
        for _, summary in ipairs(mergedSummaries) do
            nextCampSession =
                CampMazeSessionContract.applyReturn(nextCampSession, summary, mazeCompleted)
        end
        local teleportData = CampMazeSessionContract.buildMazeToCampTeleportData({
            SessionConfig = self.SessionData,
            CampSession = nextCampSession,
            Summaries = mergedSummaries,
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
        return true
    end)
end

function MazeSessionService:_beginFormalExpedition()
    local started, reason = self.RunTracker:beginExpedition()
    if not started then
        if reason ~= 'InvalidState' then
            self:_setStatus(string.format('Maze session could not start: %s', tostring(reason)))
        end
        return
    end

    self.MonsterService:spawn(self.World.PatrolPoints)
    self:_setStatus('Maze session is live. Explore, loot, and find an extraction point.')
end

function MazeSessionService:_canManageInventory(player)
    if not self.RunTracker:isPlayerActive(player.UserId) then
        self:_setStatus(
            string.format(
                '%s already returned and cannot change inventory state.',
                player.DisplayName
            )
        )
        return false
    end

    return true
end

function MazeSessionService:_setPlayerSprinting(player, isSprinting)
    if not self.RunTracker:isPlayerActive(player.UserId) then
        return
    end

    local playerState = self.PlayerStateService:getSummary(player)
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

function MazeSessionService:_equipItem(player, itemInstanceId)
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

    self:_setStatus(string.format('%s equipped %s.', player.DisplayName, result.Name))
end

function MazeSessionService:_unequipItem(player)
    if not self:_canManageInventory(player) then
        return
    end

    local success, result = self.InventoryService:unequip(player)
    if not success then
        self:_setStatus(
            string.format(
                '%s could not unequip the held item (%s).',
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

function MazeSessionService:_spawnCorpseForPlayer(player)
    if self.CorpsesByUserId[player.UserId] or not self.World or not self.World.Root then
        return
    end

    local character = player.Character
    local rootPart = character and character:FindFirstChild('HumanoidRootPart')
    local corpsePosition = rootPart and rootPart.Position or self.World.ReturnHoldCFrame.Position

    local corpse = Instance.new('Part')
    corpse.Name = string.format('Corpse_%d', player.UserId)
    corpse.Anchored = true
    corpse.Size = CORPSE_SIZE
    corpse.CFrame = CFrame.new(corpsePosition + Vector3.new(0, CORPSE_VERTICAL_OFFSET, 0))
    corpse.Color = CORPSE_COLOR
    corpse.Material = CORPSE_MATERIAL
    corpse.Parent = self.World.Root

    self.CorpsesByUserId[player.UserId] = corpse
end

function MazeSessionService:_handlePlayerDeath(player, damageKind)
    self:_spawnCorpseForPlayer(player)
    self:_syncPlayerMovement(player)

    local summary = self:_buildSummaryFor(player, 'death', false)
    local recorded = self.RunTracker:recordReturn(summary)
    if not recorded then
        return
    end

    local mazeCompleted = self.RunTracker:getActiveCount() == 0
    if mazeCompleted then
        local completed, reason = self.RunTracker:completeExpedition()
        if not completed then
            self:_setStatus(string.format('Maze completion failed: %s', tostring(reason)))
            return
        end

        self.MonsterService:destroy()
    end

    if self:_teleportToCamp({ player }, { summary }, mazeCompleted) then
        self:_setStatus(
            string.format(
                '%s took %s damage and was returned to camp.',
                player.DisplayName,
                string.lower(damageKind)
            )
        )
        return
    end

    local character = player.Character
    if character and character.Parent and self.World then
        character:PivotTo(self.World.ReturnHoldCFrame)
    end

    self:_setStatus(
        string.format(
            '%s took %s damage and died, leaving a corpse behind.',
            player.DisplayName,
            string.lower(damageKind)
        )
    )
end

function MazeSessionService:_applyPlayerDamage(player, damageKind)
    if not self.RunTracker:isPlayerActive(player.UserId) then
        return
    end

    local success, summary = self.PlayerStateService:applyDamage(player, damageKind)
    if not success then
        self:_setStatus(
            string.format('%s could not take damage (%s).', player.DisplayName, tostring(summary))
        )
        return
    end

    if summary.IsDead then
        self:_handlePlayerDeath(player, damageKind)
        return
    end

    self:_syncPlayerMovement(player)

    self:_setStatus(
        string.format(
            '%s took %s damage and now has %d/%d health pips.',
            player.DisplayName,
            string.lower(damageKind),
            summary.HealthPips,
            summary.MaxHealthPips
        )
    )
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

    local lootEntry = self.World.LootNodes[roomId]
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

function MazeSessionService:_extractPlayer(player, _extractionNodeId)
    if self.RunTracker:getState() ~= 'Expedition' then
        self:_setStatus('Extraction is only available during the expedition phase.')
        return
    end

    if not self.RunTracker:isPlayerActive(player.UserId) then
        self:_setStatus(string.format('%s already returned to camp.', player.DisplayName))
        return
    end

    local summary = self:_buildSummaryFor(player, 'extracted', false)
    local recorded, reason = self.RunTracker:recordReturn(summary)
    if not recorded then
        if reason == 'MissingActivePlayer' then
            self:_setStatus(string.format('%s already returned to camp.', player.DisplayName))
        end
        return
    end

    local mazeCompleted = self.RunTracker:getActiveCount() == 0
    if mazeCompleted then
        local completed, completionReason = self.RunTracker:completeExpedition()
        if not completed then
            self:_setStatus(string.format('Maze completion failed: %s', tostring(completionReason)))
            return
        end

        self.MonsterService:destroy()
    end

    self:_clearPlayerMovement(player)

    if self:_teleportToCamp({ player }, { summary }, mazeCompleted) then
        self:_setStatus(
            string.format('%s extracted with %d value.', player.DisplayName, summary.Value)
        )
        return
    end

    local character = player.Character
    if character and character.Parent then
        character:PivotTo(self.World.ReturnHoldCFrame)
    end

    self:_setStatus(
        string.format('%s reached the maze exit with %d value.', player.DisplayName, summary.Value)
    )
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

    self:_beginFormalExpedition()
    self:_startSnapshotLoop()
    self:_broadcastSnapshot()
end

function MazeSessionService:_startSnapshotLoop()
    if self.SnapshotThread then
        return
    end

    self.SnapshotThread = task.spawn(function()
        local previousTick = os.clock()

        while true do
            task.wait(SNAPSHOT_INTERVAL_SECONDS)

            if self.IsLaunched then
                local currentTick = os.clock()
                self.PlayerStateService:step(currentTick - previousTick)
                previousTick = currentTick

                for _, player in ipairs(Players:GetPlayers()) do
                    self:_syncPlayerMovement(player)
                end

                self:_broadcastSnapshot()
            else
                previousTick = os.clock()
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
        self:_handlePlayerTeleportData(player)
        bindCharacterTeleport(self, player)
        self:_addPlayerState(player)

        if self.IsLaunched then
            player:LoadCharacter()
            self:_setStatus(string.format('%s joined the shared maze session.', player.DisplayName))
            return
        end

        self:_broadcastSnapshot()
    end)

    Players.PlayerRemoving:Connect(function(player)
        self:_removePlayerState(player)
        self:_broadcastSnapshot()
    end)

    self.Remotes.RunAction.OnServerEvent:Connect(function(player, payload)
        if type(payload) ~= 'table' then
            return
        end

        if payload.Type == 'RequestEquipItem' then
            self:_equipItem(player, payload.ItemInstanceId)
        elseif payload.Type == 'RequestUnequipItem' then
            self:_unequipItem(player)
        elseif payload.Type == 'RequestSprintStart' then
            self:_setPlayerSprinting(player, true)
        elseif payload.Type == 'RequestSprintStop' then
            self:_setPlayerSprinting(player, false)
        elseif RunService:IsStudio() and DEBUG_DAMAGE_BY_ACTION[payload.Type] then
            self:_applyPlayerDamage(player, DEBUG_DAMAGE_BY_ACTION[payload.Type])
        end
    end)

    self:_launchMaze()
end

return MazeSessionService
