local RunSnapshotBuilder = {}

function RunSnapshotBuilder.buildForPlayer(service, player, mazeEntryAvailability)
    local playerSummary = service.PlayerService:getSummary(player)
    local playerStateSummary = if playerSummary and playerSummary.PlayerState ~= nil
        then playerSummary.PlayerState
        else service.PlayerStateService:getSummary(player)
    local bookSnapshot = service:_getBookSnapshot()
    local mazeEntry = mazeEntryAvailability or service:_evaluateMazeEntry(player)

    return {
        IsLaunched = service.IsLaunched,
        GamePhase = service.GamePhase,
        Status = service.Status,
        BuildFingerprint = service.BuildFingerprint,
        Area = service:_getPlayerArea(player),
        GateOpen = service.GateOpen,
        HostUserId = service.CampSession.HostUserId,
        IsHost = service.CampSession.HostUserId == player.UserId,
        RoundStarted = service.CampSession.RoundStarted == true,
        DangerActive = service.CampSession.DangerActive == true,
        RoundTimeRemainingSeconds = bookSnapshot.RoundTimeRemainingSeconds,
        SettlementReason = service.CampSession.SettlementReason,
        Objective = service:_getObjectiveFor(player),
        SessionId = service.CampSession.SessionId,
        SessionPhase = service.CampSession.SessionPhase,
        MazeStatus = service.CampSession.MazeStatus,
        PlayersInMaze = service:_getActiveMazeRoster(),
        ReturnedPlayerSummaries = service:_getReturnedSummaries(),
        MazeEntryMode = mazeEntry.Mode,
        MazeEntryReason = mazeEntry.Reason,
        MazeEntryReasonCode = mazeEntry.ReasonCode,
        CanEnterMaze = mazeEntry.Mode == 'Teleport',
        TeamPages = bookSnapshot.TeamPages,
        BookGoalAmount = bookSnapshot.BookGoalAmount,
        BookGoalProgress = bookSnapshot.BookGoalProgress,
        BookGoalReached = bookSnapshot.BookGoalReached,
        Inventory = service.InventoryService:getSummary(player),
        Movement = service:_getMovementSummaryFor(player),
        ControlState = service.ControlStateService:getSummary(player),
        PlayerState = playerStateSummary,
        Roster = service:_buildRoster(),
    }
end

return RunSnapshotBuilder
