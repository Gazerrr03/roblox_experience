return function()
    local ReplicatedStorage = game:GetService('ReplicatedStorage')
    local shared = require(ReplicatedStorage:WaitForChild('Packages'):WaitForChild('Shared'))
    local SessionPhase = shared.Session.SessionPhase

    assert(SessionPhase.resolveFromCampSession({
        GateOpen = false,
        MazeStatus = 'idle',
    }) == SessionPhase.RunPrep, 'Closed temple sessions should resolve to RunPrep')

    assert(
        SessionPhase.resolveFromCampSession({
            GateOpen = true,
            MazeStatus = 'idle',
        }) == SessionPhase.RunField,
        'Open temple sessions without an active maze should resolve to RunField'
    )

    assert(SessionPhase.resolveFromCampSession({
        GateOpen = true,
        MazeStatus = 'active',
        PlayersInMaze = {
            { UserId = 1, Name = 'Scout' },
        },
    }) == SessionPhase.MazeActive, 'Active maze sessions should resolve to MazeActive')

    assert(SessionPhase.resolveFromCampSession({
        GateOpen = true,
        MazeStatus = 'completed',
        ReturnedPlayerSummaries = {
            { UserId = 1, ReturnReason = 'settled' },
        },
    }) == SessionPhase.Debrief, 'Completed or returned sessions should resolve to Debrief')

    assert(
        SessionPhase.resolveFromCampSession({
            SessionClosed = true,
        }) == SessionPhase.SessionClosed,
        'Explicitly closed sessions should resolve to SessionClosed'
    )
end
