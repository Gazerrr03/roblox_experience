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

    local lobbyToRun = contract.buildLobbyToRunTeleportData({
        SessionId = 'camp-session-1',
        CampAccessCode = 'camp-access-code',
        SessionConfig = {
            Seed = 12345,
        },
    })
    assert(
        lobbyToRun.Entry.Kind == 'LobbyLaunch',
        'Lobby -> run teleport payload should mark the handoff entry kind'
    )

    local campToMaze = contract.buildRunToMazeTeleportData({
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
        PlayerInventory = {
            Capacity = 5,
            Weight = 1,
            Count = 1,
            BackpackCount = 0,
            HeldCount = 1,
            Value = 24,
            BackpackItems = {},
            HeldItem = {
                InstanceId = 4,
                Id = 'glow-orb',
                Name = 'Glow Orb',
                Weight = 1,
                Value = 24,
                Color = Color3.fromRGB(142, 236, 255),
                Light = {
                    Brightness = 2.5,
                    Range = 18,
                    Color = Color3.fromRGB(170, 240, 255),
                },
            },
        },
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
                    ModelAssetId = 4446576906,
                    RigType = 'R6',
                    AnimationMode = 'defaultR6',
                    ChaseLoopSoundAssetId = 9118823108,
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

    assert(
        campToMaze.MazeSession.MazeAccessCode == 'maze-access-code',
        'Maze access code should flow into the maze teleport payload'
    )
    assert(
        campToMaze.CampSession.SessionId == 'camp-session-1',
        'Camp session id should survive camp -> maze teleport shaping'
    )
    local enteringInventory = contract.findPlayerInventory(campToMaze, 42)
    assert(
        enteringInventory ~= nil,
        'Run -> maze payload should carry the entering player inventory'
    )
    assert(
        enteringInventory.HeldItem.Id == 'glow-orb',
        'Run -> maze inventory payload should preserve the held glow orb'
    )
    local pendingUgcPayload = contract.findPendingUgcMonsterPayload(campToMaze)
    assert(
        pendingUgcPayload ~= nil and pendingUgcPayload.OwnerUserId == 42,
        'Run -> maze payload should preserve pending UGC spawn payloads'
    )
    assert(
        pendingUgcPayload.RuntimeProfile ~= nil
            and pendingUgcPayload.RuntimeProfile.Presentation.ModelAssetId == 4446576906,
        'Pending UGC payload should preserve runtime monster presentation data'
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

    local mazeToCamp = contract.buildMazeToRunTeleportData({
        SessionConfig = {
            Seed = 12345,
            Quota = 120,
            RunDurationSeconds = 180,
            InventoryCapacity = 5,
        },
        CampSession = completed,
        Summaries = completed.ReturnedPlayerSummaries,
        MazeCompleted = true,
        PlayerInventories = {
            {
                UserId = 42,
                Inventory = {
                    Capacity = 5,
                    Weight = 1,
                    Count = 1,
                    BackpackCount = 0,
                    HeldCount = 1,
                    Value = 24,
                    BackpackItems = {},
                    HeldItem = {
                        InstanceId = 4,
                        Id = 'glow-orb',
                        Name = 'Glow Orb',
                        Weight = 1,
                        Value = 24,
                        Color = Color3.fromRGB(142, 236, 255),
                        Light = {
                            Brightness = 2.5,
                            Range = 18,
                            Color = Color3.fromRGB(170, 240, 255),
                        },
                    },
                },
            },
        },
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
    local returnedInventory = contract.findPlayerInventory(mazeToCamp, 42)
    assert(
        returnedInventory ~= nil,
        'Maze -> run payload should carry the returning player inventory'
    )
    assert(
        returnedInventory.HeldItem.Light ~= nil,
        'Maze -> run payload should preserve held item light metadata'
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
