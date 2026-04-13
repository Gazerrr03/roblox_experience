return function()
    local ReplicatedStorage = game:GetService('ReplicatedStorage')
    local Packages = ReplicatedStorage:WaitForChild('Packages')
    local Shared = require(Packages:WaitForChild('Shared'))
    local CampMazeSessionContract = Shared.Session.CampMazeSessionContract
    local runModules = ReplicatedStorage:WaitForChild('PlaceModules'):WaitForChild('Run')
    local RunSpawnPoint = require(runModules:WaitForChild('RunSpawnPoint'))
    local RunSessionService = require(runModules:WaitForChild('RunSessionService'))

    local service = RunSessionService.new()

    assert(
        service:_getReturnSpawnTargetForSummary({
            ReturnReason = 'early_return',
        }) == RunSpawnPoint.Kind.MazeReturn,
        'Blue return-pad exits should land back at the run maze entrance'
    )

    assert(
        service:_getReturnSpawnTargetForSummary({
            ReturnReason = 'extracted',
        }) == RunSpawnPoint.Kind.MazeReturn,
        'Gold extraction exits should also land back at the run maze entrance'
    )

    assert(
        service:_getReturnSpawnTargetForSummary({
            ReturnReason = 'death',
        }) == RunSpawnPoint.Kind.Return,
        'Non-loop returns should keep using the generic run return position'
    )

    local startupService = RunSessionService.new()
    startupService._readTeleportData = function()
        return nil
    end

    local startupTeleportData = CampMazeSessionContract.buildMazeToRunTeleportData({
        SessionConfig = {},
        CampSession = CampMazeSessionContract.newCampSession({
            SessionId = 'session-114',
            CampAccessCode = 'camp-114',
            MazeAccessCode = 'maze-114',
        }),
        Summaries = {
            CampMazeSessionContract.buildReturnSummary({
                UserId = 101,
                Name = 'BluePlayer',
                ReturnReason = 'early_return',
            }),
            CampMazeSessionContract.buildReturnSummary({
                UserId = 202,
                Name = 'DownedPlayer',
                ReturnReason = 'death',
            }),
        },
        MazeCompleted = false,
    })

    startupService:_applyReturnedPlayersFromTeleportData({
        {
            UserId = 101,
            DisplayName = 'BluePlayer',
        },
        {
            UserId = 202,
            DisplayName = 'DownedPlayer',
        },
    }, startupTeleportData)

    assert(
        startupService.PendingSpawnByUserId[101] == RunSpawnPoint.Kind.MazeReturn,
        'Startup return processing should keep maze-gate returns at the run maze entrance'
    )
    assert(
        startupService.PendingSpawnByUserId[202] == RunSpawnPoint.Kind.Return,
        'Startup return processing should keep non-loop returns at the generic run return position'
    )
end
