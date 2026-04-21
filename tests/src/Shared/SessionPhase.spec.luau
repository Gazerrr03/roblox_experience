return function()
    local ReplicatedStorage = game:GetService('ReplicatedStorage')
    local shared = require(ReplicatedStorage:WaitForChild('Packages'):WaitForChild('Shared'))
    local SessionPhase = shared.Session.SessionPhase

    assert(
        SessionPhase.resolveFromCampSession({}) == SessionPhase.RunPrep,
        'Default session should resolve to RunPrep'
    )

    assert(SessionPhase.resolveFromCampSession({
        GateOpen = true,
        CurrentRound = 1,
        MaxRounds = 5,
    }) == SessionPhase.RunField, 'Open ship state should resolve to RunField')

    assert(SessionPhase.resolveFromCampSession({
        MazeStatus = 'active',
        PlayersInMaze = {
            { UserId = 1, Name = 'Scout' },
        },
        CurrentRound = 1,
        MaxRounds = 5,
    }) == SessionPhase.MazeActive, 'Active maze state should resolve to MazeActive')

    assert(
        SessionPhase.resolveFromCampSession({
            SettlementReason = 'timeout',
            RoundOutcome = 'timeout',
            CurrentRound = 2,
            MaxRounds = 5,
        }) == SessionPhase.RunIntermission,
        'Mid-mission settlement should resolve to RunIntermission'
    )

    assert(SessionPhase.resolveFromCampSession({
        SessionOutcome = 'failure',
        CurrentRound = 5,
        MaxRounds = 5,
    }) == SessionPhase.FinalDebrief, 'Resolved mission outcomes should resolve to FinalDebrief')

    assert(SessionPhase.resolveFromCampSession({
        SettlementReason = 'timeout',
        CurrentRound = 5,
        MaxRounds = 5,
    }) == SessionPhase.FinalDebrief, 'Final-round settlement should resolve to FinalDebrief')

    assert(
        SessionPhase.resolveFromCampSession({
            SessionClosed = true,
        }) == SessionPhase.SessionClosed,
        'Explicitly closed sessions should resolve to SessionClosed'
    )
end
