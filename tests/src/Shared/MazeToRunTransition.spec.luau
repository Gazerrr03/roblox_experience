return function()
    local ReplicatedStorage = game:GetService('ReplicatedStorage')

    local mazeModules = ReplicatedStorage:WaitForChild('PlaceModules'):WaitForChild('Maze')
    local MazeToRunTransition = require(mazeModules:WaitForChild('MazeToRunTransition'))

    local calls = {
        TeleportToPrivateServer = 0,
    }
    local fakeTeleportService = {
        TeleportToPrivateServer = function(
            _,
            placeId,
            accessCode,
            players,
            spawnName,
            teleportData
        )
            calls.TeleportToPrivateServer += 1
            calls.PlaceId = placeId
            calls.AccessCode = accessCode
            calls.PlayerCount = #players
            calls.SpawnName = spawnName
            calls.TeleportData = teleportData
        end,
    }
    local fakeContract = {
        normalizeCampSession = function(session)
            return table.clone(session)
        end,
        applyReturn = function(session, summary, mazeCompleted)
            session.ReturnedPlayerSummaries = session.ReturnedPlayerSummaries or {}
            table.insert(session.ReturnedPlayerSummaries, {
                UserId = summary.UserId,
                MazeCompleted = mazeCompleted,
            })
            return session
        end,
        buildMazeToRunTeleportData = function(payload)
            return {
                CampSession = payload.CampSession,
                Summaries = payload.Summaries,
                MazeCompleted = payload.MazeCompleted,
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
    local transition = MazeToRunTransition.new({
        TeleportService = fakeTeleportService,
        SessionConfig = {
            PlaceIds = {
                Run = 555,
            },
        },
        Contract = fakeContract,
        Diagnostics = fakeDiagnostics,
    })

    local result = transition:returnPlayers({
        Players = {
            { UserId = 101 },
            { UserId = 202 },
        },
        SessionConfig = {
            Seed = 123,
        },
        CampSession = {
            CampAccessCode = 'run-access-1',
        },
        Summaries = {
            { UserId = 101 },
            { UserId = 202 },
        },
        MazeCompleted = true,
        PlayerInventories = {},
    })

    assert(result.Ok == true, 'MazeToRunTransition should succeed when the teleport call succeeds')
    assert(
        calls.TeleportToPrivateServer == 1,
        'MazeToRunTransition should issue a single return teleport'
    )
    assert(calls.PlaceId == 555, 'MazeToRunTransition should target the configured run place')
    assert(
        calls.AccessCode == 'run-access-1',
        'MazeToRunTransition should use the authored camp access code'
    )
    assert(
        #calls.TeleportData.CampSession.ReturnedPlayerSummaries == 2,
        'MazeToRunTransition should merge all returned summaries into camp session state'
    )
end
