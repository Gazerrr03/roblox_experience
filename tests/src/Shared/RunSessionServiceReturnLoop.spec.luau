return function()
    local ReplicatedStorage = game:GetService('ReplicatedStorage')
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
end
