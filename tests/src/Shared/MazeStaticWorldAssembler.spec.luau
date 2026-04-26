return function()
    local ReplicatedStorage = game:GetService('ReplicatedStorage')
    local Workspace = game:GetService('Workspace')

    local packages = ReplicatedStorage:WaitForChild('Packages')
    local shared = require(packages:WaitForChild('Shared'))
    local mazeModules = ReplicatedStorage:WaitForChild('PlaceModules'):WaitForChild('Maze')
    local MazeStaticWorldAssembler = require(mazeModules:WaitForChild('MazeStaticWorldAssembler'))
    local MazeStaticWorldContract = require(mazeModules:WaitForChild('MazeStaticWorldContract'))
    local MazeWorldBuilder = require(mazeModules:WaitForChild('MazeWorldBuilder'))

    local function createAuthoredRoot()
        local root = Instance.new('Folder')
        root.Name = MazeStaticWorldContract.RootName
        root.Parent = Workspace

        local spawnMarker = Instance.new('Part')
        spawnMarker.Name = 'SpawnMarker'
        spawnMarker.Anchored = true
        spawnMarker.CFrame = CFrame.new(-12, 4, 0)
        spawnMarker.Parent = root

        local returnHoldPad = Instance.new('Part')
        returnHoldPad.Name = 'ReturnHoldPad'
        returnHoldPad.Anchored = true
        returnHoldPad.CFrame = CFrame.new(-12, 0.5, -10)
        returnHoldPad.Parent = root
        Instance.new('ProximityPrompt').Parent = returnHoldPad

        local sceneryRoot = Instance.new('Folder')
        sceneryRoot.Name = MazeStaticWorldContract.SceneryFolderName
        sceneryRoot.Parent = root

        local floor = Instance.new('Part')
        floor.Name = 'Floor'
        floor.Anchored = true
        floor.Size = Vector3.new(64, 1, 64)
        floor.CFrame = CFrame.new(0, 0, 0)
        floor.Parent = sceneryRoot

        local campRoom = Instance.new('Model')
        campRoom.Name = 'Room_Camp'
        campRoom:SetAttribute('RoomType', 'OpenHub')
        campRoom:SetAttribute('IsCamp', true)
        campRoom:SetAttribute('DifficultyTier', 0)
        campRoom.Parent = root

        local campShell = Instance.new('Part')
        campShell.Name = 'Shell'
        campShell.Anchored = true
        campShell.Size = Vector3.new(20, 12, 20)
        campShell.CFrame = CFrame.new(-20, 6, 0)
        campShell.Parent = campRoom

        local lootRoom = Instance.new('Model')
        lootRoom.Name = 'Room_Loot'
        lootRoom:SetAttribute('RoomType', 'DeadEnd')
        lootRoom:SetAttribute('DifficultyTier', 2)
        lootRoom:SetAttribute('MonsterBudget', 2)
        lootRoom:SetAttribute('LootBudget', 1)
        lootRoom.Parent = root

        local lootShell = Instance.new('Part')
        lootShell.Name = 'Shell'
        lootShell.Anchored = true
        lootShell.Size = Vector3.new(24, 12, 24)
        lootShell.CFrame = CFrame.new(12, 6, 0)
        lootShell.Parent = lootRoom

        local monsterSpawns = Instance.new('Folder')
        monsterSpawns.Name = 'MonsterSpawns'
        monsterSpawns.Parent = lootRoom

        local spawnPoint = Instance.new('Part')
        spawnPoint.Name = 'SpawnPoint_1'
        spawnPoint.Anchored = true
        spawnPoint.CFrame = CFrame.new(8, 2, 0)
        spawnPoint.Parent = monsterSpawns

        local lootSocket = Instance.new('Part')
        lootSocket.Name = 'LootSocket_1'
        lootSocket.Anchored = true
        lootSocket.CFrame = CFrame.new(16, 2, 0)
        lootSocket.Parent = lootRoom

        local lootPromptPart = Instance.new('Part')
        lootPromptPart.Name = 'LootPrompt'
        lootPromptPart.Anchored = true
        lootPromptPart.CFrame = CFrame.new(16, 2, 0)
        lootPromptPart.Parent = lootRoom
        Instance.new('ProximityPrompt').Parent = lootPromptPart

        local doorwayPart = Instance.new('Part')
        doorwayPart.Name = 'Doorway_East'
        doorwayPart.Anchored = true
        doorwayPart.CFrame = CFrame.new(22, 4, 0)
        doorwayPart.Parent = lootRoom
        Instance.new('ProximityPrompt').Parent = doorwayPart

        return root, sceneryRoot, floor
    end

    local authoredRoot, authoredSceneryRoot, authoredFloor = createAuthoredRoot()
    local mazeAssets = ReplicatedStorage.Assets.Maze
    local chunkAssets = mazeAssets:FindFirstChild('Chunks')
    local overlayAssets = mazeAssets:FindFirstChild('Overlays')

    if chunkAssets ~= nil then
        chunkAssets.Parent = nil
    end
    if overlayAssets ~= nil then
        overlayAssets.Parent = nil
    end

    local authoredOk, authoredResult = pcall(function()
        return MazeStaticWorldAssembler.assemble()
    end)

    if chunkAssets ~= nil then
        chunkAssets.Parent = mazeAssets
    end
    if overlayAssets ~= nil then
        overlayAssets.Parent = mazeAssets
    end

    assert(
        authoredOk == true,
        string.format(
            'Assembler should prefer authored Workspace content: %s',
            tostring(authoredResult)
        )
    )
    assert(
        authoredResult == authoredRoot,
        'Assembler should reuse the existing authored MazeStaticWorld instead of rebuilding it'
    )
    assert(
        authoredRoot:FindFirstChild(MazeStaticWorldContract.SceneryFolderName)
            == authoredSceneryRoot,
        'Existing authored worlds should keep their scenery folder'
    )
    assert(
        authoredFloor.Parent == authoredSceneryRoot,
        'Existing authored scenery should remain in place when the assembler reuses the root'
    )

    local authoredRoomIds = shared.Runtime.MazeWorldScanner.GetRoomIds(
        shared.Runtime.MazeWorldScanner.Scan(authoredRoot)
    )
    assert(
        #authoredRoomIds == 2,
        'Authored roots should still expose only gameplay rooms to the runtime scanner'
    )

    local authoredScene = MazeWorldBuilder.build()
    assert(
        authoredScene.Root == authoredRoot,
        'World builder should reuse the authored MazeStaticWorld when it is already present'
    )
    assert(
        authoredScene:getLootNode('Room_Loot') ~= nil,
        'World builder should still produce gameplay nodes from the authored MazeStaticWorld'
    )

    authoredRoot:Destroy()

    local root = MazeStaticWorldAssembler.assemble()
    assert(
        root.Name == MazeStaticWorldContract.RootName,
        'Assembler should create MazeStaticWorld root'
    )

    local sceneryRoot = root:FindFirstChild(MazeStaticWorldContract.SceneryFolderName)
    assert(
        sceneryRoot ~= nil and sceneryRoot:IsA('Folder'),
        'Assembler should place geometry chunks under MazeStaticWorld/Scenery'
    )

    local chunkModel = sceneryRoot:FindFirstChild('maze.3dm')
    assert(
        chunkModel ~= nil and chunkModel:IsA('Model'),
        'Assembler should clone the enabled manifest chunk into the scenery root'
    )

    local geometryGroups = {
        terrain = false,
        walls = false,
        water = false,
    }
    for groupName in pairs(geometryGroups) do
        local group = chunkModel:FindFirstChild(groupName)
        geometryGroups[groupName] = group ~= nil and group:IsA('Model')
    end
    assert(
        geometryGroups.terrain and geometryGroups.walls and geometryGroups.water,
        'First maze chunk should preserve terrain/walls/water geometry groupings'
    )

    local scanResult = shared.Runtime.MazeWorldScanner.Scan(root)
    local roomIds = shared.Runtime.MazeWorldScanner.GetRoomIds(scanResult)
    assert(
        #roomIds == 2,
        'Assembler should expose the overlay rooms without treating scenery as rooms'
    )
    assert(
        table.find(roomIds, 'maze.3dm') == nil,
        'Geometry chunk containers under Scenery must be ignored by the runtime scanner'
    )

    local world = shared.Runtime.MazeWorldScanner.BuildStaticWorld(root)
    assert(
        world.LootNodes.Room_Loot ~= nil,
        'Assembled world should still expose overlay-authored loot nodes'
    )
    assert(
        world.Doorways['Room_Loot:Doorway_East'] ~= nil,
        'Assembled world should still expose overlay-authored doorway nodes'
    )

    local scene = MazeWorldBuilder.build()
    assert(
        scene.Root.Name == MazeStaticWorldContract.RootName,
        'World builder should assemble before scanning'
    )
    assert(
        scene:getLootNode('Room_Loot') ~= nil,
        'World builder should produce a MazeScene from the assembled static world'
    )

    root:Destroy()

    local overlayAsset = ReplicatedStorage.Assets.Maze.Overlays:FindFirstChild(
        MazeStaticWorldContract.OverlayAssetName
    )
    assert(
        overlayAsset ~= nil,
        'Tests should mount the maze overlay asset in ReplicatedStorage.Assets.Maze'
    )

    local savedSpawnMarker = overlayAsset:FindFirstChild('SpawnMarker')
    local spawnMarkerClone = savedSpawnMarker and savedSpawnMarker:Clone()
    if savedSpawnMarker ~= nil then
        savedSpawnMarker:Destroy()
    end

    local brokenOk, brokenErr = pcall(function()
        MazeStaticWorldAssembler.assemble()
    end)

    if spawnMarkerClone ~= nil then
        spawnMarkerClone.Parent = overlayAsset
    end

    assert(
        brokenOk == false,
        'Assembler should fail loudly when the overlay asset is missing a required authored marker'
    )
    assert(
        string.find(tostring(brokenErr), 'SpawnMarker', 1, true) ~= nil,
        'Missing overlay marker failures should mention the missing authored node'
    )

    local brokenRoot = Workspace:FindFirstChild(MazeStaticWorldContract.RootName)
    if brokenRoot ~= nil then
        brokenRoot:Destroy()
    end

    local invalidRoot = Instance.new('Folder')
    invalidRoot.Name = MazeStaticWorldContract.RootName
    invalidRoot.Parent = Workspace

    local invalidReturnHoldPad = Instance.new('Part')
    invalidReturnHoldPad.Name = 'ReturnHoldPad'
    invalidReturnHoldPad.Anchored = true
    invalidReturnHoldPad.Parent = invalidRoot
    Instance.new('ProximityPrompt').Parent = invalidReturnHoldPad

    local invalidRoom = Instance.new('Model')
    invalidRoom.Name = 'Room_Loot'
    invalidRoom:SetAttribute('RoomType', 'DeadEnd')
    invalidRoom.Parent = invalidRoot

    local invalidShell = Instance.new('Part')
    invalidShell.Name = 'Shell'
    invalidShell.Anchored = true
    invalidShell.Parent = invalidRoom

    local invalidMonsterSpawns = Instance.new('Folder')
    invalidMonsterSpawns.Name = 'MonsterSpawns'
    invalidMonsterSpawns.Parent = invalidRoom

    local invalidSpawnPoint = Instance.new('Part')
    invalidSpawnPoint.Name = 'SpawnPoint_1'
    invalidSpawnPoint.Anchored = true
    invalidSpawnPoint.Parent = invalidMonsterSpawns

    local invalidLootSocket = Instance.new('Part')
    invalidLootSocket.Name = 'LootSocket_1'
    invalidLootSocket.Anchored = true
    invalidLootSocket.Parent = invalidRoom

    local invalidLootPrompt = Instance.new('Part')
    invalidLootPrompt.Name = 'LootPrompt'
    invalidLootPrompt.Anchored = true
    invalidLootPrompt.Parent = invalidRoom
    Instance.new('ProximityPrompt').Parent = invalidLootPrompt

    local invalidDoorway = Instance.new('Part')
    invalidDoorway.Name = 'Doorway_East'
    invalidDoorway.Anchored = true
    invalidDoorway.Parent = invalidRoom
    Instance.new('ProximityPrompt').Parent = invalidDoorway

    local invalidExistingOk, invalidExistingErr = pcall(function()
        MazeStaticWorldAssembler.assemble()
    end)

    assert(
        invalidExistingOk == false,
        'Assembler should fail loudly when an authored MazeStaticWorld exists but is incomplete'
    )
    assert(
        string.find(tostring(invalidExistingErr), 'SpawnMarker', 1, true) ~= nil,
        'Incomplete authored root failures should still identify the missing authored node'
    )

    invalidRoot:Destroy()

    local finalRoot = Workspace:FindFirstChild(MazeStaticWorldContract.RootName)
    if finalRoot ~= nil then
        finalRoot:Destroy()
    end
end
