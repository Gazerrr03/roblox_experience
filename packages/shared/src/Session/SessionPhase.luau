local SessionPhase = table.freeze({
    RunPrep = 'RunPrep',
    RunField = 'RunField',
    MazeActive = 'MazeActive',
    RunIntermission = 'RunIntermission',
    FinalDebrief = 'FinalDebrief',
    SessionClosed = 'SessionClosed',
    Debrief = 'FinalDebrief',
})

function SessionPhase.resolveFromCampSession(session)
    local normalizedSession = if type(session) == 'table' then session else {}
    local mazeStatus = normalizedSession.MazeStatus
    local gateOpen = normalizedSession.GateOpen == true
    local roundStarted = normalizedSession.RoundStarted == true
    local dangerActive = normalizedSession.DangerActive == true
    local settlementReason = normalizedSession.SettlementReason
    local roundOutcome = normalizedSession.RoundOutcome
    local sessionOutcome = normalizedSession.SessionOutcome
    local returnedSummaries = normalizedSession.ReturnedPlayerSummaries or {}
    local playersInMaze = normalizedSession.PlayersInMaze or {}
    local currentRound = normalizedSession.CurrentRound or 1
    local maxRounds = normalizedSession.MaxRounds or currentRound

    if normalizedSession.SessionClosed == true then
        return SessionPhase.SessionClosed
    end

    if mazeStatus == 'active' or #playersInMaze > 0 then
        return SessionPhase.MazeActive
    end

    if type(sessionOutcome) == 'string' and sessionOutcome ~= '' then
        return SessionPhase.FinalDebrief
    end

    if type(settlementReason) == 'string' and settlementReason ~= '' then
        if currentRound >= maxRounds then
            return SessionPhase.FinalDebrief
        end

        return SessionPhase.RunIntermission
    end

    if type(roundOutcome) == 'string' and roundOutcome ~= '' then
        if currentRound >= maxRounds then
            return SessionPhase.FinalDebrief
        end

        return SessionPhase.RunIntermission
    end

    if mazeStatus == 'completed' or #returnedSummaries > 0 then
        if currentRound >= maxRounds then
            return SessionPhase.FinalDebrief
        end

        return SessionPhase.RunIntermission
    end

    if gateOpen or roundStarted or dangerActive then
        return SessionPhase.RunField
    end

    return SessionPhase.RunPrep
end

return SessionPhase
