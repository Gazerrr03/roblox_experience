return function()
    local ReplicatedStorage = game:GetService('ReplicatedStorage')

    local runModules = ReplicatedStorage:WaitForChild('PlaceModules'):WaitForChild('Run')
    local RunToMazeTransition = require(runModules:WaitForChild('RunToMazeTransition'))

    local calls = {
        ReserveServer = 0,
        TeleportAsync = 0,
    }
    local fakeTeleportService = {
        ReserveServer = function(_, placeId)
            calls.ReserveServer += 1
            calls.ReservedPlaceId = placeId
            return 'reserved-maze-access'
        end,
        TeleportAsync = function(_, placeId, players, teleportOptions)
            calls.TeleportAsync += 1
            calls.TeleportPlaceId = placeId
            calls.PlayerCount = #players
            calls.TeleportData = teleportOptions:GetTeleportData()
        end,
    }
    local fakeContract = {
        normalizeCampSession = function(session)
            return table.clone(session)
        end,
        markPlayerEntered = function(session, enteringPlayer)
            session.PlayersInMaze = { enteringPlayer }
            return session
        end,
        buildRunToMazeTeleportData = function(payload)
            return {
                SessionConfig = payload.SessionConfig,
                CampSession = payload.CampSession,
                EntryReason = payload.EntryReason,
            }
        end,
    }
    local fakeDiagnostics = {
        captureSnapshot = function()
            return { Snapshot = true }
        end,
        formatFailure = function(_, stage, reason)
            return string.format('%s:%s', tostring(stage), tostring(reason))
        end,
    }
    local transition = RunToMazeTransition.new({
        TeleportService = fakeTeleportService,
        SessionConfig = {
            PlaceIds = {
                Maze = 777,
            },
        },
        Contract = fakeContract,
        Availability = {
            ReasonCode = {
                TeleportReady = 'TeleportReady',
            },
        },
        Diagnostics = fakeDiagnostics,
    })

    local result = transition:enter({
        Player = { UserId = 1 },
        CampSession = {
            SessionId = 'camp-session-1',
        },
        GateOpen = true,
        SessionConfig = {
            Seed = 123,
        },
        PlayerInventory = {},
        EnteringPlayer = {
            UserId = 1,
            Name = 'Scout',
        },
        EntryReason = 'maze_gate',
    })

    assert(result.Ok == true, 'RunToMazeTransition should succeed when reserve and teleport work')
    assert(calls.ReserveServer == 1, 'RunToMazeTransition should reserve a maze server once')
    assert(calls.TeleportAsync == 1, 'RunToMazeTransition should issue one teleport request')
    assert(
        calls.ReservedPlaceId == 777,
        'RunToMazeTransition should reserve the configured maze place'
    )
    assert(
        calls.TeleportPlaceId == 777,
        'RunToMazeTransition should teleport to the configured maze place'
    )
    assert(
        calls.TeleportData.CampSession.MazeAccessCode == 'reserved-maze-access',
        'RunToMazeTransition should persist the reserved access code into teleport data'
    )
end
