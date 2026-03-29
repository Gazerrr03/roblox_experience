return function()
    local ReplicatedStorage = game:GetService('ReplicatedStorage')
    local Packages = ReplicatedStorage:WaitForChild('Packages')
    local Shared = require(Packages:WaitForChild('Shared'))
    local CampMazeSessionContract = Shared.Session.CampMazeSessionContract
    local runModules = ReplicatedStorage:WaitForChild('PlaceModules'):WaitForChild('Run')
    local RunSessionService = require(runModules:WaitForChild('RunSessionService'))
    local RunWorldBuilder = require(runModules:WaitForChild('RunWorldBuilder'))

    local service = RunSessionService.new()

    assert(
        service:_getReturnSpawnCFrameForSummary({
            ReturnReason = 'early_return',
        }) == RunWorldBuilder.MazeReturnCFrame,
        'Blue return-pad exits should land back at the run maze entrance'
    )

    assert(
        service:_getReturnSpawnCFrameForSummary({
            ReturnReason = 'extracted',
        }) == RunWorldBuilder.MazeReturnCFrame,
        'Gold extraction exits should also land back at the run maze entrance'
    )

    assert(
        service:_getReturnSpawnCFrameForSummary({
            ReturnReason = 'death',
        }) == RunWorldBuilder.ReturnCFrame,
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
        startupService.PendingSpawnByUserId[101] == RunWorldBuilder.MazeReturnCFrame,
        'Startup return processing should keep maze-gate returns at the run maze entrance'
    )
    assert(
        startupService.PendingSpawnByUserId[202] == RunWorldBuilder.ReturnCFrame,
        'Startup return processing should keep non-loop returns at the generic run return position'
    )
end
