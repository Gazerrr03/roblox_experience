return function()
    local ReplicatedStorage = game:GetService('ReplicatedStorage')
    local mazeModules = ReplicatedStorage:WaitForChild('PlaceModules'):WaitForChild('Maze')
    local MazeSessionService = require(mazeModules:WaitForChild('MazeSessionService'))

    local function createService()
        local service = MazeSessionService.new()
        service.World = {
            ReturnHoldCFrame = CFrame.new(),
        }

        service._setStatus = function(self, status)
            self.Status = status
        end
        service._spawnCorpseForPlayer = function() end
        service._syncPlayerMovement = function() end
        service._clearPlayerMovement = function() end
        service._buildSummaryFor = function(_, player, returnReason)
            return {
                UserId = player.UserId,
                Name = player.DisplayName,
                ReturnReason = returnReason,
                Value = 0,
            }
        end

        local destroyCount = 0
        service.MonsterService = {
            destroy = function()
                destroyCount += 1
            end,
        }
        service._monsterDestroyCount = function()
            return destroyCount
        end

        service._teleportEvents = {}
        service._teleportToCamp = function(_, players, summaries, mazeCompleted)
            table.insert(service._teleportEvents, {
                PlayerCount = #players,
                ReturnReason = summaries[1].ReturnReason,
                MazeCompleted = mazeCompleted,
            })
            return true
        end

        return service
    end

    local multiPlayerService = createService()
    assert(
        multiPlayerService.RunTracker:addPlayer({ UserId = 1, Name = 'Alpha' }) == true,
        'First active player should be tracked'
    )
    assert(
        multiPlayerService.RunTracker:addPlayer({ UserId = 2, Name = 'Bravo' }) == true,
        'Second active player should be tracked'
    )
    assert(
        multiPlayerService.RunTracker:beginExpedition() == true,
        'Regression spec should enter the expedition state'
    )

    multiPlayerService:_handlePlayerDeath({
        UserId = 1,
        DisplayName = 'Alpha',
    }, 'Heavy')

    assert(
        multiPlayerService._monsterDestroyCount() == 0,
        'A single player death should not destroy the monster while other active players remain'
    )
    assert(
        multiPlayerService._teleportEvents[1].MazeCompleted == false,
        'A non-terminal death return should keep the expedition open'
    )
    assert(
        multiPlayerService.RunTracker:isPlayerActive(2) == true,
        'Other active players should stay in the expedition after a teammate dies'
    )

    local finalPlayerService = createService()
    assert(
        finalPlayerService.RunTracker:addPlayer({ UserId = 3, Name = 'Solo' }) == true,
        'Final-player service should track its only player'
    )
    assert(
        finalPlayerService.RunTracker:beginExpedition() == true,
        'Final-player service should enter expedition'
    )

    finalPlayerService:_handlePlayerDeath({
        UserId = 3,
        DisplayName = 'Solo',
    }, 'Heavy')

    assert(
        finalPlayerService._monsterDestroyCount() == 1,
        'The monster should only be destroyed after the final active player leaves the expedition'
    )
    assert(
        finalPlayerService._teleportEvents[1].MazeCompleted == true,
        'The final-player death should mark the expedition complete'
    )
end
