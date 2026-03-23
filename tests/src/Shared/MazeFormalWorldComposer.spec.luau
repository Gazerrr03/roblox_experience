return function()
    local Workspace = game:GetService('Workspace')
    local ReplicatedStorage = game:GetService('ReplicatedStorage')
    local packages = ReplicatedStorage:WaitForChild('Packages')
    local shared = require(packages:WaitForChild('Shared'))

    local runtime = packages:WaitForChild('Shared'):WaitForChild('Runtime')
    local composer = require(runtime:WaitForChild('MazeFormalWorldComposer'))

    local testRoot = Instance.new('Folder')
    testRoot.Name = 'MazeFormalWorldComposerSpecRoot'
    testRoot.Parent = Workspace

    local world = composer.build(12345, shared.Config.SessionConfig.ProcGen, {
        Parent = testRoot,
        WorldName = 'MazeFormalWorldComposerSpecWorld',
        IncludeRoomMarkers = false,
    })

    assert(
        world.Root ~= nil and world.Root.Parent == testRoot,
        'Formal world should build under the requested parent'
    )
    assert(world.ReturnPrompt == nil, 'Formal world should not expose the debug return prompt')
    assert(
        world.ReturnHoldPad ~= nil and world.ReturnHoldPad.Prompt ~= nil,
        'Formal world should create an interactable return hold pad for run-gate returns'
    )
    assert(
        type(world.InitialMonsterPatrolIndex) == 'number',
        'Formal world should export the initial monster patrol slot'
    )
    assert(
        type(world.InitialMonsterSpawnRoomId) == 'string',
        'Formal world should export the room chosen for initial monster spawn'
    )
    assert(next(world.RoomAffordances or {}) ~= nil, 'Formal world should expose room affordances')
    assert(next(world.LootNodes or {}) ~= nil, 'Formal world should create loot nodes')
    assert(next(world.ExtractionNodes or {}) ~= nil, 'Formal world should create extraction nodes')
    assert(
        world.Root:FindFirstChild('DeployConsole', true) == nil,
        'Formal world should not recreate the legacy deploy console'
    )
    assert(
        world.Root:FindFirstChild('ReturnMarker', true) == nil,
        'Formal world should not recreate the legacy return marker'
    )
    assert(
        world.Root:FindFirstChild('ExtractionPad', true) == nil,
        'Formal world should not recreate the legacy extraction pad'
    )

    local extractionCount = 0
    for _, extractionNode in pairs(world.ExtractionNodes) do
        extractionCount += 1
        assert(extractionNode.Prompt ~= nil, 'Extraction nodes should expose a prompt')
        assert(
            extractionNode.Prompt.ObjectText == 'Run Entrance',
            'Formal extraction prompt should point players back to the run entrance'
        )
        assert(
            extractionNode.Prompt.ActionText == 'Return',
            'Formal extraction prompt should align with the shared return semantics'
        )
    end

    assert(
        world.ReturnHoldPad.Prompt.ObjectText == 'Run Entrance',
        'The blue return pad should point players back to the run entrance'
    )

    assert(extractionCount >= 1, 'Formal world should include at least one extraction node')
    assert(
        world.InitialMonsterSpawnRoomId ~= world.CampRoomId,
        'Initial monster spawn should never use the camp room'
    )

    local campRoom = world.RoomById[world.CampRoomId]
    for _, neighborRoomId in pairs(campRoom.Neighbors or {}) do
        assert(
            world.InitialMonsterSpawnRoomId ~= neighborRoomId,
            'Initial monster spawn should avoid rooms adjacent to the camp room'
        )
    end

    local patrolPointCount = 0
    local expectedPatrolPointCount = 0
    local controlPointCount = 0
    local lootAffordanceCount = 0

    for _, patrolPoint in ipairs(world.PatrolPoints or {}) do
        patrolPointCount += 1
        assert(typeof(patrolPoint) == 'Vector3', 'Patrol points should remain vector positions')
    end

    for _, roomId in ipairs(world.RoomIds) do
        local affordance = world.RoomAffordances[roomId]
        local room = world.RoomById[roomId]

        assert(affordance ~= nil, string.format('Room %s should have an affordance entry', roomId))
        assert(affordance.RoomId == roomId, 'Affordance should preserve the room id')
        assert(
            affordance.RoomKind == room.Kind,
            'Affordance should expose the same room kind as the world shell'
        )
        assert(
            affordance.RoomCenter == world.RoomCenters[roomId],
            'Affordance should expose the room center'
        )
        assert(
            #(affordance.SpawnSockets or {}) >= 1,
            'Each room should expose a primary spawn socket'
        )
        assert(
            #(affordance.SightBreakers or {}) == 0,
            'Sight breakers should be an explicit empty list until authored sources exist'
        )
        assert(
            #(affordance.ThreatTags or {}) >= 1,
            'Each affordance should expose at least one threat tag'
        )
        assert(
            affordance.ThreatTags[1] == string.format('RoomKind:%s', room.Kind),
            'Threat tags should currently derive from room kind only'
        )
        assert(
            type(affordance.TraversalMask) == 'table',
            'Each affordance should expose a traversal mask table'
        )
        assert(
            #(affordance.TraversalMask.NeighborRoomIds or {}) == room.DoorCount,
            'Traversal mask should expose one neighboring room id per connected doorway'
        )
        assert(
            #(affordance.TraversalMask.DoorwayIds or {}) == room.DoorCount,
            'Traversal mask should expose one doorway id per connected doorway'
        )
        assert(
            #(affordance.TraversalMask.ExitDirections or {}) == #(room.ExitDirections or {}),
            'Traversal mask should preserve external exit directions'
        )

        for _, doorwayId in ipairs(affordance.TraversalMask.DoorwayIds or {}) do
            assert(world.Doorways[doorwayId] ~= nil, 'Traversal mask doorway ids should be valid')
        end

        for _, controlPoint in ipairs(affordance.DoorControlPoints or {}) do
            controlPointCount += 1
            local doorway = world.Doorways[controlPoint.DoorwayId]
            assert(doorway ~= nil, 'Door control points should reference a valid doorway')
            assert(
                doorway.Prompt ~= nil,
                'Door control points should only expose interactable doorways'
            )
            assert(
                controlPoint.Position == doorway.Prompt.Parent.Position,
                'Door control points should expose the prompt position'
            )
        end

        if room.Kind == 'Loot' then
            lootAffordanceCount += 1
            expectedPatrolPointCount += 1
            assert(
                #(affordance.PatrolAnchors or {}) == 1,
                'Loot rooms should provide one patrol anchor in the minimal affordance pass'
            )

            local lootNode = world.LootNodes[roomId]
            assert(lootNode ~= nil, 'Loot rooms should still expose loot runtime nodes')
            assert(
                lootNode.Position == affordance.SpawnSockets[1].Position,
                'Loot node positions should derive from the room spawn socket'
            )
        else
            assert(
                #(affordance.PatrolAnchors or {}) == 0,
                'Non-loot rooms should not gain patrol anchors in the minimal affordance pass'
            )
        end
    end

    assert(lootAffordanceCount >= 1, 'Formal world should expose at least one loot affordance')
    assert(
        patrolPointCount == expectedPatrolPointCount,
        'Legacy patrol points should remain a flattened view of loot-room patrol anchors'
    )
    assert(
        world.InitialMonsterPatrolIndex >= 1 and world.InitialMonsterPatrolIndex <= patrolPointCount,
        'Initial monster patrol index should point into the flattened patrol-point list'
    )
    assert(
        controlPointCount >= 1,
        'Formal world affordances should expose at least one interactable door control point'
    )

    local ok, err = pcall(function()
        composer.build(12345, shared.Config.SessionConfig.ProcGen, {
            Parent = testRoot,
            WorldName = 'MazeFormalWorldComposerMissingAssets',
            RequireModuleAssets = true,
        })
    end)
    assert(
        ok == false,
        'Formal world should fail loudly when module assets are required but missing'
    )
    assert(
        string.find(tostring(err), 'no asset root was supplied', 1, true) ~= nil,
        'Formal world should explain the missing module asset root'
    )

    testRoot:Destroy()
end
