return function()
    local ReplicatedStorage = game:GetService('ReplicatedStorage')
    local runModules = ReplicatedStorage:WaitForChild('PlaceModules'):WaitForChild('Run')
    local RunSessionService = require(runModules:WaitForChild('RunSessionService'))

    local service = RunSessionService.new()
    service.GamePhase = 'Waiting'

    service:_assignHost(200)
    assert(service.HostUserId == 200, 'The first waiting player should become host')

    service:_assignHost(100)
    assert(
        service.HostUserId == 200,
        'Later waiting joins should not replace the existing host while they are still present'
    )

    service:_removeWaitingPlayer(200)
    service:_assignHost(nil)
    assert(
        service.HostUserId == 100,
        'When the host leaves, the next waiting player should inherit the host role'
    )

    service:_assignHost(100)
    assert(
        #service.WaitingPlayerOrderUserIds == 1,
        'Waiting join order should deduplicate repeated joins for the same player'
    )
end
