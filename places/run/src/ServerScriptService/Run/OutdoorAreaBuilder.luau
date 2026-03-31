local OutdoorAreaBuilder = {}
local MAZE_GATE_MARKER_CFRAME = CFrame.new(0, 0.5, 120)

function OutdoorAreaBuilder.build(worldFolder, createPart, createPromptPart)
    local outdoorFolder = Instance.new('Folder')
    outdoorFolder.Name = 'Wilderness'
    outdoorFolder.Parent = worldFolder

    createPart({
        Name = 'OutdoorGround',
        Size = Vector3.new(220, 2, 240),
        CFrame = CFrame.new(0, -1, 85),
        Color = Color3.fromRGB(83, 126, 78),
        Material = Enum.Material.Grass,
    }, outdoorFolder)

    createPart({
        Name = 'CampApproach',
        Size = Vector3.new(18, 1, 38),
        CFrame = CFrame.new(0, 0, 32),
        Color = Color3.fromRGB(122, 101, 75),
        Material = Enum.Material.Ground,
    }, outdoorFolder)

    createPart({
        Name = 'Trail',
        Size = Vector3.new(16, 1, 88),
        CFrame = CFrame.new(0, 0, 78),
        Color = Color3.fromRGB(114, 97, 69),
        Material = Enum.Material.Ground,
    }, outdoorFolder)

    for _, treePosition in ipairs({
        Vector3.new(-38, 0, 40),
        Vector3.new(38, 0, 48),
        Vector3.new(-52, 0, 78),
        Vector3.new(50, 0, 94),
        Vector3.new(-34, 0, 126),
        Vector3.new(44, 0, 132),
    }) do
        createPart({
            Name = 'TreeTrunk',
            Size = Vector3.new(2.5, 16, 2.5),
            CFrame = CFrame.new(treePosition + Vector3.new(0, 8, 0)),
            Color = Color3.fromRGB(96, 70, 48),
            Material = Enum.Material.Wood,
        }, outdoorFolder)

        createPart({
            Name = 'TreeCanopy',
            Size = Vector3.new(10, 10, 10),
            CFrame = CFrame.new(treePosition + Vector3.new(0, 18, 0)),
            Color = Color3.fromRGB(67, 112, 65),
            Material = Enum.Material.Grass,
            Shape = Enum.PartType.Ball,
        }, outdoorFolder)
    end

    for _, rockConfig in ipairs({
        { Vector3.new(-22, 2, 58), Vector3.new(6, 4, 5) },
        { Vector3.new(28, 2, 74), Vector3.new(5, 4, 4) },
        { Vector3.new(-16, 3, 116), Vector3.new(8, 5, 6) },
    }) do
        createPart({
            Name = 'Rock',
            Size = rockConfig[2],
            CFrame = CFrame.new(rockConfig[1]),
            Color = Color3.fromRGB(100, 104, 112),
            Material = Enum.Material.Slate,
            Shape = Enum.PartType.Ball,
        }, outdoorFolder)
    end

    createPart({
        Name = 'CliffWall',
        Size = Vector3.new(120, 36, 8),
        CFrame = CFrame.new(0, 16, 156),
        Color = Color3.fromRGB(84, 89, 96),
        Material = Enum.Material.Slate,
    }, outdoorFolder)

    createPart({
        Name = 'MazeGateLeft',
        Size = Vector3.new(4, 18, 4),
        CFrame = CFrame.new(-8, 9, 132),
        Color = Color3.fromRGB(91, 95, 102),
        Material = Enum.Material.Slate,
    }, outdoorFolder)

    createPart({
        Name = 'MazeGateRight',
        Size = Vector3.new(4, 18, 4),
        CFrame = CFrame.new(8, 9, 132),
        Color = Color3.fromRGB(91, 95, 102),
        Material = Enum.Material.Slate,
    }, outdoorFolder)

    createPart({
        Name = 'MazeGateBeam',
        Size = Vector3.new(22, 4, 4),
        CFrame = CFrame.new(0, 18, 132),
        Color = Color3.fromRGB(91, 95, 102),
        Material = Enum.Material.Slate,
    }, outdoorFolder)

    local _, mazePrompt = createPromptPart({
        Name = 'MazeGateMarker',
        Size = Vector3.new(6, 1, 6),
        CFrame = MAZE_GATE_MARKER_CFRAME,
        Color = Color3.fromRGB(154, 113, 214),
        Material = Enum.Material.Neon,
        ActionText = 'Enter',
        ObjectText = 'Shared Maze Gate',
        MaxActivationDistance = 12,
        KeyboardKeyCode = Enum.KeyCode.E,
        RequiresLineOfSight = false,
    }, outdoorFolder)

    -- 叙事交互点1：被遗忘的铭文石碑
    local _, stelePrompt = createPromptPart({
        Name = 'InscriptionStele',
        Size = Vector3.new(3, 8, 1),
        CFrame = CFrame.new(-35, 4, 60),
        Color = Color3.fromRGB(84, 89, 96),
        Material = Enum.Material.Slate,
        ActionText = 'Read',
        ObjectText = 'Weathered Inscription Stele',
        MaxActivationDistance = 10,
        KeyboardKeyCode = Enum.KeyCode.E,
        HoldDuration = 0.5,
        CanCollide = false,
    }, outdoorFolder)

    -- 叙事交互点2：镜子中的不速之客
    local _, mirrorPrompt = createPromptPart({
        Name = 'ShatteredMirror',
        Size = Vector3.new(4, 5, 0.1),
        CFrame = CFrame.new(25, 3, 95) * CFrame.Angles(0, math.rad(45), 0),
        Color = Color3.fromRGB(200, 200, 200),
        Material = Enum.Material.Glass,
        Transparency = 0.3,
        ActionText = 'Look into',
        ObjectText = 'Shattered Mirror',
        MaxActivationDistance = 8,
        KeyboardKeyCode = Enum.KeyCode.E,
        HoldDuration = 0,
        CanCollide = false,
    }, outdoorFolder)

    -- 叙事交互点3：守望者的低语
    local _, statuePrompt = createPromptPart({
        Name = 'WatcherStatue',
        Size = Vector3.new(3, 10, 2),
        CFrame = CFrame.new(50, 5, 115),
        Color = Color3.fromRGB(91, 95, 102),
        Material = Enum.Material.Slate,
        ActionText = 'Listen',
        ObjectText = 'The Watcher Statue',
        MaxActivationDistance = 12,
        KeyboardKeyCode = Enum.KeyCode.E,
        HoldDuration = 1,
        CanCollide = true,
    }, outdoorFolder)

    return {
        MazePrompt = mazePrompt,
        StelePrompt = stelePrompt,
        MirrorPrompt = mirrorPrompt,
        StatuePrompt = statuePrompt,
    }
end

OutdoorAreaBuilder.MazeGateMarkerCFrame = MAZE_GATE_MARKER_CFRAME

return OutdoorAreaBuilder
