return function()
    local ReplicatedStorage = game:GetService('ReplicatedStorage')
    local Workspace = game:GetService('Workspace')

    local packages = ReplicatedStorage:WaitForChild('Packages')
    local shared = require(packages:WaitForChild('Shared'))
    local scanner = shared.Runtime.MazeWorldScanner
    local mazeModules = ReplicatedStorage:WaitForChild('PlaceModules'):WaitForChild('Maze')
    local overlayManifest = require(mazeModules:WaitForChild('MazeStaticWorldOverlayManifest'))

    local expectedChainSteps = {
        'EntryBuffer',
        'Warning',
        'PagesTemptation',
        'SoundPredatorPayoff',
        'ReturnDecision',
    }
    assert(
        #overlayManifest.FirstPlayableChain == #expectedChainSteps,
        'First playable chain should expose exactly five authored payoff steps'
    )
    for index, expectedStepId in ipairs(expectedChainSteps) do
        assert(
            overlayManifest.FirstPlayableChain[index].StepId == expectedStepId,
            'First playable chain should preserve the deadline-slice step order'
        )
    end
    assert(
        overlayManifest.FirstPlayableChain[4].TargetId == 'Room_Loot'
            and overlayManifest.FirstPlayableChain[4].PayoffHintId == 'sound-predator',
        'Sound predator payoff should point at the authored loot room and hint id'
    )
    assert(
        overlayManifest.Rooms.Room_Loot.PayoffHintId
            == overlayManifest.FirstPlayableChain[4].PayoffHintId,
        'First playable chain payoff should match Room_Loot authored payoff metadata'
    )
    assert(
        overlayManifest.FirstPlayableChain[5].TargetId == 'ReturnHoldPad',
        'Return decision should point at the authored return hold node'
    )

    local root = Instance.new('Folder')
    root.Name = 'MazeStaticWorld'
    root.Parent = Workspace

    local spawnMarker = Instance.new('Part')
    spawnMarker.Name = 'SpawnMarker'
    spawnMarker.Anchored = true
    spawnMarker.CFrame = CFrame.new(0, 4, 0)
    spawnMarker.Parent = root

    local returnHoldPad = Instance.new('Part')
    returnHoldPad.Name = 'ReturnHoldPad'
    returnHoldPad.Anchored = true
    returnHoldPad.CFrame = CFrame.new(0, 0.5, -12)
    returnHoldPad.Parent = root

    local returnPrompt = Instance.new('ProximityPrompt')
    returnPrompt.Parent = returnHoldPad

    local function createRoom(name, roomTag, center, attributes)
        local room = Instance.new('Model')
        room.Name = name
        room:AddTag('RoomType/' .. roomTag)

        for attributeName, attributeValue in pairs(attributes or {}) do
            room:SetAttribute(attributeName, attributeValue)
        end

        local shell = Instance.new('Part')
        shell.Name = 'Shell'
        shell.Anchored = true
        shell.Size = Vector3.new(18, 12, 18)
        shell.Position = center
        shell.Parent = room

        room.Parent = root
        return room
    end

    createRoom('Room_Camp', 'OpenHub', Vector3.new(0, 6, 24), {
        IsCamp = true,
        DifficultyTier = 0,
        EncounterRole = 'EntryBuffer',
    })

    local lootRoom = createRoom('Room_Loot', 'DeadEnd', Vector3.new(24, 6, 24), {
        MonsterBudget = 2,
        DifficultyTier = 2,
        RoomTemplateId = 'SearchCluster',
        RoomCategory = 'SearchCluster',
        EncounterRole = 'WarningPayoffResourceTemptation',
        PayoffHintId = 'sound-predator',
    })
    lootRoom:AddTag('HasMonsterSpawner')

    local monsterSpawns = Instance.new('Folder')
    monsterSpawns.Name = 'MonsterSpawns'
    monsterSpawns.Parent = lootRoom

    local patrolPoint = Instance.new('Part')
    patrolPoint.Name = 'SpawnPoint_1'
    patrolPoint.Anchored = true
    patrolPoint.Position = Vector3.new(24, 2, 24)
    patrolPoint.Parent = monsterSpawns

    local lootSocket = Instance.new('Part')
    lootSocket.Name = 'LootSocket_1'
    lootSocket.Anchored = true
    lootSocket.Position = Vector3.new(26, 2, 24)
    lootSocket.Parent = lootRoom

    local lootPromptPart = Instance.new('Part')
    lootPromptPart.Name = 'LootPrompt'
    lootPromptPart.Anchored = true
    lootPromptPart.Position = Vector3.new(26, 2, 24)
    lootPromptPart.Parent = lootRoom

    local lootPrompt = Instance.new('ProximityPrompt')
    lootPrompt.Parent = lootPromptPart

    local doorwayPart = Instance.new('Part')
    doorwayPart.Name = 'Doorway_East'
    doorwayPart.Anchored = true
    doorwayPart.Position = Vector3.new(32, 4, 24)
    doorwayPart.Parent = lootRoom

    local doorwayPrompt = Instance.new('ProximityPrompt')
    doorwayPrompt.Parent = doorwayPart

    local scenery = Instance.new('Folder')
    scenery.Name = 'Scenery'
    scenery.Parent = root

    local fakeSceneryRoom = Instance.new('Model')
    fakeSceneryRoom.Name = 'Room_SceneryFake'
    fakeSceneryRoom:SetAttribute('RoomType', 'DeadEnd')
    fakeSceneryRoom.Parent = scenery

    local fakeSceneryShell = Instance.new('Part')
    fakeSceneryShell.Name = 'Shell'
    fakeSceneryShell.Anchored = true
    fakeSceneryShell.Position = Vector3.new(60, 6, 24)
    fakeSceneryShell.Parent = fakeSceneryRoom

    local world = scanner.BuildStaticWorld(root)
    local scanResult = scanner.Scan(root)
    local roomIds = scanner.GetRoomIds(scanResult)

    assert(world.Root == root, 'Static maze world should preserve the authored root')
    assert(
        world.SpawnCFrame == spawnMarker.CFrame,
        'Static maze world should expose the authored spawn marker'
    )
    assert(
        world.ReturnHoldPad.Prompt == returnPrompt,
        'Static maze world should expose the return hold prompt'
    )
    assert(
        world.RoomById.Room_Camp.Kind == 'Camp',
        'Camp room should preserve its authored camp kind'
    )
    assert(
        world.FindRoomByPosition(Vector3.new(24, 2, 24)).Id == 'Room_Loot',
        'Room lookup should resolve the nearest authored room'
    )
    assert(world.LootNodes.Room_Loot ~= nil, 'Loot rooms should create loot runtime nodes')
    assert(
        table.find(roomIds, 'Room_SceneryFake') == nil,
        'Scanner should ignore scenery-authored geometry folders even when they contain room-like metadata'
    )
    assert(
        world.RoomById.Room_SceneryFake == nil,
        'BuildStaticWorld should not promote scenery-only content into gameplay rooms'
    )
    assert(
        world.LootNodes.Room_Loot.Prompt == lootPrompt,
        'Loot runtime nodes should preserve the authored loot prompt'
    )
    assert(
        #(world.PatrolPoints or {}) == 1,
        'Static maze world should flatten authored patrol anchors'
    )
    assert(
        world.InitialMonsterPatrolIndex == 1,
        'Static maze world should point monster startup at the first authored patrol point'
    )

    local doorwayId = 'Room_Loot:Doorway_East'
    assert(
        world.Doorways[doorwayId] ~= nil,
        'Static maze world should register authored doorway controls'
    )
    assert(
        world.Doorways[doorwayId].Prompt == doorwayPrompt,
        'Authored doorway prompts should be preserved'
    )
    assert(world.ToggleDoor(doorwayId) == true, 'Static maze world should toggle authored doors')
    assert(doorwayPart.CanCollide == false, 'Toggling authored doors should release collision')

    root:Destroy()

    local invalidRoot = Instance.new('Folder')
    invalidRoot.Name = 'MazeStaticWorld'
    invalidRoot.Parent = Workspace

    local invalidSpawnMarker = Instance.new('Part')
    invalidSpawnMarker.Name = 'SpawnMarker'
    invalidSpawnMarker.Anchored = true
    invalidSpawnMarker.Parent = invalidRoot

    local invalidReturnHoldPad = Instance.new('Part')
    invalidReturnHoldPad.Name = 'ReturnHoldPad'
    invalidReturnHoldPad.Anchored = true
    invalidReturnHoldPad.Parent = invalidRoot

    Instance.new('ProximityPrompt').Parent = invalidReturnHoldPad

    local invalidMonsterRoom =
        createRoom('Room_InvalidMonster', 'DeadEnd', Vector3.new(24, 6, 24), {
            MonsterBudget = 2,
            DifficultyTier = 2,
        })
    invalidMonsterRoom.Parent = invalidRoot
    invalidMonsterRoom:AddTag('HasMonsterSpawner')

    local directSpawnPoint = Instance.new('Part')
    directSpawnPoint.Name = 'SpawnPoint_1'
    directSpawnPoint.Anchored = true
    directSpawnPoint.Position = Vector3.new(24, 2, 24)
    directSpawnPoint.Parent = invalidMonsterRoom

    local invalidLootSocket = Instance.new('Part')
    invalidLootSocket.Name = 'LootSocket_1'
    invalidLootSocket.Anchored = true
    invalidLootSocket.Position = Vector3.new(26, 2, 24)
    invalidLootSocket.Parent = invalidMonsterRoom

    local invalidLootPromptPart = Instance.new('Part')
    invalidLootPromptPart.Name = 'LootPrompt'
    invalidLootPromptPart.Anchored = true
    invalidLootPromptPart.Position = Vector3.new(26, 2, 24)
    invalidLootPromptPart.Parent = invalidMonsterRoom

    Instance.new('ProximityPrompt').Parent = invalidLootPromptPart

    local invalidOk, invalidErr = pcall(function()
        scanner.BuildStaticWorld(invalidRoot)
    end)

    assert(
        invalidOk == false,
        'Static maze world build should fail loudly when monster rooms miss MonsterSpawns'
    )
    assert(
        string.find(tostring(invalidErr), 'MonsterSpawns/SpawnPoint_*', 1, true) ~= nil,
        'Missing monster patrol anchors should mention the MonsterSpawns contract'
    )
    assert(
        string.find(tostring(invalidErr), 'Room_InvalidMonster', 1, true) ~= nil,
        'Missing monster patrol anchors should identify the authored room'
    )

    invalidRoot:Destroy()

    local deprecatedRoot = Instance.new('Folder')
    deprecatedRoot.Name = 'MazeStaticWorld'
    deprecatedRoot.Parent = Workspace

    local deprecatedSpawnMarker = Instance.new('Part')
    deprecatedSpawnMarker.Name = 'SpawnMarker'
    deprecatedSpawnMarker.Anchored = true
    deprecatedSpawnMarker.Parent = deprecatedRoot

    local deprecatedReturnHoldPad = Instance.new('Part')
    deprecatedReturnHoldPad.Name = 'ReturnHoldPad'
    deprecatedReturnHoldPad.Anchored = true
    deprecatedReturnHoldPad.Parent = deprecatedRoot

    Instance.new('ProximityPrompt').Parent = deprecatedReturnHoldPad

    local deprecatedRoom =
        createRoom('Room_Deprecated', 'Straight', Vector3.new(48, 6, 24), { DifficultyTier = 1 })
    deprecatedRoom.Parent = deprecatedRoot

    local deprecatedExtractionMarker = Instance.new('Part')
    deprecatedExtractionMarker.Name = 'ExtractionMarker'
    deprecatedExtractionMarker.Anchored = true
    deprecatedExtractionMarker.Position = Vector3.new(48, 2, 24)
    deprecatedExtractionMarker.Parent = deprecatedRoom

    Instance.new('ProximityPrompt').Parent = deprecatedExtractionMarker

    local deprecatedOk, deprecatedErr = pcall(function()
        scanner.BuildStaticWorld(deprecatedRoot)
    end)

    assert(
        deprecatedOk == false,
        'Static maze world build should fail loudly when deprecated extraction markers remain'
    )
    assert(
        string.find(tostring(deprecatedErr), 'ExtractionMarker', 1, true) ~= nil,
        'Deprecated extraction marker failures should mention the authored node'
    )

    deprecatedRoot:Destroy()
end
