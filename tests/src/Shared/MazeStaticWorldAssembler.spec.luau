return function()
    local ReplicatedStorage = game:GetService('ReplicatedStorage')
    local Workspace = game:GetService('Workspace')

    local packages = ReplicatedStorage:WaitForChild('Packages')
    local shared = require(packages:WaitForChild('Shared'))
    local mazeModules = ReplicatedStorage:WaitForChild('PlaceModules'):WaitForChild('Maze')
    local MazeStaticWorldAssembler = require(mazeModules:WaitForChild('MazeStaticWorldAssembler'))
    local MazeStaticWorldContract = require(mazeModules:WaitForChild('MazeStaticWorldContract'))
    local MazeStaticWorldOverlayManifest =
        require(mazeModules:WaitForChild('MazeStaticWorldOverlayManifest'))
    local MazeWorldBuilder = require(mazeModules:WaitForChild('MazeWorldBuilder'))

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
        #MazeStaticWorldOverlayManifest.FirstPlayableChain == 5,
        'Overlay manifest should publish the first playable payoff chain'
    )
    assert(
        MazeStaticWorldOverlayManifest.FirstPlayableChain[4].PayoffHintId == 'sound-predator',
        'Overlay manifest should bind the first payoff chain to the sound predator hint'
    )
    assert(
        MazeStaticWorldOverlayManifest.FirstPlayableChain[5].TargetId == 'ReturnHoldPad',
        'Overlay manifest should make return decision an explicit authored node'
    )
    assert(
        root:FindFirstChild('Room_Camp'):GetAttribute('EncounterRole') == 'EntryBuffer',
        'Assembler should apply the entry buffer role to the camp room'
    )
    assert(
        root:FindFirstChild('Room_Loot'):GetAttribute('PayoffHintId') == 'sound-predator',
        'Assembler should apply the first sound-predator payoff metadata to the loot room'
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

    local finalRoot = Workspace:FindFirstChild(MazeStaticWorldContract.RootName)
    if finalRoot ~= nil then
        finalRoot:Destroy()
    end
end
