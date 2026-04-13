return function()
    local ReplicatedStorage = game:GetService('ReplicatedStorage')

    local runModules = ReplicatedStorage:WaitForChild('PlaceModules'):WaitForChild('Run')
    local RunScene = require(runModules:WaitForChild('RunScene'))
    local RunSpawnPoint = require(runModules:WaitForChild('RunSpawnPoint'))

    local root = Instance.new('Folder')
    root.Name = 'RunStaticWorld'
    root:SetAttribute('OutdoorThresholdZ', 50)

    local function createPromptPart(name, z)
        local part = Instance.new('Part')
        part.Name = name
        part.Anchored = true
        part.Position = Vector3.new(0, 4, z)
        part.Parent = root

        local prompt = Instance.new('ProximityPrompt')
        prompt.Parent = part

        return part, prompt
    end

    local spawnMarker = Instance.new('Part')
    spawnMarker.Name = 'SpawnMarker'
    spawnMarker.Anchored = true
    spawnMarker.CFrame = CFrame.new(0, 4, 0)
    spawnMarker.Parent = root

    local returnMarker = Instance.new('Part')
    returnMarker.Name = 'ReturnMarker'
    returnMarker.Anchored = true
    returnMarker.CFrame = CFrame.new(0, 4, 8)
    returnMarker.Parent = root

    local mazeReturnMarker = Instance.new('Part')
    mazeReturnMarker.Name = 'MazeReturnMarker'
    mazeReturnMarker.Anchored = true
    mazeReturnMarker.CFrame = CFrame.new(0, 4, 64)
    mazeReturnMarker.Parent = root

    local doorLeft = Instance.new('Part')
    doorLeft.Name = 'DoorLeft'
    doorLeft.Anchored = true
    doorLeft.Parent = root

    local doorRight = Instance.new('Part')
    doorRight.Name = 'DoorRight'
    doorRight.Anchored = true
    doorRight.Parent = root

    createPromptPart('ShopTerminal', 0)
    createPromptPart('SalvageTerminal', 2)
    createPromptPart('ObjectiveBoard', 4)
    createPromptPart('LoadoutBench', 6)
    createPromptPart('UgcLabConsole', 8)
    local _, gatePrompt = createPromptPart('GateSwitch', 10)
    createPromptPart('MazeGateMarker', 72)

    local scene = RunScene.new(root)

    assert(
        scene:getSpawnCFrame(RunSpawnPoint.Kind.Spawn) == spawnMarker.CFrame,
        'RunScene should expose the authored spawn marker'
    )
    assert(
        scene:getSpawnCFrame(RunSpawnPoint.Kind.Return) == returnMarker.CFrame,
        'RunScene should expose the authored return marker'
    )
    assert(
        scene:getAreaForPosition(Vector3.new(0, 0, 80)) == 'Wilderness',
        'RunScene should classify positions beyond the outdoor threshold as wilderness'
    )
    assert(
        scene:getAreaForPosition(Vector3.new(0, 0, 20)) == 'Temple Hall',
        'RunScene should classify interior positions as temple hall'
    )

    scene:openGate()
    assert(doorLeft.Transparency == 1, 'RunScene gate opening should hide the left door')
    assert(doorRight.Transparency == 1, 'RunScene gate opening should hide the right door')
    assert(gatePrompt.ActionText == 'Gate Open', 'RunScene should update gate prompt copy')
end
