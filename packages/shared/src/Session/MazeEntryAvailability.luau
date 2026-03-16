local MazeEntryAvailability = {}

MazeEntryAvailability.Mode = {
    Teleport = 'Teleport',
    LocalDebugFallback = 'LocalDebugFallback',
    Blocked = 'Blocked',
}

MazeEntryAvailability.ReasonCode = {
    TeleportReady = 'TeleportReady',
    LocalDebugFallbackEnabled = 'LocalDebugFallbackEnabled',
    MazePlaceIdMissing = 'MazePlaceIdMissing',
    StudioLocalFileTeleportBlocked = 'StudioLocalFileTeleportBlocked',
}

function MazeEntryAvailability.evaluate(params)
    local placeIds = params.PlaceIds or {}
    local mazePlaceId = type(placeIds.Maze) == 'number' and placeIds.Maze or 0
    local isStudio = params.IsStudio == true
    local placeId = type(params.PlaceId) == 'number' and params.PlaceId or 0
    local gameId = type(params.GameId) == 'number' and params.GameId or 0
    local debugLocalMazeHandoff = params.DebugLocalMazeHandoff == true

    if isStudio and (placeId <= 0 or gameId <= 0) then
        if debugLocalMazeHandoff then
            return {
                Mode = MazeEntryAvailability.Mode.LocalDebugFallback,
                ReasonCode = MazeEntryAvailability.ReasonCode.LocalDebugFallbackEnabled,
                Reason = 'Studio local debug fallback is enabled. Maze entry stays in the current place for MVP testing.',
            }
        end

        return {
            Mode = MazeEntryAvailability.Mode.Blocked,
            ReasonCode = MazeEntryAvailability.ReasonCode.StudioLocalFileTeleportBlocked,
            Reason = 'Maze teleport requires a published run place session (placeId and gameId must be non-zero).',
        }
    end

    if mazePlaceId <= 0 then
        return {
            Mode = MazeEntryAvailability.Mode.Blocked,
            ReasonCode = MazeEntryAvailability.ReasonCode.MazePlaceIdMissing,
            Reason = 'Set SessionConfig.PlaceIds.Maze or SessionPlaceIdMaze before using the maze gate.',
        }
    end

    return {
        Mode = MazeEntryAvailability.Mode.Teleport,
        ReasonCode = MazeEntryAvailability.ReasonCode.TeleportReady,
        Reason = 'Maze teleport target is ready.',
    }
end

return MazeEntryAvailability
