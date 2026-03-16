return function()
    local ReplicatedStorage = game:GetService('ReplicatedStorage')
    local shared = require(ReplicatedStorage:WaitForChild('Packages'):WaitForChild('Shared'))
    local availability = shared.Session.MazeEntryAvailability

    local teleportReady = availability.evaluate({
        PlaceIds = {
            Lobby = 1,
            Run = 2,
            Maze = 3,
        },
        PlaceId = 2,
        GameId = 99,
        IsStudio = false,
        DebugLocalMazeHandoff = false,
    })

    assert(
        teleportReady.Mode == availability.Mode.Teleport,
        'Published place ids should allow teleport mode'
    )
    assert(
        teleportReady.ReasonCode == availability.ReasonCode.TeleportReady,
        'Teleport mode should use TeleportReady reason'
    )

    local localDebugFallback = availability.evaluate({
        PlaceIds = {
            Lobby = 1,
            Run = 2,
            Maze = 0,
        },
        PlaceId = 0,
        GameId = 0,
        IsStudio = true,
        DebugLocalMazeHandoff = true,
    })

    assert(
        localDebugFallback.Mode == availability.Mode.LocalDebugFallback,
        'Studio local-file mode should use local debug fallback when enabled'
    )
    assert(
        localDebugFallback.ReasonCode == availability.ReasonCode.StudioLocalFileDebugFallback,
        'Local debug fallback should expose the expected reason code'
    )

    local blockedStudioLocalFile = availability.evaluate({
        PlaceIds = {
            Lobby = 1,
            Run = 2,
            Maze = 3,
        },
        PlaceId = 0,
        GameId = 0,
        IsStudio = true,
        DebugLocalMazeHandoff = false,
    })

    assert(
        blockedStudioLocalFile.Mode == availability.Mode.LocalDebugFallback,
        'Studio local-file mode should auto-enable local debug fallback when debug flag is disabled'
    )
    assert(
        blockedStudioLocalFile.ReasonCode == availability.ReasonCode.StudioLocalFileAutoFallback,
        'Studio local-file auto fallback should expose the expected reason code'
    )

    local blockedMissingPlaceId = availability.evaluate({
        PlaceIds = {
            Lobby = 1,
            Run = 2,
            Maze = 0,
        },
        PlaceId = 2,
        GameId = 99,
        IsStudio = false,
        DebugLocalMazeHandoff = false,
    })

    assert(
        blockedMissingPlaceId.Mode == availability.Mode.Blocked,
        'Missing maze place id should block entry'
    )
    assert(
        blockedMissingPlaceId.ReasonCode == availability.ReasonCode.MazePlaceIdMissing,
        'Blocked mode should identify missing maze place id'
    )
end
