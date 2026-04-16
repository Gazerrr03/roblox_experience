return function()
    local ReplicatedStorage = game:GetService('ReplicatedStorage')
    local runModules = ReplicatedStorage:WaitForChild('PlaceModules'):WaitForChild('Run')
    local RunSessionService = require(runModules:WaitForChild('RunSessionService'))

    local fakeTODService = {
        StartCalls = 0,
    }

    function fakeTODService:start()
        self.StartCalls += 1
    end

    function fakeTODService:prime() end

    function fakeTODService:sendToPlayer() end

    local service = RunSessionService.new({
        TODService = fakeTODService,
    })

    local worldOpenCalls = 0
    local trackerBeginCalls = 0

    service.World = {
        openGate = function()
            worldOpenCalls += 1
        end,
    }
    service.RunTracker = {
        beginExpedition = function()
            trackerBeginCalls += 1
        end,
    }
    service._syncCampSession = function() end
    service._beginExpedition = function() end
    service._setStatus = function() end

    service:_openGate({
        DisplayName = 'Explorer',
    })

    assert(service.GateOpen == true, 'Opening the gate should mark the run gate as open')
    assert(worldOpenCalls == 1, 'Opening the gate should animate the world gate exactly once')
    assert(
        trackerBeginCalls == 1,
        'Opening the gate should tell the run tracker to enter expedition mode'
    )
    assert(fakeTODService.StartCalls == 1, 'Opening the gate should start TOD exactly once')

    service:_openGate({
        DisplayName = 'Explorer',
    })

    assert(worldOpenCalls == 1, 'Repeated gate checks should not reopen the world gate')
    assert(
        fakeTODService.StartCalls == 1,
        'Repeated gate checks should not restart TOD after the first launch'
    )
end
