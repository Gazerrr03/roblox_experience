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
end
