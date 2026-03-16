return function()
    local ReplicatedStorage = game:GetService('ReplicatedStorage')
    local shared = require(ReplicatedStorage:WaitForChild('Packages'):WaitForChild('Shared'))
    local contract = shared.Session.CampMazeSessionContract

    local campSession = contract.newCampSession({
        SessionId = 'camp-session-1',
        CampAccessCode = 'camp-access-code',
    })

    assert(
        campSession.MazeStatus == contract.MazeStatus.Idle,
        'New camp sessions should start idle'
    )

    local entered = contract.markPlayerEntered(campSession, {
        UserId = 42,
        Name = 'Scout',
    })
    entered.MazeAccessCode = 'maze-access-code'

    assert(
        entered.MazeStatus == contract.MazeStatus.Active,
        'Entering the maze should activate the maze status'
    )
    assert(#entered.PlayersInMaze == 1, 'Entering should track the player inside the maze')

    local campToMaze = contract.buildCampToMazeTeleportData({
        SessionConfig = {
            Seed = 12345,
            Quota = 120,
            RunDurationSeconds = 180,
            InventoryCapacity = 5,
        },
        CampSession = entered,
        EnteringPlayer = {
            UserId = 42,
            Name = 'Scout',
        },
        EntryReason = 'maze_gate',
    })

    assert(
        campToMaze.MazeSession.MazeAccessCode == 'maze-access-code',
        'Maze access code should flow into the maze teleport payload'
    )
    assert(
        campToMaze.CampSession.SessionId == 'camp-session-1',
        'Camp session id should survive camp -> maze teleport shaping'
    )

    local earlyReturn = contract.buildReturnSummary({
        UserId = 42,
        Name = 'Scout',
        ReturnReason = 'early_return',
        Value = 18,
        ItemCount = 1,
        Weight = 2,
    })
    local resumed = contract.applyReturn(entered, earlyReturn, false)

    assert(
        #resumed.PlayersInMaze == 0,
        'Returned players should be removed from the in-maze roster'
    )
    assert(
        resumed.MazeStatus == contract.MazeStatus.Active,
        'Maze stays active when it was opened but not completed'
    )
    assert(
        resumed.ReturnedPlayerSummaries[1].Value == 18,
        'Return summaries should preserve collected value'
    )
    assert(
        contract.hasReturnedSummary(resumed, 42) == true,
        'Returned players should remain discoverable through the summary helper'
    )

    local reentered = contract.markPlayerEntered(resumed, {
        UserId = 42,
        Name = 'Scout',
    })
    assert(
        contract.hasReturnedSummary(reentered, 42) == false,
        "Re-entering the maze should clear that player's stale return summary"
    )
    assert(
        contract.isPlayerInMaze(reentered, 42) == true,
        'Re-entering the maze should put the player back into the active maze roster'
    )

    local preservedMazeEntry = contract.prunePlayer(entered, 42, {
        PreserveMazeEntry = true,
    })
    assert(
        contract.isPlayerInMaze(preservedMazeEntry, 42) == true,
        'Camp-side disconnect cleanup should preserve active maze entries'
    )

    local prunedReturn = contract.prunePlayer(resumed, 42)
    assert(
        contract.hasReturnedSummary(prunedReturn, 42) == false,
        'Disconnect cleanup should clear stale returned summaries by default'
    )

    local preservedReturn = contract.prunePlayer(resumed, 42, {
        PreserveReturnSummary = true,
    })
    assert(
        contract.hasReturnedSummary(preservedReturn, 42) == true,
        'Maze-side cleanup should be able to keep a recorded return summary'
    )

    local settled = contract.buildReturnSummary({
        UserId = 7,
        Name = 'Lead',
        ReturnReason = 'settled',
        Value = 42,
        ItemCount = 2,
        Weight = 4,
        WasExtracted = true,
        WasSettled = true,
    })
    local completed = contract.applyReturn(
        contract.markPlayerEntered(resumed, {
            UserId = 7,
            Name = 'Lead',
        }),
        settled,
        true
    )

    assert(
        completed.MazeStatus == contract.MazeStatus.Completed,
        'Completed maze sessions should lock into completed status'
    )
    assert(
        #completed.PlayersInMaze == 0,
        'Completed maze sessions should not retain active maze players'
    )

    local mazeToCamp = contract.buildMazeToCampTeleportData({
        SessionConfig = {
            Seed = 12345,
            Quota = 120,
            RunDurationSeconds = 180,
            InventoryCapacity = 5,
        },
        CampSession = completed,
        Summaries = completed.ReturnedPlayerSummaries,
        MazeCompleted = true,
    })

    local returnedScout = contract.findReturnSummary(mazeToCamp, 42)
    local returnedLead = contract.findReturnSummary(mazeToCamp, 7)

    assert(
        returnedScout.ReturnReason == 'early_return',
        'findReturnSummary should locate the matching player summary'
    )
    assert(
        returnedLead.WasSettled == true,
        'Maze return payload should preserve settlement summaries'
    )

    local reconciledPlaceholder, placeholderAccepted = contract.reconcileIncomingCampSession(
        contract.newCampSession({}),
        contract.newCampSession({
            SessionId = 'camp-session-2',
            CampAccessCode = 'camp-access-code-2',
            MazeAccessCode = 'maze-access-code-2',
        })
    )
    assert(
        placeholderAccepted == true and reconciledPlaceholder.SessionId == 'camp-session-2',
        'Placeholder camp sessions should accept the first real incoming session'
    )

    local reconciledSameSession, sameSessionAccepted = contract.reconcileIncomingCampSession(
        entered,
        contract.newCampSession({
            SessionId = 'camp-session-1',
            CampAccessCode = 'camp-access-code',
            MazeAccessCode = 'maze-access-code',
        })
    )
    assert(
        sameSessionAccepted == true and reconciledSameSession.CampAccessCode == 'camp-access-code',
        'Matching incoming session payloads should be accepted'
    )

    local rejectedSession, mismatchedAccepted = contract.reconcileIncomingCampSession(
        entered,
        contract.newCampSession({
            SessionId = 'camp-session-other',
            CampAccessCode = 'camp-access-code-other',
        })
    )
    assert(
        mismatchedAccepted == false and rejectedSession.SessionId == entered.SessionId,
        'Mismatched incoming sessions should not overwrite the current authority'
    )
end
