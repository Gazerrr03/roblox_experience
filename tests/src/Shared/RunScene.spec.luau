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

    local mazeReturnPart = Instance.new('Part')
    mazeReturnPart.Name = 'MazeReturnMarker'
    mazeReturnPart.Anchored = true
    mazeReturnPart.CanCollide = false
    mazeReturnPart.CanTouch = false
    mazeReturnPart.CanQuery = true
    mazeReturnPart.CFrame = CFrame.new(0, 4, 64)
    mazeReturnPart.Parent = root

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

    local mazeReturnFloor = Instance.new('Part')
    mazeReturnFloor.Name = 'MazeReturnFloor'
    mazeReturnFloor.Anchored = true
    mazeReturnFloor.CanCollide = true
    mazeReturnFloor.CanTouch = false
    mazeReturnFloor.CanQuery = true
    mazeReturnFloor.Transparency = 1
    mazeReturnFloor.CFrame = CFrame.new(mazeReturnPart.Position.X, 0, mazeReturnPart.Position.Z)
    mazeReturnFloor.Size = Vector3.new(24, 1, 24)
    mazeReturnFloor.Parent = sceneCollisionRoot

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

    local doorLeft = Instance.new('Part')
    doorLeft.Name = 'DoorLeft'
    doorLeft.Anchored = true
    doorLeft.Parent = root

    local doorRight = Instance.new('Part')
    doorRight.Name = 'DoorRight'
    doorRight.Anchored = true
    doorRight.Parent = root

    local clueScene = Instance.new('Folder')
    clueScene.Name = 'FirstCorpseClueScene'
    clueScene.Parent = root

    local corpseRecorderMarker = Instance.new('Part')
    corpseRecorderMarker.Name = 'ClueMarker_FirstCorpse'
    corpseRecorderMarker.Anchored = true
    corpseRecorderMarker:SetAttribute('ClueId', 'first-corpse-sound-warning')
    corpseRecorderMarker:SetAttribute('SourceMarkerId', 'ClueMarker_FirstCorpse')
    corpseRecorderMarker:SetAttribute('ReadableTitle', 'Recorder Beside the Old Body')
    corpseRecorderMarker:SetAttribute(
        'ReadableText',
        'The last voice is breathing too fast. Metal scrapes, boots hammer the floor, and something answers every noise before the recording cuts out.'
    )
    corpseRecorderMarker:SetAttribute('ThreatHintId', 'sound-predator')
    corpseRecorderMarker:SetAttribute('ItemName', 'Corpse Recorder')
    corpseRecorderMarker.Parent = clueScene

    local corpseRecorderPrompt = Instance.new('ProximityPrompt')
    corpseRecorderPrompt.ActionText = 'Recover clue'
    corpseRecorderPrompt.ObjectText = 'Old recorder'
    corpseRecorderPrompt.Parent = corpseRecorderMarker

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
        math.abs(scene:getSpawnCFrame(RunSpawnPoint.Kind.MazeReturn).Position.Y - 4.5) < 0.001,
        'RunScene should also ground maze return markers when collision exists beneath them'
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
    assert(
        scene.Collision.Ship == nil,
        'RunScene should tolerate the ship collision root being absent'
    )
    assert(#scene.OceanTriggers == 1, 'RunScene should expose authored ocean triggers')
    assert(
        scene.StartGamePrompt == startGamePrompt,
        'RunScene should expose the optional ship start prompt when authored'
    )
    assert(#scene.ClueMarkers == 1, 'RunScene should discover nested authored clue markers')
    local firstCorpseClue = scene.ClueMarkers[1]
    assert(
        firstCorpseClue.ClueId == 'first-corpse-sound-warning',
        'First corpse clue should preserve its authored clue id'
    )
    assert(
        firstCorpseClue.SourceMarkerId == 'ClueMarker_FirstCorpse',
        'First corpse clue should preserve its authored source marker id'
    )
    assert(
        firstCorpseClue.ReadableTitle == 'Recorder Beside the Old Body',
        'First corpse clue should preserve its readable title'
    )
    assert(
        string.find(firstCorpseClue.ReadableText, 'something answers every noise', 1, true) ~= nil,
        'First corpse clue should preserve the sound-predator warning text'
    )
    assert(
        firstCorpseClue.ThreatHintId == 'sound-predator',
        'First corpse clue should preserve the sound predator threat hint'
    )
    assert(
        firstCorpseClue.ItemName == 'Corpse Recorder',
        'First corpse clue should preserve its inventory item name'
    )
    assert(
        firstCorpseClue.Prompt == corpseRecorderPrompt,
        'First corpse clue should preserve its recovery prompt'
    )

    scene:openGate()
    assert(gatePrompt.ActionText == 'Gate Open', 'RunScene should update gate prompt copy')

    root:Destroy()
end
