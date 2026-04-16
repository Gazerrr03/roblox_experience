return function()
    local ReplicatedStorage = game:GetService('ReplicatedStorage')
    local Workspace = game:GetService('Workspace')

    local runModules = ReplicatedStorage:WaitForChild('PlaceModules'):WaitForChild('Run')
    local builder = require(runModules:WaitForChild('RunWorldBuilder'))
    local RunStaticWorldContract = require(runModules:WaitForChild('RunStaticWorldContract'))

    local function createRunStaticWorldRoot(outdoorThresholdZ)
        local root = Instance.new('Folder')
        root.Name = 'RunStaticWorld'
        root:SetAttribute('OutdoorThresholdZ', outdoorThresholdZ or 88)
        root.Parent = Workspace

        local collisionRoot = Instance.new('Folder')
        collisionRoot.Name = 'Collision'
        collisionRoot.Parent = root

        local sceneCollisionRoot = Instance.new('Folder')
        sceneCollisionRoot.Name = 'Scene'
        sceneCollisionRoot.Parent = collisionRoot

        local triggersRoot = Instance.new('Folder')
        triggersRoot.Name = 'Triggers'
        triggersRoot.Parent = root

        local oceanTriggerRoot = Instance.new('Folder')
        oceanTriggerRoot.Name = 'Ocean'
        oceanTriggerRoot.Parent = triggersRoot

        return {
            Root = root,
            SceneCollisionRoot = sceneCollisionRoot,
            OceanTriggerRoot = oceanTriggerRoot,
        }
    end

    local function createPromptPart(root, name, cframe)
        local part = Instance.new('Part')
        part.Name = name
        part.Anchored = true
        part.CFrame = cframe or CFrame.new()
        part.Parent = root

        local prompt = Instance.new('ProximityPrompt')
        prompt.Parent = part

        return part, prompt
    end

    local function createCollisionPart(parent, name, cframe, size)
        local part = Instance.new('Part')
        part.Name = name
        part.Anchored = true
        part.CanCollide = true
        part.CanTouch = false
        part.CanQuery = true
        part.Transparency = 1
        part.Size = size or Vector3.new(12, 1, 12)
        part.CFrame = cframe or CFrame.new()
        part.Parent = parent
        return part
    end

    local function createOceanTrigger(parent, name, cframe, size)
        local part = Instance.new('Part')
        part.Name = name or 'OceanSurface'
        part.Anchored = true
        part.CanCollide = false
        part.CanTouch = true
        part.Transparency = 1
        part.Size = size or Vector3.new(64, 2, 64)
        part.CFrame = cframe or CFrame.new()
        part.Parent = parent
        return part
    end

    local function createMarker(root, name, cframe)
        local marker = Instance.new('Part')
        marker.Name = name
        marker.Anchored = true
        marker.CanCollide = false
        marker.CanTouch = false
        marker.CanQuery = true
        marker.Size = Vector3.new(4, 1, 4)
        marker.CFrame = cframe
        marker.Parent = root
        return marker
    end

    local function createRequiredPromptParts(root, originX, originZ)
        local promptNames = {
            'ShopTerminal',
            'SalvageTerminal',
            'ObjectiveBoard',
            'LoadoutBench',
            'UgcLabConsole',
            'GateSwitch',
            'MazeGateMarker',
        }

        local prompts = {}
        for index, name in ipairs(promptNames) do
            local part, prompt =
                createPromptPart(root, name, CFrame.new(originX + index * 4, 4, originZ))
            prompts[name] = {
                Part = part,
                Prompt = prompt,
            }
        end

        return prompts
    end

    local validWorld = createRunStaticWorldRoot(88)
    createMarker(validWorld.Root, 'SpawnMarker', CFrame.new(10, 4, -3))
    createMarker(validWorld.Root, 'ReturnMarker', CFrame.new(11, 4, -1))
    local mazeReturnMarker =
        createMarker(validWorld.Root, 'MazeReturnMarker', CFrame.new(3, 4, 120))
    local validPrompts = createRequiredPromptParts(validWorld.Root, 10, 20)
    local _, startGamePrompt =
        createPromptPart(validWorld.Root, 'StartGamePrompt', CFrame.new(14, 4, 12))

    local runTerrainMain = Instance.new('Model')
    runTerrainMain.Name = 'RunTerrain_Main'
    runTerrainMain.Parent = validWorld.Root

    local visualScene = Instance.new('Model')
    visualScene.Name = 'Scene'
    visualScene.Parent = runTerrainMain

    local visualScenePart = Instance.new('Part')
    visualScenePart.Name = 'VisualScenePart'
    visualScenePart.Anchored = false
    visualScenePart.CanCollide = true
    visualScenePart.Parent = visualScene

    local visualShip = Instance.new('Model')
    visualShip.Name = 'Sci-Fi Space Ship'
    visualShip.Parent = runTerrainMain

    local visualShipPart = Instance.new('Part')
    visualShipPart.Name = 'VisualShipPart'
    visualShipPart.Anchored = false
    visualShipPart.CanCollide = true
    visualShipPart.Parent = visualShip

    createCollisionPart(
        validWorld.SceneCollisionRoot,
        'SpawnFloor',
        CFrame.new(10, 0, -3),
        Vector3.new(24, 1, 24)
    )
    createOceanTrigger(validWorld.OceanTriggerRoot, 'OceanSurface', CFrame.new(10, -8, -3))

    local world = builder.build()

    assert(world.Root == validWorld.Root, 'Run static world should preserve the authored root')
    assert(
        math.abs(world.SpawnCFrame.Position.Y - (0.5 + RunStaticWorldContract.SpawnLiftStuds))
            < 0.001,
        'Run static world should lift the spawn point above authored collision shells'
    )
    assert(
        math.abs(world.ReturnCFrame.Position.Y - (0.5 + RunStaticWorldContract.SpawnLiftStuds))
            < 0.001,
        'Run static world should also lift grounded return markers above collision shells'
    )
    assert(
        world.MazeReturnCFrame == mazeReturnMarker.CFrame,
        'Run static world should expose the authored maze return marker'
    )
    assert(
        world.OutdoorThresholdZ == 88,
        'Run static world should expose the authored outdoor threshold'
    )
    assert(
        world.ShopPrompt == validPrompts.ShopTerminal.Prompt,
        'Run static world should expose the shop prompt'
    )
    assert(
        world.SellPrompt == validPrompts.SalvageTerminal.Prompt,
        'Run static world should expose the salvage prompt'
    )
    assert(
        world.ObjectivePrompt == validPrompts.ObjectiveBoard.Prompt,
        'Run static world should expose the objective prompt'
    )
    assert(
        world.LoadoutPrompt == validPrompts.LoadoutBench.Prompt,
        'Run static world should expose the loadout prompt'
    )
    assert(
        world.UgcLabPrompt == validPrompts.UgcLabConsole.Prompt,
        'Run static world should expose the UGC lab prompt'
    )
    assert(
        world.GatePrompt == validPrompts.GateSwitch.Prompt,
        'Run static world should expose the gate prompt'
    )
    assert(
        world.MazePrompt == validPrompts.MazeGateMarker.Prompt,
        'Run static world should expose the maze prompt'
    )
    assert(
        world.StartGamePrompt == startGamePrompt,
        'Run static world should expose the optional ship start prompt when authored'
    )
    assert(world.Collision.Ship == nil, 'Run static world should tolerate missing ship collision')
    assert(#world.OceanTriggers == 1, 'Run static world should expose authored ocean trigger parts')
    assert(
        visualScenePart.Anchored == true and visualScenePart.CanCollide == false,
        'Run world builder should stabilize scene visual parts instead of letting them carry physics'
    )
    assert(
        visualShipPart.Anchored == true and visualShipPart.CanCollide == false,
        'Run world builder should stabilize ship visual parts instead of letting them break apart'
    )

    world.OpenGate()
    assert(
        validPrompts.GateSwitch.Prompt.ActionText == 'Gate Open',
        'Opening the static gate should update the prompt copy'
    )

    validWorld.Root:Destroy()

    local missingPromptWorld = createRunStaticWorldRoot(12)
    createMarker(missingPromptWorld.Root, 'SpawnMarker', CFrame.new(0, 4, 0))
    createMarker(missingPromptWorld.Root, 'ReturnMarker', CFrame.new(4, 4, 0))
    createMarker(missingPromptWorld.Root, 'MazeReturnMarker', CFrame.new(8, 4, 0))
    createCollisionPart(
        missingPromptWorld.SceneCollisionRoot,
        'SceneFloor',
        CFrame.new(0, 0, 0),
        Vector3.new(24, 1, 24)
    )
    createOceanTrigger(missingPromptWorld.OceanTriggerRoot, 'OceanSurface', CFrame.new(0, -6, 0))

    local missingPromptOk, missingPromptErr = pcall(function()
        builder.build()
    end)
    assert(
        missingPromptOk == false,
        'Run static world should fail loudly when required prompt parts are missing'
    )
    assert(
        string.find(tostring(missingPromptErr), 'ShopTerminal', 1, true) ~= nil,
        'Run static world failures should mention the missing prompt part'
    )

    missingPromptWorld.Root:Destroy()

    local missingFloorWorld = createRunStaticWorldRoot(24)
    createMarker(missingFloorWorld.Root, 'SpawnMarker', CFrame.new(0, 20, 0))
    createMarker(missingFloorWorld.Root, 'ReturnMarker', CFrame.new(4, 4, 0))
    createMarker(missingFloorWorld.Root, 'MazeReturnMarker', CFrame.new(8, 4, 0))
    createRequiredPromptParts(missingFloorWorld.Root, 60, 60)
    createCollisionPart(
        missingFloorWorld.SceneCollisionRoot,
        'SceneShelf',
        CFrame.new(20, 0, 20),
        Vector3.new(12, 1, 12)
    )
    createOceanTrigger(missingFloorWorld.OceanTriggerRoot)

    local missingFloorOk, missingFloorErr = pcall(function()
        builder.build()
    end)
    assert(
        missingFloorOk == false,
        'Run static world should fail loudly when SpawnMarker has no authored floor below it'
    )
    assert(
        string.find(tostring(missingFloorErr), 'SpawnMarker must raycast onto', 1, true) ~= nil,
        'Missing spawn floor failures should mention the authored collision floor requirement'
    )

    missingFloorWorld.Root:Destroy()

    local strayColliderWorld = createRunStaticWorldRoot(42)
    createMarker(strayColliderWorld.Root, 'SpawnMarker', CFrame.new(0, 8, 0))
    createMarker(strayColliderWorld.Root, 'ReturnMarker', CFrame.new(4, 4, 0))
    createMarker(strayColliderWorld.Root, 'MazeReturnMarker', CFrame.new(8, 4, 0))
    createRequiredPromptParts(strayColliderWorld.Root, 40, 10)
    createCollisionPart(
        strayColliderWorld.SceneCollisionRoot,
        'SceneDecoration',
        CFrame.new(30, 2, 30),
        Vector3.new(12, 1, 12)
    )
    createOceanTrigger(strayColliderWorld.OceanTriggerRoot)

    local fakeFloor = Instance.new('Part')
    fakeFloor.Name = 'FakeFloor'
    fakeFloor.Anchored = true
    fakeFloor.CanCollide = true
    fakeFloor.Size = Vector3.new(20, 1, 20)
    fakeFloor.CFrame = CFrame.new(0, 2, 0)
    fakeFloor.Parent = strayColliderWorld.Root

    local strayColliderOk, strayColliderErr = pcall(function()
        builder.build()
    end)
    assert(
        strayColliderOk == false,
        'Run static world should reject ordinary root-level collidable parts as spawn floors'
    )
    assert(
        string.find(tostring(strayColliderErr), 'SpawnMarker must raycast onto', 1, true) ~= nil,
        'Ordinary root-level blockers should not satisfy the authored collision floor requirement'
    )

    strayColliderWorld.Root:Destroy()

    local edgeGapWorld = createRunStaticWorldRoot(58)
    createMarker(edgeGapWorld.Root, 'SpawnMarker', CFrame.new(0, 8, 0))
    createMarker(edgeGapWorld.Root, 'ReturnMarker', CFrame.new(4, 4, 0))
    createMarker(edgeGapWorld.Root, 'MazeReturnMarker', CFrame.new(8, 4, 0))
    createRequiredPromptParts(edgeGapWorld.Root, 40, 10)
    createCollisionPart(
        edgeGapWorld.SceneCollisionRoot,
        'TinyCenterFloor',
        CFrame.new(0, 2, 0),
        Vector3.new(1, 1, 1)
    )
    createOceanTrigger(edgeGapWorld.OceanTriggerRoot)

    local edgeGapOk, edgeGapErr = pcall(function()
        builder.build()
    end)
    assert(
        edgeGapOk == false,
        'Run static world should reject a spawn floor that only supports the center point'
    )
    assert(
        string.find(tostring(edgeGapErr), 'SpawnMarker must raycast onto', 1, true) ~= nil,
        'Edge-gap failures should mention the authored collision floor requirement'
    )

    edgeGapWorld.Root:Destroy()

    local collidableMarkerWorld = createRunStaticWorldRoot(64)
    local collidableSpawnMarker =
        createMarker(collidableMarkerWorld.Root, 'SpawnMarker', CFrame.new(0, 8, 0))
    createMarker(collidableMarkerWorld.Root, 'ReturnMarker', CFrame.new(4, 4, 0))
    createMarker(collidableMarkerWorld.Root, 'MazeReturnMarker', CFrame.new(8, 4, 0))
    createRequiredPromptParts(collidableMarkerWorld.Root, 40, 10)
    createCollisionPart(
        collidableMarkerWorld.SceneCollisionRoot,
        'SceneFloor',
        CFrame.new(0, 2, 0),
        Vector3.new(24, 1, 24)
    )
    createOceanTrigger(collidableMarkerWorld.OceanTriggerRoot)
    collidableSpawnMarker.CanCollide = true

    local collidableMarkerOk, collidableMarkerErr = pcall(function()
        builder.build()
    end)
    assert(collidableMarkerOk == false, 'Run static world should reject collidable spawn markers')
    assert(
        string.find(
            tostring(collidableMarkerErr),
            'RunStaticWorld marker "SpawnMarker" must have CanCollide=false.',
            1,
            true
        ) ~= nil,
        'Marker validation should mention that spawn markers must not block player movement'
    )

    collidableMarkerWorld.Root:Destroy()
end
