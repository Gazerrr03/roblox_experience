return function()
    local ReplicatedStorage = game:GetService('ReplicatedStorage')
    local Workspace = game:GetService('Workspace')

    local runModules = ReplicatedStorage:WaitForChild('PlaceModules'):WaitForChild('Run')
    local builder = require(runModules:WaitForChild('RunWorldBuilder'))

    local root = Instance.new('Folder')
    root.Name = 'RunStaticWorld'
    root:SetAttribute('OutdoorThresholdZ', 88)
    root.Parent = Workspace

    local function createPromptPart(name, cframe)
        local part = Instance.new('Part')
        part.Name = name
        part.Anchored = true
        part.CFrame = cframe or CFrame.new()
        part.Parent = root

        local prompt = Instance.new('ProximityPrompt')
        prompt.Parent = part

        return part, prompt
    end

    local spawnMarker = Instance.new('Part')
    spawnMarker.Name = 'SpawnMarker'
    spawnMarker.Anchored = true
    spawnMarker.CFrame = CFrame.new(10, 4, -3)
    spawnMarker.Parent = root

    local returnMarker = Instance.new('Part')
    returnMarker.Name = 'ReturnMarker'
    returnMarker.Anchored = true
    returnMarker.CFrame = CFrame.new(11, 4, -1)
    returnMarker.Parent = root

    local mazeReturnMarker = Instance.new('Part')
    mazeReturnMarker.Name = 'MazeReturnMarker'
    mazeReturnMarker.Anchored = true
    mazeReturnMarker.CFrame = CFrame.new(3, 4, 120)
    mazeReturnMarker.Parent = root

    local doorLeft = Instance.new('Part')
    doorLeft.Name = 'DoorLeft'
    doorLeft.Anchored = true
    doorLeft.Parent = root

    local doorRight = Instance.new('Part')
    doorRight.Name = 'DoorRight'
    doorRight.Anchored = true
    doorRight.Parent = root

    local _, shopPrompt = createPromptPart('ShopTerminal')
    local _, sellPrompt = createPromptPart('SalvageTerminal')
    local _, objectivePrompt = createPromptPart('ObjectiveBoard')
    local _, loadoutPrompt = createPromptPart('LoadoutBench')
    local _, ugcLabPrompt = createPromptPart('UgcLabConsole')
    local _, gatePrompt = createPromptPart('GateSwitch')
    local _, mazePrompt = createPromptPart('MazeGateMarker')

    local world = builder.build()

    assert(world.Root == root, 'Run static world should preserve the authored root')
    assert(
        world.SpawnCFrame == spawnMarker.CFrame,
        'Run static world should expose the authored spawn marker'
    )
    assert(
        world.ReturnCFrame == returnMarker.CFrame,
        'Run static world should expose the authored return marker'
    )
    assert(
        world.MazeReturnCFrame == mazeReturnMarker.CFrame,
        'Run static world should expose the authored maze return marker'
    )
    assert(
        world.OutdoorThresholdZ == 88,
        'Run static world should expose the authored outdoor threshold'
    )
    assert(world.ShopPrompt == shopPrompt, 'Run static world should expose the shop prompt')
    assert(world.SellPrompt == sellPrompt, 'Run static world should expose the salvage prompt')
    assert(
        world.ObjectivePrompt == objectivePrompt,
        'Run static world should expose the objective prompt'
    )
    assert(
        world.LoadoutPrompt == loadoutPrompt,
        'Run static world should expose the loadout prompt'
    )
    assert(world.UgcLabPrompt == ugcLabPrompt, 'Run static world should expose the UGC lab prompt')
    assert(world.GatePrompt == gatePrompt, 'Run static world should expose the gate prompt')
    assert(world.MazePrompt == mazePrompt, 'Run static world should expose the maze prompt')

    world.OpenGate()
    assert(doorLeft.Transparency == 1, 'Opening the static gate should hide the left door')
    assert(doorRight.Transparency == 1, 'Opening the static gate should hide the right door')
    assert(
        gatePrompt.ActionText == 'Gate Open',
        'Opening the static gate should update the prompt copy'
    )

    root:Destroy()

    local invalidRoot = Instance.new('Folder')
    invalidRoot.Name = 'RunStaticWorld'
    invalidRoot:SetAttribute('OutdoorThresholdZ', 12)
    invalidRoot.Parent = Workspace

    local invalidSpawn = Instance.new('Part')
    invalidSpawn.Name = 'SpawnMarker'
    invalidSpawn.Anchored = true
    invalidSpawn.Parent = invalidRoot

    local invalidReturn = Instance.new('Part')
    invalidReturn.Name = 'ReturnMarker'
    invalidReturn.Anchored = true
    invalidReturn.Parent = invalidRoot

    local invalidMazeReturn = Instance.new('Part')
    invalidMazeReturn.Name = 'MazeReturnMarker'
    invalidMazeReturn.Anchored = true
    invalidMazeReturn.Parent = invalidRoot

    local invalidDoorLeft = Instance.new('Part')
    invalidDoorLeft.Name = 'DoorLeft'
    invalidDoorLeft.Anchored = true
    invalidDoorLeft.Parent = invalidRoot

    local invalidDoorRight = Instance.new('Part')
    invalidDoorRight.Name = 'DoorRight'
    invalidDoorRight.Anchored = true
    invalidDoorRight.Parent = invalidRoot

    local ok, err = pcall(function()
        builder.build()
    end)
    assert(
        ok == false,
        'Run static world should fail loudly when required prompt parts are missing'
    )
    assert(
        string.find(tostring(err), 'ShopTerminal', 1, true) ~= nil,
        'Run static world failures should mention the missing prompt part'
    )

    invalidRoot:Destroy()
end
