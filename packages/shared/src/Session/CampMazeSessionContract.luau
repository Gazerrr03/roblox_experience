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
    local normalized = CampMazeSessionContract.normalizeCampSession(session)

    for _, entry in ipairs(normalized.ReturnedPlayerSummaries) do
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

function CampMazeSessionContract.buildLobbyToCampTeleportData(params)
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
    }
end

function CampMazeSessionContract.buildCampToMazeTeleportData(params)
    return {
        SessionConfig = cloneTable(params.SessionConfig),
        CampSession = CampMazeSessionContract.normalizeCampSession(params.CampSession),
        MazeSession = {
            SessionId = params.CampSession.SessionId,
            CampAccessCode = params.CampSession.CampAccessCode,
            MazeAccessCode = params.CampSession.MazeAccessCode,
            EntryReason = params.EntryReason or 'camp_gate',
            EnteringPlayer = table.clone(params.EnteringPlayer),
        },
    }
end

function CampMazeSessionContract.buildMazeToCampTeleportData(params)
    return {
        SessionConfig = cloneTable(params.SessionConfig),
        CampSession = CampMazeSessionContract.normalizeCampSession(params.CampSession),
        MazeReturn = {
            MazeCompleted = params.MazeCompleted == true,
            Summaries = cloneArray(params.Summaries),
        },
    }
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

CampMazeSessionContract.MazeStatus = MAZE_STATUS

return CampMazeSessionContract
