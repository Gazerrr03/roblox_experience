return function()
    local ReplicatedStorage = game:GetService('ReplicatedStorage')
    local mazeModules = ReplicatedStorage:WaitForChild('PlaceModules'):WaitForChild('Maze')
    local MazeSessionService = require(mazeModules:WaitForChild('MazeSessionService'))

    local subscribeFinished = false
    local fakeRoundSignalConnection = {
        Disconnect = function() end,
    }
    local fakeRoundSignalBus = {
        publish = function()
            return true
        end,
        subscribe = function()
            task.wait(0.2)
            subscribeFinished = true
            return fakeRoundSignalConnection, true
        end,
    }

    local service = MazeSessionService.new({
        RoundSignalBus = fakeRoundSignalBus,
        MonsterServiceFactory = function()
            return {
                destroy = function() end,
                setDeterministicSeed = function() end,
                spawn = function() end,
            }
        end,
    })

    local startedAt = os.clock()
    service:_subscribeToRoundSignals()
    local elapsed = os.clock() - startedAt

    assert(
        elapsed < 0.05,
        'Maze round-signal subscription should not block direct PlayTest startup'
    )
    assert(
        subscribeFinished == false,
        'Round-signal subscription should continue in the background after startup continues'
    )

    task.wait(0.25)

    assert(subscribeFinished == true, 'Background round-signal subscription should still run')
    assert(
        service.RoundSignalConnection == fakeRoundSignalConnection,
        'Successful background round-signal subscription should be retained'
    )
end
