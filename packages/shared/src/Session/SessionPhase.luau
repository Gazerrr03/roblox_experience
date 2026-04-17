local SessionPhase = table.freeze({
    RunPrep = 'RunPrep',
    RunField = 'RunField',
    MazeActive = 'MazeActive',
    Debrief = 'Debrief',
    SessionClosed = 'SessionClosed',
})

function SessionPhase.resolveFromCampSession(session)
    local normalizedSession = if type(session) == 'table' then session else {}
    local mazeStatus = normalizedSession.MazeStatus
    local gateOpen = normalizedSession.GateOpen == true
    local roundStarted = normalizedSession.RoundStarted == true
    local dangerActive = normalizedSession.DangerActive == true
    local settlementReason = normalizedSession.SettlementReason
    local returnedSummaries = normalizedSession.ReturnedPlayerSummaries or {}
    local playersInMaze = normalizedSession.PlayersInMaze or {}

    if normalizedSession.SessionClosed == true then
        return SessionPhase.SessionClosed
    end

    if mazeStatus == 'active' or #playersInMaze > 0 then
        return SessionPhase.MazeActive
    end

    if type(settlementReason) == 'string' and settlementReason ~= '' then
        return SessionPhase.Debrief
    end

    if mazeStatus == 'completed' or #returnedSummaries > 0 then
        return SessionPhase.Debrief
    end

    if gateOpen or roundStarted or dangerActive then
        return SessionPhase.RunField
    end

    return SessionPhase.RunPrep
end

return SessionPhase
