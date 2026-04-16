return function()
    local ReplicatedStorage = game:GetService('ReplicatedStorage')
    local Workspace = game:GetService('Workspace')

    local runModules = ReplicatedStorage:WaitForChild('PlaceModules'):WaitForChild('Run')
    local RunScene = require(runModules:WaitForChild('RunScene'))
    local RunSpawnPoint = require(runModules:WaitForChild('RunSpawnPoint'))

    local root = Instance.new('Folder')
    root.Name = 'RunStaticWorld'
    root:SetAttribute('OutdoorThresholdZ', 50)
    root.Parent = Workspace

    local collisionRoot = Instance.new('Folder')
    collisionRoot.Name = 'Collision'
    collisionRoot.Parent = root

    local sceneCollisionRoot = Instance.new('Folder')
    sceneCollisionRoot.Name = 'Scene'
    sceneCollisionRoot.Parent = collisionRoot

    local shipCollisionRoot = Instance.new('Folder')
    shipCollisionRoot.Name = 'Ship'
    shipCollisionRoot.Parent = collisionRoot

    local triggersRoot = Instance.new('Folder')
    triggersRoot.Name = 'Triggers'
    triggersRoot.Parent = root

    local oceanTriggerRoot = Instance.new('Folder')
    oceanTriggerRoot.Name = 'Ocean'
    oceanTriggerRoot.Parent = triggersRoot

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
    spawnMarker.CanCollide = false
    spawnMarker.CanTouch = false
    spawnMarker.CanQuery = true
    spawnMarker.CFrame = CFrame.new(0, 4, 0)
    spawnMarker.Parent = root

    local returnMarker = Instance.new('Part')
    returnMarker.Name = 'ReturnMarker'
    returnMarker.Anchored = true
    returnMarker.CanCollide = false
    returnMarker.CanTouch = false
    returnMarker.CanQuery = true
    returnMarker.CFrame = CFrame.new(0, 4, 8)
    returnMarker.Parent = root

    local mazeReturnMarker = Instance.new('Part')
    mazeReturnMarker.Name = 'MazeReturnMarker'
    mazeReturnMarker.Anchored = true
    mazeReturnMarker.CanCollide = false
    mazeReturnMarker.CanTouch = false
    mazeReturnMarker.CanQuery = true
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

    local sceneFloor = Instance.new('Part')
    sceneFloor.Name = 'SceneFloor'
    sceneFloor.Anchored = true
    sceneFloor.CanCollide = true
    sceneFloor.CanTouch = false
    sceneFloor.CanQuery = true
    sceneFloor.Transparency = 1
    sceneFloor.Parent = sceneCollisionRoot

    local shipDeck = Instance.new('Part')
    shipDeck.Name = 'ShipDeck'
    shipDeck.Anchored = true
    shipDeck.CanCollide = true
    shipDeck.CanTouch = false
    shipDeck.CanQuery = true
    shipDeck.Transparency = 1
    shipDeck.CFrame = CFrame.new(0, 0, 0)
    shipDeck.Size = Vector3.new(24, 1, 24)
    shipDeck.Parent = shipCollisionRoot

    local oceanTrigger = Instance.new('Part')
    oceanTrigger.Name = 'OceanSurface'
    oceanTrigger.Anchored = true
    oceanTrigger.CanCollide = false
    oceanTrigger.CanTouch = true
    oceanTrigger.Transparency = 1
    oceanTrigger.Parent = oceanTriggerRoot

    createPromptPart('ShopTerminal', 0)
    createPromptPart('SalvageTerminal', 2)
    createPromptPart('ObjectiveBoard', 4)
    createPromptPart('LoadoutBench', 6)
    createPromptPart('UgcLabConsole', 8)
    local _, startGamePrompt = createPromptPart('StartGamePrompt', 9)
    local _, gatePrompt = createPromptPart('GateSwitch', 10)
    createPromptPart('MazeGateMarker', 72)

    local scene = RunScene.new(root)

    assert(
        math.abs(scene:getSpawnCFrame(RunSpawnPoint.Kind.Spawn).Position.Y - 4.5) < 0.001,
        'RunScene should lift grounded spawn points above authored collision shells'
    )
    assert(
        math.abs(scene:getSpawnCFrame(RunSpawnPoint.Kind.Return).Position.Y - 4.5) < 0.001,
        'RunScene should also ground return markers when collision exists beneath them'
    )
    assert(
        scene:getSpawnCFrame(RunSpawnPoint.Kind.MazeReturn) == mazeReturnMarker.CFrame,
        'RunScene should fall back to the authored marker when no collision shell exists beneath it'
    )
    assert(
        scene:getAreaForPosition(Vector3.new(0, 0, 80)) == 'Wilderness',
        'RunScene should classify positions beyond the outdoor threshold as wilderness'
    )
    assert(
        scene:getAreaForPosition(Vector3.new(0, 0, 20)) == 'Temple Hall',
        'RunScene should classify interior positions as temple hall'
    )
    assert(
        scene.Collision.Scene == sceneCollisionRoot,
        'RunScene should expose scene collision root'
    )
    assert(scene.Collision.Ship == shipCollisionRoot, 'RunScene should expose ship collision root')
    assert(#scene.OceanTriggers == 1, 'RunScene should expose authored ocean triggers')
    assert(
        scene.StartGamePrompt == startGamePrompt,
        'RunScene should expose the optional ship start prompt when authored'
    )

    scene:openGate()
    assert(doorLeft.Transparency == 1, 'RunScene gate opening should hide the left door')
    assert(doorRight.Transparency == 1, 'RunScene gate opening should hide the right door')
    assert(gatePrompt.ActionText == 'Gate Open', 'RunScene should update gate prompt copy')

    root:Destroy()
end
