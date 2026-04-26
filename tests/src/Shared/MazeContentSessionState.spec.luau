return function()
    local ReplicatedStorage = game:GetService('ReplicatedStorage')
    local placeModules = ReplicatedStorage:WaitForChild('PlaceModules')
    local MazeContentSessionState = require(
        placeModules:WaitForChild('MazeContentHarness'):WaitForChild('MazeContentSessionState')
    )

    local state = MazeContentSessionState.new(4242)
    assert(state.Seed == 4242, 'Seed should be stored on local content state')
    assert(state.SessionPhase == 'MazeActive', 'Content harness should default to MazeActive phase')
    assert(
        state.CurrentRound == 1 and state.MaxRounds == 1,
        'Content harness should stay single-round'
    )

    state:addPlayer({ UserId = 7, Name = 'Scout' })
    state:addPlayer({ UserId = 9, Name = 'Medic' })
    assert(state:getActiveCount() == 2, 'Added players should become active')

    local started, startReason = state:beginExpedition()
    assert(started == true, string.format('Expedition should begin (%s)', tostring(startReason)))
    assert(state.LoopState == 'Expedition', 'Loop state should move into Expedition')

    state:addBankedItems(3)
    assert(state.BankedItemCount == 3, 'Banked loot should accumulate locally')

    state:markLootCollected('Room_Loot')
    state:markLootCollected('Room_Loot')
    local persistentWorldState = state:getPersistentWorldState()
    assert(#persistentWorldState.CollectedLootRoomIds == 1, 'Collected loot ids should dedupe')
    assert(
        persistentWorldState.CollectedLootRoomIds[1] == 'Room_Loot',
        'Collected room ids should preserve authored ids'
    )

    local recorded, recordReason = state:recordReturn({
        UserId = 7,
        Name = 'Scout',
        ReturnReason = 'returned',
        LootItemCount = 2,
        MissionCount = 2,
    })
    assert(
        recorded == true,
        string.format('Return should record locally (%s)', tostring(recordReason))
    )
    assert(state:getActiveCount() == 1, 'Recording a return should remove the active player')

    local returnedSummaries = state:getReturnedSummaries()
    assert(#returnedSummaries == 1, 'Returned summaries should be captured locally')
    assert(
        returnedSummaries[1].ReturnReason == 'returned',
        'Returned summaries should preserve local return reason'
    )

    local completed, completionReason = state:completeExpedition()
    assert(completed == false, 'Expedition should not complete while players remain active')
    assert(
        completionReason == 'ActivePlayersRemaining',
        'Completion should fail with active players'
    )

    local secondRecorded = state:recordReturn({
        UserId = 9,
        Name = 'Medic',
        ReturnReason = 'death',
        CountedInSettlement = false,
    })
    assert(secondRecorded == true, 'Dead players should still be removable from active state')

    completed, completionReason = state:completeExpedition()
    assert(
        completed == true,
        string.format(
            'Expedition should complete after all players return (%s)',
            tostring(completionReason)
        )
    )
    assert(state.LoopState == 'Completed', 'Loop state should close locally once everyone is done')
    assert(
        state.SessionPhase == 'RunIntermission',
        'Completed local loop should flip the placeholder phase'
    )
    assert(state.MazeStatus == 'completed', 'Maze status should mark the local loop complete')
end
