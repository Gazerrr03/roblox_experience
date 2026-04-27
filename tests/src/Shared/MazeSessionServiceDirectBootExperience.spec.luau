return function()
    local ReplicatedStorage = game:GetService('ReplicatedStorage')
    local mazeModules = ReplicatedStorage:WaitForChild('PlaceModules'):WaitForChild('Maze')
    local MazeSessionService = require(mazeModules:WaitForChild('MazeSessionService'))

    local function createPlayer(userId, displayName)
        return {
            UserId = userId,
            DisplayName = displayName,
        }
    end

    local function createService(options)
        local runtimeOptions = options or {}
        runtimeOptions.MonsterServiceFactory = runtimeOptions.MonsterServiceFactory
            or function()
                return {
                    destroy = function() end,
                    setDeterministicSeed = function() end,
                    spawn = function() end,
                }
            end

        local service = MazeSessionService.new(runtimeOptions)
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

    local directToolService = createService({
        DirectBootTestToolsEnabled = true,
    })
    local directToolPlayer = createPlayer(101, 'Alpha')
    directToolService:_addPlayerState(directToolPlayer)
    local directInventory = directToolService.InventoryService:getSummary(directToolPlayer)
    assert(directInventory.Count == 3, 'Direct boot should seed the empty test backpack')
    assert(
        directInventory.ToolCount == 3,
        'Direct boot should seed flashlight/crowbar/potion tools'
    )

    local formalEntryService = createService({
        DirectBootTestToolsEnabled = true,
    })
    formalEntryService.IsDirectBoot = false
    local formalEntryPlayer = createPlayer(202, 'Bravo')
    formalEntryService:_addPlayerState(formalEntryPlayer)
    local formalInventory = formalEntryService.InventoryService:getSummary(formalEntryPlayer)
    assert(
        formalInventory.Count == 0,
        'Formal Maze entry should not receive direct-boot test tools'
    )

    local snapshotService = createService()
    snapshotService.IsLaunched = true
    local missingStateSnapshot = snapshotService:_buildSnapshotFor(createPlayer(303, 'Charlie'), {
        MazeStatus = 'active',
        ReturnedPlayerSummaries = {},
        Roster = {},
        SessionPhase = 'MazeActive',
        WorldBuildFields = {},
    })
    assert(
        missingStateSnapshot.PlayerState == nil,
        'Snapshot should tolerate players whose player runtime has not been added yet'
    )
    assert(
        type(missingStateSnapshot.Movement) == 'table',
        'Snapshot should still provide safe movement fallback data'
    )

    local localReturnService = createService({
        DirectBootLocalReturnEnabled = true,
        DirectBootTestToolsEnabled = false,
    })
    local localReturnPlayer = createPlayer(404, 'Delta')
    localReturnService:_addPlayerState(localReturnPlayer)
    assert(
        localReturnService.RunTracker:beginExpedition() == true,
        'Local return spec should enter expedition'
    )
    local teleportCalled = false
    localReturnService._teleportToCamp = function()
        teleportCalled = true
        return true
    end

    localReturnService:_returnPlayerToRunEntrance(localReturnPlayer, 'returned')
    assert(teleportCalled == false, 'Direct boot return should stay local instead of teleporting')
    assert(
        string.find(localReturnService.Status, 'local Maze PlayTest', 1, true) ~= nil,
        'Direct boot return should report local PlayTest completion'
    )
end
