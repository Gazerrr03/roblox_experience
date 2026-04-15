local RunSnapshotBuilder = {}

function RunSnapshotBuilder.buildForPlayer(service, player, mazeEntryAvailability)
    local playerSummary = service.PlayerService:getSummary(player)
    local playerStateSummary = if playerSummary and playerSummary.PlayerState ~= nil
        then playerSummary.PlayerState
        else service.PlayerStateService:getSummary(player)
    local bookSnapshot = service:_getBookSnapshot()

    return {
        IsLaunched = service.IsLaunched,
        Status = service.Status,
        BuildFingerprint = service.BuildFingerprint,
        Area = service:_getPlayerArea(player),
        GateOpen = service.GateOpen,
        Objective = service:_getObjectiveFor(player),
        SessionId = service.CampSession.SessionId,
        SessionPhase = service.CampSession.SessionPhase,
        MazeStatus = service.CampSession.MazeStatus,
        PlayersInMaze = service:_getActiveMazeRoster(),
        ReturnedPlayerSummaries = service:_getReturnedSummaries(),
        MazeEntryMode = mazeEntryAvailability.Mode,
        MazeEntryReason = mazeEntryAvailability.Reason,
        MazeEntryReasonCode = mazeEntryAvailability.ReasonCode,
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
