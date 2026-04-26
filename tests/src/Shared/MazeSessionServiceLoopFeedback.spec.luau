return function()
    local ReplicatedStorage = game:GetService('ReplicatedStorage')
    local packages = ReplicatedStorage:WaitForChild('Packages')
    local gameplay = require(packages:WaitForChild('Gameplay'))
    local mazeModules = ReplicatedStorage:WaitForChild('PlaceModules'):WaitForChild('Maze')
    local MazeSessionService = require(mazeModules:WaitForChild('MazeSessionService'))

    local function createPlayer(userId, displayName)
        return {
            UserId = userId,
            DisplayName = displayName,
        }
    end

    local function createService()
        local service = MazeSessionService.new({
            MonsterServiceFactory = function()
                return {
                    destroy = function() end,
                    spawn = function() end,
                }
            end,
        })

        service._setStatus = function(self, status)
            self.Status = status
        end
        service._publishMazePresence = function() end
        service._clearPlayerMovement = function() end
        service.World = {
            ReturnHoldCFrame = CFrame.new(),
        }

        return service
    end

    local objectiveService = createService()
    assert(
        string.find(objectiveService:_getObjectiveFor(), 'recover Pages', 1, true) ~= nil,
        'Maze objective should tell players to recover Pages'
    )
    assert(
        string.find(objectiveService:_getObjectiveFor(), 'grab loot', 1, true) == nil,
        'Maze objective should not call the assignment loot'
    )

    local pickupService = createService()
    local pickupPlayer = createPlayer(101, 'Alpha')
    pickupService:_addPlayerState(pickupPlayer)
    assert(
        pickupService.RunTracker:beginExpedition() == true,
        'Pickup feedback spec should enter expedition'
    )

    local lootNode = {
        Collected = false,
        ItemDef = gameplay.Config.Items[1],
        markCollected = function(self)
            self.Collected = true
        end,
    }
    pickupService.World.getLootNode = function(_, roomId)
        if roomId == 'Room_Loot' then
            return lootNode
        end
        return nil
    end

    pickupService:_pickupLoot(pickupPlayer, 'Room_Loot')
    assert(
        string.find(pickupService.Status, 'recovered a Page', 1, true) ~= nil,
        'Pickup feedback should name the recovered objective as a Page'
    )
    assert(
        string.find(pickupService.Status, 'return now or risk more', 1, true) ~= nil,
        'Pickup feedback should teach the retreat versus greed decision'
    )

    local returnService = createService()
    local returnPlayer = createPlayer(202, 'Bravo')
    returnService:_addPlayerState(returnPlayer)
    assert(
        returnService.RunTracker:beginExpedition() == true,
        'Return feedback spec should enter expedition'
    )
    returnService.InventoryService:pickup(returnPlayer, gameplay.Config.Items[1])
    returnService._teleportToCamp = function()
        return true
    end

    returnService:_returnPlayerToRunEntrance(returnPlayer, 'returned')
    assert(
        string.find(returnService.Status, 'returned alive with 1 Page', 1, true) ~= nil,
        'Return feedback should state the Page count brought back alive'
    )
    assert(
        string.find(returnService.Status, 'Banking Pages alive is progress', 1, true) ~= nil,
        'Return feedback should reinforce alive return value'
    )

    local deathService = createService()
    local deathPlayer = createPlayer(303, 'Charlie')
    deathService:_addPlayerState(deathPlayer)
    assert(
        deathService.RunTracker:beginExpedition() == true,
        'Death feedback spec should enter expedition'
    )

    deathService:_handlePlayerDeath(deathPlayer, 'Heavy')
    assert(
        string.find(deathService.Status, 'dropping their pack', 1, true) ~= nil,
        'Death feedback should mention dropped pack consequence'
    )
    assert(
        string.find(deathService.Status, 'make less noise', 1, true) ~= nil,
        'Death feedback should teach less noise next time'
    )
    assert(
        string.find(deathService.Status, 'leave with Pages sooner', 1, true) ~= nil,
        'Death feedback should teach earlier Page extraction'
    )
end
