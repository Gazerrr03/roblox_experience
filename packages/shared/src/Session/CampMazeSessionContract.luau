local CampMazeSessionContract = {}

local MAZE_STATUS = {
    Idle = 'idle',
    Active = 'active',
    Completed = 'completed',
}

local function cloneArray(list)
    local result = {}

    for index, entry in ipairs(list or {}) do
        result[index] = table.clone(entry)
    end

    return result
end

local function cloneTable(input)
    return table.clone(input or {})
end

local function cloneLightConfig(lightConfig)
    if type(lightConfig) ~= 'table' then
        return nil
    end

    return {
        Brightness = lightConfig.Brightness,
        Range = lightConfig.Range,
        Color = lightConfig.Color,
    }
end

local function cloneInventoryItem(itemEntry)
    if type(itemEntry) ~= 'table' then
        return nil
    end

    return {
        InstanceId = itemEntry.InstanceId,
        Id = itemEntry.Id,
        Name = itemEntry.Name,
        Weight = itemEntry.Weight,
        Value = itemEntry.Value,
        Color = itemEntry.Color,
        Light = cloneLightConfig(itemEntry.Light),
        Description = itemEntry.Description,
        IconAssetId = itemEntry.IconAssetId,
        ToolTemplateName = itemEntry.ToolTemplateName,
        ToolCategory = itemEntry.ToolCategory,
        StateModel = itemEntry.StateModel,
        InitialState = itemEntry.InitialState,
        CurrentState = itemEntry.CurrentState,
        ConsumePerUse = itemEntry.ConsumePerUse,
        CooldownSeconds = itemEntry.CooldownSeconds,
        LastUsedAt = itemEntry.LastUsedAt,
        SwingRange = itemEntry.SwingRange,
        SwingArcDegrees = itemEntry.SwingArcDegrees,
        KnockbackStrength = itemEntry.KnockbackStrength,
        MeleeDamage = itemEntry.MeleeDamage,
        HealHealthPips = itemEntry.HealHealthPips,
    }
end

local function cloneInventorySummary(summary)
    if type(summary) ~= 'table' then
        return nil
    end

    local backpackItems = {}
    for index, itemEntry in ipairs(summary.BackpackItems or {}) do
        backpackItems[index] = cloneInventoryItem(itemEntry)
    end

    return {
        Capacity = summary.Capacity or 0,
        Weight = summary.Weight or 0,
        Count = summary.Count or 0,
        BackpackCount = summary.BackpackCount or #backpackItems,
        HeldCount = summary.HeldCount or (summary.HeldItem and 1 or 0),
        Value = summary.Value or 0,
        BackpackItems = backpackItems,
        HeldItem = cloneInventoryItem(summary.HeldItem),
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

    if nextSession.MazeAccessCode then
        nextSession.MazeStatus = MAZE_STATUS.Active
        return
    end

    nextSession.MazeStatus = MAZE_STATUS.Idle
end

function CampMazeSessionContract.normalizeCampSession(session)
    local normalized = {
        SessionId = session and session.SessionId or 'local-debug-camp',
        CampAccessCode = session and session.CampAccessCode or 'local-debug-camp',
        GateOpen = session ~= nil and session.GateOpen == true or false,
        MazeStatus = session and session.MazeStatus or MAZE_STATUS.Idle,
        MazeAccessCode = session and session.MazeAccessCode or nil,
        PlayersInMaze = cloneArray(session and session.PlayersInMaze or {}),
        ReturnedPlayerSummaries = cloneArray(session and session.ReturnedPlayerSummaries or {}),
    }

    sortPlayers(normalized.PlayersInMaze)
    sortSummaries(normalized.ReturnedPlayerSummaries)

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
    }
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

    table.insert(nextSummaries, table.clone(summary))
    sortPlayers(nextPlayers)
    sortSummaries(nextSummaries)
    nextSession.ReturnedPlayerSummaries = nextSummaries

    if mazeCompleted then
        nextSession.MazeStatus = MAZE_STATUS.Completed
        nextSession.PlayersInMaze = {}
    else
        updateMazeStatus(nextSession)
    end

    return nextSession
end

function CampMazeSessionContract.buildLobbyToRunTeleportData(params)
    return {
        SessionConfig = cloneTable(params.SessionConfig),
        CampSession = CampMazeSessionContract.newCampSession({
            SessionId = params.SessionId,
            CampAccessCode = params.CampAccessCode,
            GateOpen = false,
            MazeStatus = MAZE_STATUS.Idle,
            MazeAccessCode = nil,
            PlayersInMaze = {},
            ReturnedPlayerSummaries = {},
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
            Summaries = cloneArray(params.Summaries),
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
            return summary
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

return CampMazeSessionContract
