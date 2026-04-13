return function()
    local ReplicatedStorage = game:GetService('ReplicatedStorage')
    local Workspace = game:GetService('Workspace')

    local packages = ReplicatedStorage:WaitForChild('Packages')
    local shared = require(packages:WaitForChild('Shared'))
    local scanner = shared.Runtime.MazeWorldScanner

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
    })

    local lootRoom = createRoom('Room_Loot', 'DeadEnd', Vector3.new(24, 6, 24), {
        MonsterBudget = 2,
        DifficultyTier = 2,
        RoomTemplateId = 'SearchCluster',
        RoomCategory = 'SearchCluster',
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
        DifficultyTier = 1,
    })

    local extractionMarker = Instance.new('Part')
    extractionMarker.Name = 'ExtractionMarker'
    extractionMarker.Anchored = true
    extractionMarker.Position = Vector3.new(48, 2, 24)
    extractionMarker.Parent = extractionRoom

    local extractionPrompt = Instance.new('ProximityPrompt')
    extractionPrompt.Parent = extractionMarker

    local world = scanner.BuildStaticWorld(root)

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
        world.RoomById.Room_Extraction.Kind == 'Extraction',
        'Extraction room should preserve its authored extraction kind'
    )
    assert(
        world.FindRoomByPosition(Vector3.new(24, 2, 24)).Id == 'Room_Loot',
        'Room lookup should resolve the nearest authored room'
    )
    assert(world.LootNodes.Room_Loot ~= nil, 'Loot rooms should create loot runtime nodes')
    assert(
        world.LootNodes.Room_Loot.Prompt == lootPrompt,
        'Loot runtime nodes should preserve the authored loot prompt'
    )
    assert(
        next(world.ExtractionNodes) ~= nil,
        'Static maze world should expose authored extraction nodes'
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
end
