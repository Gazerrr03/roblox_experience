return function()
    local ReplicatedStorage = game:GetService('ReplicatedStorage')
    local Workspace = game:GetService('Workspace')

    local packages = ReplicatedStorage:WaitForChild('Packages')
    local shared = require(packages:WaitForChild('Shared'))
    local mazeModules = ReplicatedStorage:WaitForChild('PlaceModules'):WaitForChild('Maze')
    local MazeScene = require(mazeModules:WaitForChild('MazeScene'))

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
    returnHoldPad.CFrame = CFrame.new(0, 1, -12)
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

    local lootRoom = createRoom('Room_Loot', 'DeadEnd', Vector3.new(24, 6, 24), {
        MonsterBudget = 2,
        DifficultyTier = 2,
    })
    lootRoom:AddTag('HasMonsterSpawner')

    local patrolPoint = Instance.new('Part')
    patrolPoint.Name = 'SpawnPoint_1'
    patrolPoint.Anchored = true
    patrolPoint.Position = Vector3.new(24, 2, 24)
    patrolPoint.Parent = lootRoom

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

    local extractionRoom = createRoom('Room_Extraction', 'Straight', Vector3.new(48, 6, 24), {
        IsExtraction = true,
    })

    local extractionMarker = Instance.new('Part')
    extractionMarker.Name = 'ExtractionMarker'
    extractionMarker.Anchored = true
    extractionMarker.Position = Vector3.new(48, 2, 24)
    extractionMarker.Parent = extractionRoom

    local extractionPrompt = Instance.new('ProximityPrompt')
    extractionPrompt.Parent = extractionMarker

    local rawWorld = shared.Runtime.MazeWorldScanner.BuildStaticWorld(root)
    local scene = MazeScene.new(rawWorld)

    assert(
        scene.SpawnCFrame == spawnMarker.CFrame,
        'MazeScene should expose the authored spawn marker'
    )
    assert(
        scene.ReturnHoldPad.Prompt == returnPrompt,
        'MazeScene should preserve the authored return hold prompt'
    )
    assert(
        scene:findRoomByPosition(Vector3.new(24, 2, 24)).Id == 'Room_Loot',
        'MazeScene should resolve authored rooms by position'
    )
    assert(
        scene:getLootNode('Room_Loot').Prompt == lootPrompt,
        'MazeScene should index authored loot nodes'
    )
    local extractionNode = select(2, next(scene.ExtractionNodes))
    assert(
        extractionNode ~= nil and extractionNode.Prompt == extractionPrompt,
        'MazeScene should index authored extraction nodes'
    )
    assert(
        scene:toggleDoor('Room_Loot:Doorway_East') == true,
        'MazeScene should toggle authored doors'
    )
    assert(doorwayPart.CanCollide == false, 'MazeScene doorway toggles should release collision')

    root:Destroy()

    local invalidRoot = Instance.new('Folder')
    invalidRoot.Name = 'MazeStaticWorld'
    invalidRoot.Parent = Workspace

    local invalidSpawn = Instance.new('Part')
    invalidSpawn.Name = 'SpawnMarker'
    invalidSpawn.Anchored = true
    invalidSpawn.Parent = invalidRoot

    local invalidReturnHold = Instance.new('Part')
    invalidReturnHold.Name = 'ReturnHoldPad'
    invalidReturnHold.Anchored = true
    invalidReturnHold.Parent = invalidRoot

    local invalidReturnPrompt = Instance.new('ProximityPrompt')
    invalidReturnPrompt.Parent = invalidReturnHold

    local invalidRoom = Instance.new('Model')
    invalidRoom.Name = 'Room_Only'
    invalidRoom:AddTag('RoomType/DeadEnd')
    invalidRoom.Parent = invalidRoot

    local invalidShell = Instance.new('Part')
    invalidShell.Name = 'Shell'
    invalidShell.Anchored = true
    invalidShell.Parent = invalidRoom

    local invalidRawWorld = shared.Runtime.MazeWorldScanner.BuildStaticWorld(invalidRoot)
    local ok, err = pcall(function()
        MazeScene.new(invalidRawWorld)
    end)
    assert(
        ok == false,
        'MazeScene should fail loudly when authored extraction or loot data is missing'
    )
    assert(
        string.find(tostring(err), 'extraction', 1, true) ~= nil
            or string.find(tostring(err), 'loot', 1, true) ~= nil,
        'MazeScene failures should mention the missing authored interaction category'
    )

    invalidRoot:Destroy()
end
