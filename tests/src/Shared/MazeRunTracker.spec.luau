return function()
    local ReplicatedStorage = game:GetService('ReplicatedStorage')
    local shared = require(ReplicatedStorage:WaitForChild('Packages'):WaitForChild('Shared'))
    local gameplay = require(ReplicatedStorage:WaitForChild('Packages'):WaitForChild('Gameplay'))
    local tracker = gameplay.Session.MazeRunTracker.new()

    assert(tracker:addPlayer({ UserId = 10, Name = 'Alpha' }) == true, 'First player should join')
    assert(tracker:addPlayer({ UserId = 20, Name = 'Bravo' }) == true, 'Second player should join')
    assert(tracker:getActiveCount() == 2, 'Both players should start active')

    local expeditionStarted, expeditionReason = tracker:beginExpedition()
    assert(expeditionStarted == true, expeditionReason or 'Expedition should start from camp')
    assert(
        tracker:getState() == shared.Enums.RunState.Expedition,
        'Tracker should transition into expedition'
    )

    local earlyReturnRecorded, earlyReturnReason = tracker:recordReturn({
        UserId = 10,
        Name = 'Alpha',
        ReturnReason = 'early_return',
        Value = 18,
        ItemCount = 1,
        Weight = 2,
    })
    assert(earlyReturnRecorded == true, earlyReturnReason or 'Early return should be recorded')
    assert(
        tracker:isPlayerActive(10) == false,
        'Returned players should leave the active maze roster'
    )
    assert(
        tracker:getState() == shared.Enums.RunState.Expedition,
        'Early return should not force settlement'
    )

    local extractionStarted, extractionReason = tracker:beginExtraction()
    assert(
        extractionStarted == true,
        extractionReason or 'Extraction should start after expedition'
    )
    assert(
        tracker:getState() == shared.Enums.RunState.Extraction,
        'Tracker should transition into extraction'
    )

    local settlementCompleted, settlementReason = tracker:completeSettlement({
        {
            UserId = 20,
            Name = 'Bravo',
            ReturnReason = 'settled',
            Value = 42,
            ItemCount = 2,
            Weight = 4,
            WasExtracted = true,
            WasSettled = true,
        },
    })
    assert(
        settlementCompleted == true,
        settlementReason or 'Settlement should complete for the remaining active player'
    )
    assert(tracker.IsCompleted == true, 'Settlement should mark the tracker complete')
    assert(
        tracker:getState() == shared.Enums.RunState.Settlement,
        'Tracker should end in settlement'
    )

    local summaries = tracker:getReturnedSummaries()
    assert(#summaries == 2, 'Both player summaries should be retained')
    assert(summaries[1].ReturnReason == 'early_return', 'Early return should be preserved')
    assert(summaries[2].WasSettled == true, 'Settlement summary should keep settled flag')

    local canRejoin, rejoinReason = tracker:addPlayer({ UserId = 30, Name = 'Charlie' })
    assert(canRejoin == false, 'Completed trackers should reject new active players')
    assert(rejoinReason == 'Completed', 'Completed trackers should expose a concrete error')
end
