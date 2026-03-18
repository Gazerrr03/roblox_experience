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
        'Studio local-file mode should allow local debug fallback when enabled'
    )
    assert(
        localDebugFallback.ReasonCode == availability.ReasonCode.LocalDebugFallbackEnabled,
        'Local debug fallback should expose the expected reason code'
    )

    local studioPublishedFallback = availability.evaluate({
        PlaceIds = {
            Lobby = 1,
            Run = 2,
            Maze = 3,
        },
        PlaceId = 2,
        GameId = 99,
        IsStudio = true,
        DebugLocalMazeHandoff = true,
    })

    assert(
        studioPublishedFallback.Mode == availability.Mode.LocalDebugFallback,
        'Studio should allow local debug fallback even when PlaceId/GameId are set'
    )
    assert(
        studioPublishedFallback.ReasonCode == availability.ReasonCode.LocalDebugFallbackEnabled,
        'Studio local debug fallback should expose the expected reason code'
    )

    local studioPublishedFallbackWithoutMazePlaceId = availability.evaluate({
        PlaceIds = {
            Lobby = 1,
            Run = 2,
            Maze = 0,
        },
        PlaceId = 2,
        GameId = 99,
        IsStudio = true,
        DebugLocalMazeHandoff = true,
    })

    assert(
        studioPublishedFallbackWithoutMazePlaceId.Mode == availability.Mode.LocalDebugFallback,
        'Studio debug fallback should not require a maze place id'
    )

    local autoFallbackStudioLocalFile = availability.evaluate({
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
        autoFallbackStudioLocalFile.Mode == availability.Mode.LocalDebugFallback,
        'Studio local-file mode should auto-fallback when teleport targets are unpublished'
    )
    assert(
        autoFallbackStudioLocalFile.ReasonCode
            == availability.ReasonCode.StudioLocalFileAutoFallback,
        'Studio local-file auto-fallback should expose the expected reason code'
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
