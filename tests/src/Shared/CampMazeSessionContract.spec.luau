return function()
    local ReplicatedStorage = game:GetService('ReplicatedStorage')
    local gameplay = require(ReplicatedStorage:WaitForChild('Packages'):WaitForChild('Gameplay'))
    local shared = require(ReplicatedStorage:WaitForChild('Packages'):WaitForChild('Shared'))
    local contract = shared.Session.CampMazeSessionContract
    local monsterAssetIds = gameplay.Monsters.MonsterAssetIds

    local campSession = contract.newCampSession({
        SessionId = 'camp-session-1',
        CampAccessCode = 'camp-access-code',
        SignalScope = 'run:test-scope',
    })

    assert(campSession.CurrentRound == 1, 'New sessions should start on round 1')
    assert(campSession.MaxRounds == 5, 'New sessions should default to a 5-round mission')
    assert(
        campSession.TargetItemCount == 12,
        'New sessions should default to the mission target item count'
    )
    assert(campSession.BankedItemCount == 0, 'New sessions should start with zero banked items')
    assert(
        campSession.SessionPhase == contract.SessionPhase.RunPrep,
        'New sessions should start in RunPrep'
    )

    local assignedHost = contract.assignHost(campSession, 42)
    assert(assignedHost.HostUserId == 42, 'Host assignment should persist on the session')

    local roundLive = contract.markRoundStarted(assignedHost, {
        HostUserId = 42,
        RoundStartTime = 10,
        RoundEndTime = 910,
        DangerActive = true,
    })
    assert(roundLive.GateOpen == true, 'Round start should open the ship gate')
    assert(roundLive.RoundStarted == true, 'Round start should mark the round live')
    assert(
        roundLive.SessionPhase == contract.SessionPhase.RunField,
        'Live round should resolve to RunField'
    )

    local midSettlement = contract.markSettlementTriggered(roundLive, {
        SettlementReason = 'timeout',
        TriggeredByUserId = 42,
        TriggeredByName = 'Scout',
        RoundOutcome = 'timeout',
    })
    assert(midSettlement.GateOpen == false, 'Settlement should close the gate')
    assert(midSettlement.RoundOutcome == 'timeout', 'Settlement should preserve the round outcome')
    assert(
        midSettlement.SessionPhase == contract.SessionPhase.RunIntermission,
        'Non-final settlement should move into RunIntermission'
    )

    local afterBank = contract.recordBankedItems(midSettlement, 3)
    assert(afterBank.BankedItemCount == 3, 'Banked items should accumulate on the shared session')

    local persistentWorld = contract.setPersistentWorldState(afterBank, {
        CollectedLootRoomIds = { 'Room_A', 'Room_B' },
        DropNodes = {
            {
                DropNodeId = 'drop-1',
                Label = 'Scout Pack',
                Position = Vector3.new(1, 2, 3),
                Entries = {
                    {
                        InstanceId = 7,
                        Id = 'clue-threat-1',
                        Name = 'Warning Note',
                        ItemCategory = 'Clue',
                        MissionCount = 0,
                        ReadableTitle = 'Warning Note',
                        ReadableText = 'Do not trust the first footsteps you hear.',
                    },
                },
            },
        },
    })
    assert(
        persistentWorld.PersistentWorldState.DropNodes[1].Position.X == 1,
        'Persistent world drop positions should normalize to serializable coordinates'
    )
    assert(
        persistentWorld.PersistentWorldState.DropNodes[1].Entries[1].ReadableTitle == 'Warning Note',
        'Persistent world state should preserve dropped clue entries'
    )

    local resetRound = contract.resetForNextRound(persistentWorld)
    assert(resetRound.CurrentRound == 2, 'Reset should advance to the next mission round')
    assert(resetRound.BankedItemCount == 3, 'Reset should preserve banked mission progress')
    assert(
        resetRound.PersistentWorldState.CollectedLootRoomIds[2] == 'Room_B',
        'Reset should preserve persistent world state'
    )
    assert(
        resetRound.SessionPhase == contract.SessionPhase.RunPrep,
        'Reset should return to RunPrep when the mission continues'
    )

    local entered = contract.markPlayerEntered(resetRound, {
        UserId = 42,
        Name = 'Scout',
    })
    entered.MazeAccessCode = 'maze-access-code'
    assert(
        entered.MazeStatus == contract.MazeStatus.Active,
        'Entering the maze should activate the maze status'
    )
    assert(
        entered.SessionPhase == contract.SessionPhase.MazeActive,
        'Entering the maze should move the session into MazeActive'
    )

    local roundTripInventory = {
        Capacity = 5,
        Weight = 0,
        Count = 2,
        BackpackCount = 1,
        HeldCount = 1,
        Value = 0,
        LootCount = 1,
        ClueCount = 1,
        ToolCount = 0,
        MissionCount = 1,
        BackpackItems = {
            {
                InstanceId = 1,
                Id = 'clue-threat-1',
                Name = 'Warning Note',
                ItemCategory = 'Clue',
                MissionCount = 0,
                ReadableTitle = 'Warning Note',
                ReadableText = 'Do not trust the first footsteps you hear.',
                ClueId = 'threat-1',
                ThreatHintId = 'monster-echo',
                SourceMarkerId = 'ClueMarker_Warning',
            },
        },
        HeldItem = {
            InstanceId = 2,
            Id = 'glow-orb',
            Name = 'Glow Orb',
            ItemCategory = 'Loot',
            MissionCount = 1,
            Weight = 1,
            Value = 24,
            Color = Color3.fromRGB(142, 236, 255),
            Light = {
                Brightness = 2.5,
                Range = 18,
                Color = Color3.fromRGB(170, 240, 255),
            },
        },
    }

    local campToMaze = contract.buildRunToMazeTeleportData({
        SessionConfig = {
            Seed = 12345,
            Quota = 12,
            RunDurationSeconds = 900,
            InventoryCapacity = 5,
        },
        CampSession = entered,
        EnteringPlayer = {
            UserId = 42,
            Name = 'Scout',
        },
        EntryReason = 'maze_gate',
        PlayerInventory = roundTripInventory,
        PendingUgcMonsterPayload = {
            OwnerUserId = 42,
            MonsterId = 'ugc-42-100',
            MonsterName = 'Scrap Whisper',
            Seed = 100,
            RecipeHash = 'recipe-1234',
            RuntimeProfile = {
                Id = 'ugc-42-100',
                Name = 'Scrap Whisper',
                Presentation = {
                    ModelAssetId = monsterAssetIds.DefaultModelAssetId,
                    RigType = 'R6',
                    AnimationMode = 'defaultR6',
                    ChaseLoopSoundAssetId = monsterAssetIds.DefaultChaseLoopSoundAssetId,
                },
                Speed = 14,
                SightRange = 36,
                PatrolSpeedMultiplier = 0.45,
                SpawnOffset = Vector3.new(0, 4, 0),
                Behaviors = {
                    SenseNearestTarget = true,
                    Chase = true,
                },
                Effects = {},
            },
            Diagnostics = {
                SkippedBehaviorIds = { 'LoseTarget' },
                SkippedEffectIds = {},
                ClampedFields = {},
            },
        },
    })

    local enteringInventory = contract.findPlayerInventory(campToMaze, 42)
    assert(
        enteringInventory ~= nil,
        'Run -> maze payload should carry the entering player inventory'
    )
    assert(enteringInventory.ClueCount == 1, 'Teleport inventory should preserve clue counts')
    assert(
        enteringInventory.HeldItem.MissionCount == 1,
        'Teleport inventory should preserve loot mission count'
    )
    assert(
        enteringInventory.BackpackItems[1].ReadableText
            == 'Do not trust the first footsteps you hear.',
        'Teleport inventory should preserve readable clue text'
    )

    local pendingUgcPayload = contract.findPendingUgcMonsterPayload(campToMaze)
    assert(
        pendingUgcPayload ~= nil and pendingUgcPayload.OwnerUserId == 42,
        'Run -> maze payload should preserve pending UGC monster payloads'
    )
    assert(
        pendingUgcPayload.RuntimeProfile.Presentation.ModelAssetId
            == monsterAssetIds.DefaultModelAssetId,
        'Pending UGC payload should preserve monster presentation data'
    )

    local earlyReturn = contract.buildReturnSummary({
        UserId = 42,
        Name = 'Scout',
        ReturnReason = 'extracted',
        LootItemCount = 2,
        ClueCount = 1,
        ToolCount = 0,
        MissionCount = 2,
        ItemCount = 3,
        WasExtracted = true,
    })
    local resumed = contract.applyReturn(entered, earlyReturn, false)
    assert(#resumed.PlayersInMaze == 0, 'Returned players should leave the maze roster')
    assert(
        resumed.ReturnedPlayerSummaries[1].LootItemCount == 2,
        'Return summaries should preserve loot counts'
    )
    assert(
        resumed.SessionPhase == contract.SessionPhase.RunIntermission,
        'Returned summaries should move the mission into RunIntermission while rounds remain'
    )

    local finalRound = contract.newCampSession({
        SessionId = 'camp-session-final',
        CampAccessCode = 'camp-access-final',
        CurrentRound = 5,
        MaxRounds = 5,
        BankedItemCount = 11,
        TargetItemCount = 12,
    })
    local finalSettlement = contract.markSettlementTriggered(finalRound, {
        SettlementReason = 'timeout',
        RoundOutcome = 'timeout',
    })
    local finalOutcome = contract.markSessionOutcome(finalSettlement, 'failure')
    assert(
        finalOutcome.SessionPhase == contract.SessionPhase.FinalDebrief,
        'Final-round outcome should move into FinalDebrief'
    )
    assert(
        finalOutcome.SessionOutcome == 'failure',
        'Session outcome should persist on final debrief'
    )

    local mazeToRun = contract.buildMazeToRunTeleportData({
        SessionConfig = {
            Seed = 12345,
        },
        CampSession = finalOutcome,
        Summaries = {
            earlyReturn,
        },
        MazeCompleted = true,
        PlayerInventories = {
            {
                UserId = 42,
                Inventory = roundTripInventory,
            },
        },
    })
    assert(
        mazeToRun.MazeReturn.MazeCompleted == true,
        'Maze -> run payload should preserve completion state'
    )
    assert(
        contract.findReturnSummary(mazeToRun, 42).MissionCount == 2,
        'Maze -> run payload should preserve mission counts inside return summaries'
    )
end
