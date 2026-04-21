local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Packages = ReplicatedStorage:WaitForChild('Packages')
local ItemFields = require(Packages:WaitForChild('Gameplay')).Config.ItemFields
local SessionConfig = require(script.Parent.Parent.Config.SessionConfig)

local CampMazeSessionContract = {}
local SessionPhase = require(script.Parent.SessionPhase)

local MAZE_STATUS = {
    Idle = 'idle',
    Active = 'active',
    Completed = 'completed',
}

local DEFAULT_MAX_ROUNDS = SessionConfig.Mission.RoundCount
local DEFAULT_TARGET_ITEM_COUNT = SessionConfig.Mission.TargetItemCount

local function cloneShallow(value)
    if type(value) == 'table' then
        return table.clone(value)
    end

    return value
end

local function cloneArray(list)
    local result = {}

    for index, entry in ipairs(list or {}) do
        result[index] = cloneShallow(entry)
    end

    return result
end

local function cloneTable(input)
    return table.clone(input or {})
end

local function cloneInventoryItem(itemEntry)
    return ItemFields.copyItemEntry(itemEntry)
end

local function summarizeItems(backpackItems, heldItem)
    local lootCount = 0
    local clueCount = 0
    local toolCount = 0
    local missionCount = 0

    local function addItem(itemEntry)
        if type(itemEntry) ~= 'table' then
            return
        end

        local itemCategory = itemEntry.ItemCategory
        if itemCategory == 'Clue' then
            clueCount += 1
        elseif itemCategory == 'Tool' then
            toolCount += 1
        else
            lootCount += 1
        end

        if type(itemEntry.MissionCount) == 'number' then
            missionCount += itemEntry.MissionCount
        elseif itemCategory == 'Loot' or itemCategory == nil then
            missionCount += 1
        end
    end

    for _, itemEntry in ipairs(backpackItems) do
        addItem(itemEntry)
    end

    addItem(heldItem)

    return lootCount, clueCount, toolCount, missionCount
end

local function cloneInventorySummary(summary)
    if type(summary) ~= 'table' then
        return nil
    end

    local backpackItems = {}
    for index, itemEntry in ipairs(summary.BackpackItems or {}) do
        backpackItems[index] = cloneInventoryItem(itemEntry)
    end

    local heldItem = cloneInventoryItem(summary.HeldItem)
    local lootCount, clueCount, toolCount, missionCount = summarizeItems(backpackItems, heldItem)

    return {
        Capacity = summary.Capacity or 0,
        Weight = summary.Weight or 0,
        Count = summary.Count or (#backpackItems + (if heldItem then 1 else 0)),
        BackpackCount = summary.BackpackCount or #backpackItems,
        HeldCount = summary.HeldCount or (if heldItem then 1 else 0),
        Value = summary.Value or 0,
        BackpackItems = backpackItems,
        HeldItem = heldItem,
        LootCount = summary.LootCount or lootCount,
        ClueCount = summary.ClueCount or clueCount,
        ToolCount = summary.ToolCount or toolCount,
        MissionCount = summary.MissionCount or missionCount,
    }
end

local function clonePlayerInventories(playerInventories)
    local cloned = {}

    for _, entry in ipairs(playerInventories or {}) do
        if type(entry) == 'table' and type(entry.UserId) == 'number' then
            table.insert(cloned, {
                UserId = entry.UserId,
                Inventory = cloneInventorySummary(entry.Inventory),
            })
        end
    end

    table.sort(cloned, function(left, right)
        return left.UserId < right.UserId
    end)

    return cloned
end

local function cloneUgcRuntimeProfile(runtimeProfile)
    if type(runtimeProfile) ~= 'table' then
        return nil
    end

    return {
        Id = runtimeProfile.Id,
        Name = runtimeProfile.Name,
        Presentation = type(runtimeProfile.Presentation) == 'table' and table.clone(
            runtimeProfile.Presentation
        ) or nil,
        Speed = runtimeProfile.Speed,
        SightRange = runtimeProfile.SightRange,
        PatrolSpeedMultiplier = runtimeProfile.PatrolSpeedMultiplier,
        SpawnOffset = runtimeProfile.SpawnOffset,
        Behaviors = type(runtimeProfile.Behaviors) == 'table' and table.clone(
            runtimeProfile.Behaviors
        ) or {},
        Effects = cloneArray(runtimeProfile.Effects),
    }
end

local function cloneUgcDiagnostics(diagnostics)
    if type(diagnostics) ~= 'table' then
        return nil
    end

    return {
        SkippedBehaviorIds = cloneArray(diagnostics.SkippedBehaviorIds),
        SkippedEffectIds = cloneArray(diagnostics.SkippedEffectIds),
        ClampedFields = cloneArray(diagnostics.ClampedFields),
    }
end

local function clonePendingUgcMonsterPayload(payload)
    if type(payload) ~= 'table' then
        return nil
    end

    return {
        OwnerUserId = payload.OwnerUserId,
        MonsterId = payload.MonsterId,
        MonsterName = payload.MonsterName,
        Seed = payload.Seed,
        RecipeHash = payload.RecipeHash,
        RuntimeProfile = cloneUgcRuntimeProfile(payload.RuntimeProfile),
        Diagnostics = cloneUgcDiagnostics(payload.Diagnostics),
    }
end

local function clonePosition(position)
    if typeof(position) == 'Vector3' then
        return {
            X = position.X,
            Y = position.Y,
            Z = position.Z,
        }
    end

    if type(position) == 'table' then
        return {
            X = position.X or position[1] or 0,
            Y = position.Y or position[2] or 0,
            Z = position.Z or position[3] or 0,
        }
    end

    return nil
end

local function cloneDropNodes(dropNodes)
    local cloned = {}

    for index, dropNode in ipairs(dropNodes or {}) do
        if type(dropNode) == 'table' then
            local entries = {}
            for entryIndex, itemEntry in ipairs(dropNode.Entries or {}) do
                entries[entryIndex] = cloneInventoryItem(itemEntry)
            end

            cloned[index] = {
                DropNodeId = dropNode.DropNodeId,
                Label = dropNode.Label,
                Position = clonePosition(dropNode.Position),
                Entries = entries,
            }
        end
    end

    return cloned
end

local function clonePersistentWorldState(persistentWorldState)
    local state = persistentWorldState or {}

    return {
        CollectedLootRoomIds = cloneArray(state.CollectedLootRoomIds),
        DropNodes = cloneDropNodes(state.DropNodes),
    }
end

local function cloneReturnedSummary(summary)
    if type(summary) ~= 'table' then
        return nil
    end

    return {
        UserId = summary.UserId,
        Name = summary.Name,
        ReturnReason = summary.ReturnReason,
        Value = summary.Value or 0,
        ItemCount = summary.ItemCount or 0,
        Weight = summary.Weight or 0,
        WasExtracted = summary.WasExtracted == true,
        WasSettled = summary.WasSettled == true,
        CountedInSettlement = summary.CountedInSettlement ~= false,
        LootItemCount = summary.LootItemCount or summary.MissionCount or summary.ItemCount or 0,
        ClueCount = summary.ClueCount or 0,
        ToolCount = summary.ToolCount or 0,
        MissionCount = summary.MissionCount or summary.LootItemCount or summary.ItemCount or 0,
    }
end

local function cloneReturnedSummaries(summaries)
    local cloned = {}

    for _, summary in ipairs(summaries or {}) do
        local clonedSummary = cloneReturnedSummary(summary)
        if clonedSummary ~= nil then
            table.insert(cloned, clonedSummary)
        end
    end

    return cloned
end

local function sortPlayers(players)
    table.sort(players, function(left, right)
        if left.UserId == right.UserId then
            return (left.Name or '') < (right.Name or '')
        end

        return left.UserId < right.UserId
    end)
end

local function sortSummaries(summaries)
    table.sort(summaries, function(left, right)
        if left.UserId == right.UserId then
            return (left.ReturnReason or '') < (right.ReturnReason or '')
        end

        return left.UserId < right.UserId
    end)
end

local function isPlaceholderSession(session)
    return session.SessionId == 'local-debug-camp'
        and session.CampAccessCode == 'local-debug-camp'
        and #session.PlayersInMaze == 0
        and #session.ReturnedPlayerSummaries == 0
end

local function updateMazeStatus(nextSession)
    if nextSession.MazeStatus == MAZE_STATUS.Completed then
        return
    end

    if nextSession.MazeAccessCode or #nextSession.PlayersInMaze > 0 then
        nextSession.MazeStatus = MAZE_STATUS.Active
        return
    end

    nextSession.MazeStatus = MAZE_STATUS.Idle
end

function CampMazeSessionContract.normalizeCampSession(session)
    local normalized = {
        SessionId = session and session.SessionId or 'local-debug-camp',
        CampAccessCode = session and session.CampAccessCode or 'local-debug-camp',
        SignalScope = session and session.SignalScope or nil,
        HostUserId = session and session.HostUserId or nil,
        GateOpen = session ~= nil and session.GateOpen == true or false,
        RoundStarted = session ~= nil and session.RoundStarted == true or false,
        DangerActive = session ~= nil and session.DangerActive == true or false,
        RoundStartTime = session and session.RoundStartTime or nil,
        RoundEndTime = session and session.RoundEndTime or nil,
        SettlementReason = session and session.SettlementReason or nil,
        SettlementTriggeredByUserId = session and session.SettlementTriggeredByUserId or nil,
        SettlementTriggeredByName = session and session.SettlementTriggeredByName or nil,
        MazeStatus = session and session.MazeStatus or MAZE_STATUS.Idle,
        MazeAccessCode = session and session.MazeAccessCode or nil,
        PlayersInMaze = cloneArray(session and session.PlayersInMaze or {}),
        ReturnedPlayerSummaries = cloneReturnedSummaries(
            session and session.ReturnedPlayerSummaries or {}
        ),
        SessionClosed = session ~= nil and session.SessionClosed == true or false,
        CurrentRound = session and session.CurrentRound or 1,
        MaxRounds = session and session.MaxRounds or DEFAULT_MAX_ROUNDS,
        BankedItemCount = session and session.BankedItemCount or 0,
        TargetItemCount = session and session.TargetItemCount or DEFAULT_TARGET_ITEM_COUNT,
        RoundOutcome = session and session.RoundOutcome or nil,
        SessionOutcome = session and session.SessionOutcome or nil,
        PersistentWorldState = clonePersistentWorldState(
            session and session.PersistentWorldState or nil
        ),
    }

    sortPlayers(normalized.PlayersInMaze)
    sortSummaries(normalized.ReturnedPlayerSummaries)
    normalized.SessionPhase = SessionPhase.resolveFromCampSession(normalized)

    return normalized
end

function CampMazeSessionContract.newCampSession(params)
    return CampMazeSessionContract.normalizeCampSession(params)
end

function CampMazeSessionContract.isPlayerInMaze(session, userId)
    for _, entry in ipairs(session and session.PlayersInMaze or {}) do
        if entry.UserId == userId then
            return true
        end
    end

    return false
end

function CampMazeSessionContract.hasReturnedSummary(session, userId)
    for _, entry in ipairs(session and session.ReturnedPlayerSummaries or {}) do
        if entry.UserId == userId then
            return true
        end
    end

    return false
end

function CampMazeSessionContract.reconcileIncomingCampSession(currentSession, incomingSession)
    local normalizedCurrent = CampMazeSessionContract.normalizeCampSession(currentSession)
    local normalizedIncoming = CampMazeSessionContract.normalizeCampSession(incomingSession)

    if isPlaceholderSession(normalizedCurrent) then
        return normalizedIncoming, true
    end

    local sameSession = normalizedCurrent.SessionId == normalizedIncoming.SessionId
        and normalizedCurrent.CampAccessCode == normalizedIncoming.CampAccessCode
    if sameSession then
        return normalizedIncoming, true
    end

    return normalizedCurrent, false
end

function CampMazeSessionContract.buildReturnSummary(params)
    return {
        UserId = params.UserId,
        Name = params.Name,
        ReturnReason = params.ReturnReason,
        Value = params.Value or 0,
        ItemCount = params.ItemCount or 0,
        Weight = params.Weight or 0,
        WasExtracted = params.WasExtracted == true,
        WasSettled = params.WasSettled == true,
        CountedInSettlement = params.CountedInSettlement ~= false,
        LootItemCount = params.LootItemCount or params.MissionCount or params.ItemCount or 0,
        ClueCount = params.ClueCount or 0,
        ToolCount = params.ToolCount or 0,
        MissionCount = params.MissionCount or params.LootItemCount or params.ItemCount or 0,
    }
end

function CampMazeSessionContract.assignHost(session, hostUserId)
    local nextSession = CampMazeSessionContract.normalizeCampSession(session)
    nextSession.HostUserId = if type(hostUserId) == 'number' then hostUserId else nil
    nextSession.SessionPhase = SessionPhase.resolveFromCampSession(nextSession)
    return nextSession
end

function CampMazeSessionContract.markRoundStarted(session, params)
    local nextSession = CampMazeSessionContract.normalizeCampSession(session)
    local resolved = params or {}

    nextSession.HostUserId = resolved.HostUserId or nextSession.HostUserId
    nextSession.GateOpen = true
    nextSession.RoundStarted = true
    nextSession.DangerActive = resolved.DangerActive ~= false
    nextSession.RoundStartTime = resolved.RoundStartTime
    nextSession.RoundEndTime = resolved.RoundEndTime
    nextSession.SettlementReason = nil
    nextSession.SettlementTriggeredByUserId = nil
    nextSession.SettlementTriggeredByName = nil
    nextSession.RoundOutcome = nil
    nextSession.SessionClosed = false
    nextSession.SessionPhase = SessionPhase.resolveFromCampSession(nextSession)
    return nextSession
end

function CampMazeSessionContract.markSettlementTriggered(session, params)
    local nextSession = CampMazeSessionContract.normalizeCampSession(session)
    local resolved = params or {}

    nextSession.GateOpen = false
    nextSession.RoundStarted = false
    nextSession.DangerActive = false
    nextSession.SettlementReason = resolved.SettlementReason or 'settlement'
    nextSession.SettlementTriggeredByUserId = resolved.TriggeredByUserId
    nextSession.SettlementTriggeredByName = resolved.TriggeredByName
    nextSession.RoundOutcome = resolved.RoundOutcome or nextSession.RoundOutcome
    nextSession.SessionPhase = SessionPhase.resolveFromCampSession(nextSession)
    return nextSession
end

function CampMazeSessionContract.markPlayerEntered(session, player)
    local nextSession = CampMazeSessionContract.normalizeCampSession(session)
    local nextPlayers = {}

    for _, entry in ipairs(nextSession.PlayersInMaze) do
        if entry.UserId ~= player.UserId then
            table.insert(nextPlayers, entry)
        end
    end

    table.insert(nextPlayers, {
        UserId = player.UserId,
        Name = player.Name,
    })
    sortPlayers(nextPlayers)
    nextSession.PlayersInMaze = nextPlayers

    local nextSummaries = {}
    for _, entry in ipairs(nextSession.ReturnedPlayerSummaries) do
        if entry.UserId ~= player.UserId then
            table.insert(nextSummaries, entry)
        end
    end
    sortSummaries(nextSummaries)
    nextSession.ReturnedPlayerSummaries = nextSummaries

    nextSession.MazeStatus = MAZE_STATUS.Active
    nextSession.SessionPhase = SessionPhase.resolveFromCampSession(nextSession)

    return nextSession
end

function CampMazeSessionContract.prunePlayer(session, userId, options)
    local nextSession = CampMazeSessionContract.normalizeCampSession(session)
    local preserveMazeEntry = options and options.PreserveMazeEntry == true or false
    local preserveReturnSummary = options and options.PreserveReturnSummary == true or false
    local nextPlayers = {}

    for _, entry in ipairs(nextSession.PlayersInMaze) do
        if entry.UserId ~= userId or preserveMazeEntry then
            table.insert(nextPlayers, entry)
        end
    end

    nextSession.PlayersInMaze = nextPlayers

    local nextSummaries = {}
    for _, entry in ipairs(nextSession.ReturnedPlayerSummaries) do
        if entry.UserId ~= userId or preserveReturnSummary then
            table.insert(nextSummaries, entry)
        end
    end

    sortPlayers(nextPlayers)
    sortSummaries(nextSummaries)
    nextSession.ReturnedPlayerSummaries = nextSummaries
    updateMazeStatus(nextSession)
    nextSession.SessionPhase = SessionPhase.resolveFromCampSession(nextSession)

    return nextSession
end

function CampMazeSessionContract.applyReturn(session, summary, mazeCompleted)
    local nextSession = CampMazeSessionContract.normalizeCampSession(session)
    local nextPlayers = {}

    for _, entry in ipairs(nextSession.PlayersInMaze) do
        if entry.UserId ~= summary.UserId then
            table.insert(nextPlayers, entry)
        end
    end

    nextSession.PlayersInMaze = nextPlayers

    local nextSummaries = {}
    for _, entry in ipairs(nextSession.ReturnedPlayerSummaries) do
        if entry.UserId ~= summary.UserId then
            table.insert(nextSummaries, entry)
        end
    end

    table.insert(nextSummaries, cloneReturnedSummary(summary))
    sortPlayers(nextPlayers)
    sortSummaries(nextSummaries)
    nextSession.ReturnedPlayerSummaries = nextSummaries

    if mazeCompleted then
        nextSession.MazeStatus = MAZE_STATUS.Completed
        nextSession.PlayersInMaze = {}
    else
        updateMazeStatus(nextSession)
    end

    nextSession.SessionPhase = SessionPhase.resolveFromCampSession(nextSession)

    return nextSession
end

function CampMazeSessionContract.recordBankedItems(session, itemCount)
    local nextSession = CampMazeSessionContract.normalizeCampSession(session)
    local count = math.max(0, math.floor(tonumber(itemCount) or 0))
    nextSession.BankedItemCount += count
    nextSession.SessionPhase = SessionPhase.resolveFromCampSession(nextSession)
    return nextSession
end

function CampMazeSessionContract.setPersistentWorldState(session, persistentWorldState)
    local nextSession = CampMazeSessionContract.normalizeCampSession(session)
    nextSession.PersistentWorldState = clonePersistentWorldState(persistentWorldState)
    nextSession.SessionPhase = SessionPhase.resolveFromCampSession(nextSession)
    return nextSession
end

function CampMazeSessionContract.markRoundOutcome(session, roundOutcome)
    local nextSession = CampMazeSessionContract.normalizeCampSession(session)
    nextSession.RoundOutcome = roundOutcome
    nextSession.SessionPhase = SessionPhase.resolveFromCampSession(nextSession)
    return nextSession
end

function CampMazeSessionContract.markSessionOutcome(session, sessionOutcome)
    local nextSession = CampMazeSessionContract.normalizeCampSession(session)
    nextSession.SessionOutcome = sessionOutcome
    nextSession.SessionPhase = SessionPhase.resolveFromCampSession(nextSession)
    return nextSession
end

function CampMazeSessionContract.resetForNextRound(session)
    local nextSession = CampMazeSessionContract.normalizeCampSession(session)

    nextSession.GateOpen = false
    nextSession.RoundStarted = false
    nextSession.DangerActive = false
    nextSession.RoundStartTime = nil
    nextSession.RoundEndTime = nil
    nextSession.SettlementReason = nil
    nextSession.SettlementTriggeredByUserId = nil
    nextSession.SettlementTriggeredByName = nil
    nextSession.MazeStatus = MAZE_STATUS.Idle
    nextSession.MazeAccessCode = nil
    nextSession.PlayersInMaze = {}
    nextSession.ReturnedPlayerSummaries = {}
    nextSession.RoundOutcome = nil
    nextSession.SessionClosed = false

    if nextSession.SessionOutcome == nil then
        nextSession.CurrentRound = math.min(nextSession.CurrentRound + 1, nextSession.MaxRounds)
    end

    nextSession.SessionPhase = SessionPhase.resolveFromCampSession(nextSession)

    return nextSession
end

function CampMazeSessionContract.buildLobbyToRunTeleportData(params)
    return {
        SessionConfig = cloneTable(params.SessionConfig),
        CampSession = CampMazeSessionContract.newCampSession({
            SessionId = params.SessionId,
            CampAccessCode = params.CampAccessCode,
            SignalScope = params.SignalScope,
            GateOpen = false,
            RoundStarted = false,
            DangerActive = false,
            MazeStatus = MAZE_STATUS.Idle,
            MazeAccessCode = nil,
            PlayersInMaze = {},
            ReturnedPlayerSummaries = {},
            CurrentRound = params.CurrentRound or 1,
            MaxRounds = params.MaxRounds or DEFAULT_MAX_ROUNDS,
            BankedItemCount = params.BankedItemCount or 0,
            TargetItemCount = params.TargetItemCount or DEFAULT_TARGET_ITEM_COUNT,
            PersistentWorldState = params.PersistentWorldState,
        }),
        Entry = {
            Kind = 'LobbyLaunch',
        },
        PlayerInventories = {},
    }
end

function CampMazeSessionContract.buildLobbyToCampTeleportData(params)
    return CampMazeSessionContract.buildLobbyToRunTeleportData(params)
end

function CampMazeSessionContract.closeCampSession(session)
    local nextSession = CampMazeSessionContract.normalizeCampSession(session)
    nextSession.SessionClosed = true
    nextSession.SessionPhase = SessionPhase.SessionClosed
    return nextSession
end

function CampMazeSessionContract.buildRunToMazeTeleportData(params)
    local playerInventories = {}
    if
        type(params.EnteringPlayer) == 'table'
        and type(params.EnteringPlayer.UserId) == 'number'
    then
        table.insert(playerInventories, {
            UserId = params.EnteringPlayer.UserId,
            Inventory = cloneInventorySummary(params.PlayerInventory),
        })
    end

    return {
        SessionConfig = cloneTable(params.SessionConfig),
        CampSession = CampMazeSessionContract.normalizeCampSession(params.CampSession),
        MazeSession = {
            SessionId = params.CampSession.SessionId,
            CampAccessCode = params.CampSession.CampAccessCode,
            MazeAccessCode = params.CampSession.MazeAccessCode,
            EntryReason = params.EntryReason or 'camp_gate',
            EnteringPlayer = table.clone(params.EnteringPlayer),
            PendingUgcMonsterPayload = clonePendingUgcMonsterPayload(
                params.PendingUgcMonsterPayload
            ),
        },
        PlayerInventories = clonePlayerInventories(playerInventories),
    }
end

function CampMazeSessionContract.buildCampToMazeTeleportData(params)
    return CampMazeSessionContract.buildRunToMazeTeleportData(params)
end

function CampMazeSessionContract.buildMazeToRunTeleportData(params)
    return {
        SessionConfig = cloneTable(params.SessionConfig),
        CampSession = CampMazeSessionContract.normalizeCampSession(params.CampSession),
        MazeReturn = {
            MazeCompleted = params.MazeCompleted == true,
            Summaries = cloneReturnedSummaries(params.Summaries),
        },
        PlayerInventories = clonePlayerInventories(params.PlayerInventories),
    }
end

function CampMazeSessionContract.buildMazeToCampTeleportData(params)
    return CampMazeSessionContract.buildMazeToRunTeleportData(params)
end

function CampMazeSessionContract.findReturnSummary(teleportData, userId)
    local mazeReturn = teleportData and teleportData.MazeReturn
    if type(mazeReturn) ~= 'table' then
        return nil
    end

    for _, summary in ipairs(mazeReturn.Summaries or {}) do
        if summary.UserId == userId then
            return cloneReturnedSummary(summary)
        end
    end

    return nil
end

function CampMazeSessionContract.findPlayerInventory(teleportData, userId)
    local playerInventories = teleportData and teleportData.PlayerInventories
    if type(playerInventories) ~= 'table' then
        return nil
    end

    for _, entry in ipairs(playerInventories) do
        if entry.UserId == userId then
            return cloneInventorySummary(entry.Inventory)
        end
    end

    return nil
end

function CampMazeSessionContract.findPendingUgcMonsterPayload(teleportData)
    local mazeSession = teleportData and teleportData.MazeSession
    if type(mazeSession) ~= 'table' then
        return nil
    end

    return clonePendingUgcMonsterPayload(mazeSession.PendingUgcMonsterPayload)
end

CampMazeSessionContract.MazeStatus = MAZE_STATUS
CampMazeSessionContract.SessionPhase = SessionPhase

return CampMazeSessionContract
