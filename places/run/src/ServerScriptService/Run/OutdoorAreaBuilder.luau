local OutdoorAreaBuilder = {}
local MAZE_GATE_MARKER_CFRAME = CFrame.new(0, 0.5, 120)

function OutdoorAreaBuilder.build(worldFolder, createPart, createPromptPart)
    local outdoorFolder = Instance.new('Folder')
    outdoorFolder.Name = 'Wilderness'
    outdoorFolder.Parent = worldFolder

    -- ==================== 基础地形 ====================
    -- 整体荒野地面
    createPart({
        Name = 'OutdoorGround',
        Size = Vector3.new(300, 2, 300),
        CFrame = CFrame.new(0, -1, 100),
        Color = Color3.fromRGB(83, 126, 78),
        Material = Enum.Material.Grass,
    }, outdoorFolder)

    -- 营地小径
    createPart({
        Name = 'CampPath',
        Size = Vector3.new(20, 0.2, 50),
        CFrame = CFrame.new(0, 0, 35),
        Color = Color3.fromRGB(139, 119, 101),
        Material = Enum.Material.Ground,
    }, outdoorFolder)

    -- 连接各区域的小径
    createPart({
        Name = 'MainTrail',
        Size = Vector3.new(18, 0.2, 200),
        CFrame = CFrame.new(0, 0, 125),
        Color = Color3.fromRGB(132, 116, 96),
        Material = Enum.Material.Ground,
    }, outdoorFolder)

    -- ==================== 区域1：神庙区域（出生点）====================
    local templeZone = Instance.new('Folder')
    templeZone.Name = 'TempleZone'
    templeZone.Parent = outdoorFolder

    -- 做梦祭坛平台
    createPart({
        Name = 'DreamAltarPlatform',
        Size = Vector3.new(12, 1, 12),
        CFrame = CFrame.new(0, 0.5, 10),
        Color = Color3.fromRGB(180, 160, 140),
        Material = Enum.Material.Sand,
    }, templeZone)

    -- 做梦祭坛主体
    createPart({
        Name = 'DreamAltar',
        Size = Vector3.new(6, 4, 6),
        CFrame = CFrame.new(0, 3, 10),
        Color = Color3.fromRGB(200, 180, 160),
        Material = Enum.Material.Sandstone,
    }, templeZone)

    -- 拼凑台
    createPart({
        Name = 'AssemblyTable',
        Size = Vector3.new(8, 3, 5),
        CFrame = CFrame.new(-15, 1.5, 15),
        Color = Color3.fromRGB(120, 100, 80),
        Material = Enum.Material.Wood,
    }, templeZone)

    -- 沙之书展示台
    createPart({
        Name = 'BookDisplayStand',
        Size = Vector3.new(5, 5, 5),
        CFrame = CFrame.new(15, 2.5, 15),
        Color = Color3.fromRGB(150, 130, 110),
        Material = Enum.Material.Slate,
    }, templeZone)

    -- ==================== 区域2：废弃神庙区====================
    local abandonedZone = Instance.new('Folder')
    abandonedZone.Name = 'AbandonedTempleZone'
    abandonedZone.Parent = outdoorFolder

    -- 倒塌的神庙墙壁
    createPart({
        Name = 'FallenWall1',
        Size = Vector3.new(15, 8, 3),
        CFrame = CFrame.new(-50, 4, 40) * CFrame.Angles(0, math.rad(30), math.rad(-15)),
        Color = Color3.fromRGB(100, 105, 110),
        Material = Enum.Material.Slate,
    }, abandonedZone)

    createPart({
        Name = 'FallenWall2',
        Size = Vector3.new(18, 6, 2.5),
        CFrame = CFrame.new(-60, 3, 55) * CFrame.Angles(0, math.rad(-20), math.rad(10)),
        Color = Color3.fromRGB(95, 100, 108),
        Material = Enum.Material.Slate,
    }, abandonedZone)

    -- 倒塌的灯塔
    createPart({
        Name = 'FallenLighthouseBase',
        Size = Vector3.new(8, 12, 8),
        CFrame = CFrame.new(-70, 6, 30) * CFrame.Angles(math.rad(25), 0, 0),
        Color = Color3.fromRGB(110, 115, 120),
        Material = Enum.Material.Slate,
    }, abandonedZone)

    createPart({
        Name = 'FallenLighthouseTop',
        Size = Vector3.new(4, 8, 4),
        CFrame = CFrame.new(-85, 4, 30),
        Color = Color3.fromRGB(105, 110, 115),
        Material = Enum.Material.Slate,
    }, abandonedZone)

    -- 碎石堆
    for i, rubblePos in ipairs({
        Vector3.new(-45, 1, 50),
        Vector3.new(-55, 0.5, 45),
        Vector3.new(-65, 1.5, 35),
        Vector3.new(-75, 0.8, 25),
    }) do
        createPart({
            Name = 'Rubble' .. i,
            Size = Vector3.new(math.random(3, 6), math.random(1, 3), math.random(3, 6)),
            CFrame = CFrame.new(rubblePos),
            Color = Color3.fromRGB(90, 95, 100),
            Material = Enum.Material.Slate,
            Shape = Enum.PartType.Ball,
        }, abandonedZone)
    end

    -- ==================== 区域3：古代遗迹区====================
    local ancientZone = Instance.new('Folder')
    ancientZone.Name = 'AncientRuinsZone'
    ancientZone.Parent = outdoorFolder

    -- 古代石碑群
    for i, steleConfig in ipairs({
        { Vector3.new(60, 4, 30), Vector3.new(3, 8, 1), 0 },
        { Vector3.new(70, 3.5, 35), Vector3.new(2.5, 7, 1), math.rad(15) },
        { Vector3.new(65, 4.5, 45), Vector3.new(3.5, 9, 1.2), math.rad(-10) },
    }) do
        createPart({
            Name = 'AncientStele' .. i,
            Size = steleConfig[2],
            CFrame = CFrame.new(steleConfig[1]) * CFrame.Angles(0, steleConfig[3], 0),
            Color = Color3.fromRGB(130, 135, 140),
            Material = Enum.Material.Slate,
        }, ancientZone)
    end

    -- 古代天平
    createPart({
        Name = 'AncientScaleBase',
        Size = Vector3.new(6, 2, 6),
        CFrame = CFrame.new(75, 1, 55),
        Color = Color3.fromRGB(140, 145, 150),
        Material = Enum.Material.Slate,
    }, ancientZone)

    createPart({
        Name = 'AncientScalePillar',
        Size = Vector3.new(1, 4, 1),
        CFrame = CFrame.new(75, 4, 55),
        Color = Color3.fromRGB(135, 140, 145),
        Material = Enum.Material.Slate,
    }, ancientZone)

    -- 共鸣石
    for i, stonePos in ipairs({
        Vector3.new(50, 2, 60),
        Vector3.new(55, 1.5, 70),
        Vector3.new(65, 2.5, 65),
    }) do
        createPart({
            Name = 'ResonanceStone' .. i,
            Size = Vector3.new(4, 4, 4),
            CFrame = CFrame.new(stonePos),
            Color = Color3.fromRGB(145, 150, 155),
            Material = Enum.Material.Slate,
            Shape = Enum.PartType.Ball,
        }, ancientZone)
    end

    -- ==================== 区域4：荒野森林区====================
    local forestZone = Instance.new('Folder')
    forestZone.Name = 'WildernessForestZone'
    forestZone.Parent = outdoorFolder

    -- 森林树木（密集）
    for i, treePos in ipairs({
        Vector3.new(20, 0, 70),
        Vector3.new(35, 0, 75),
        Vector3.new(25, 0, 85),
        Vector3.new(40, 0, 90),
        Vector3.new(15, 0, 95),
        Vector3.new(30, 0, 100),
        Vector3.new(45, 0, 105),
        Vector3.new(20, 0, 110),
        Vector3.new(35, 0, 115),
        Vector3.new(25, 0, 125),
        Vector3.new(40, 0, 130),
        Vector3.new(15, 0, 140),
    }) do
        createPart({
            Name = 'ForestTreeTrunk' .. i,
            Size = Vector3.new(2, 14, 2),
            CFrame = CFrame.new(treePos + Vector3.new(0, 7, 0)),
            Color = Color3.fromRGB(85, 65, 45),
            Material = Enum.Material.Wood,
        }, forestZone)

        createPart({
            Name = 'ForestTreeCanopy' .. i,
            Size = Vector3.new(8, 8, 8),
            CFrame = CFrame.new(treePos + Vector3.new(0, 15, 0)),
            Color = Color3.fromRGB(60, 100, 58),
            Material = Enum.Material.Grass,
            Shape = Enum.PartType.Ball,
        }, forestZone)
    end

    -- 灌木丛
    for i, bushPos in ipairs({
        Vector3.new(18, 0.5, 80),
        Vector3.new(32, 0.5, 88),
        Vector3.new(42, 0.5, 98),
        Vector3.new(22, 0.5, 108),
        Vector3.new(38, 0.5, 120),
    }) do
        createPart({
            Name = 'Bush' .. i,
            Size = Vector3.new(3, 2, 3),
            CFrame = CFrame.new(bushPos),
            Color = Color3.fromRGB(55, 95, 53),
            Material = Enum.Material.Grass,
            Shape = Enum.PartType.Ball,
        }, forestZone)
    end

    -- 动物足迹标记（用小石头表示）
    for i, trackPos in ipairs({
        Vector3.new(28, 0.1, 82),
        Vector3.new(33, 0.1, 87),
        Vector3.new(27, 0.1, 92),
        Vector3.new(31, 0.1, 97),
    }) do
        createPart({
            Name = 'Footprint' .. i,
            Size = Vector3.new(0.5, 0.2, 0.8),
            CFrame = CFrame.new(trackPos),
            Color = Color3.fromRGB(70, 70, 75),
            Material = Enum.Material.Slate,
        }, forestZone)
    end

    -- ==================== 区域5：洞穴遗迹区====================
    local caveZone = Instance.new('Folder')
    caveZone.Name = 'CaveRuinsZone'
    caveZone.Parent = outdoorFolder

    -- 洞穴入口
    createPart({
        Name = 'CaveEntranceLeft',
        Size = Vector3.new(10, 12, 10),
        CFrame = CFrame.new(-20, 6, 150),
        Color = Color3.fromRGB(75, 80, 85),
        Material = Enum.Material.Slate,
    }, caveZone)

    createPart({
        Name = 'CaveEntranceRight',
        Size = Vector3.new(10, 12, 10),
        CFrame = CFrame.new(20, 6, 150),
        Color = Color3.fromRGB(75, 80, 85),
        Material = Enum.Material.Slate,
    }, caveZone)

    createPart({
        Name = 'CaveEntranceTop',
        Size = Vector3.new(30, 8, 10),
        CFrame = CFrame.new(0, 14, 150),
        Color = Color3.fromRGB(70, 75, 80),
        Material = Enum.Material.Slate,
    }, caveZone)

    -- 洞穴内部（模拟）
    createPart({
        Name = 'CaveInteriorGround',
        Size = Vector3.new(25, 1, 30),
        CFrame = CFrame.new(0, -0.5, 170),
        Color = Color3.fromRGB(60, 65, 70),
        Material = Enum.Material.Slate,
    }, caveZone)

    -- 宝藏箱
    createPart({
        Name = 'TreasureChest',
        Size = Vector3.new(4, 3, 3),
        CFrame = CFrame.new(0, 1.5, 165),
        Color = Color3.fromRGB(139, 90, 43),
        Material = Enum.Material.Wood,
    }, caveZone)

    -- 古代机关
    createPart({
        Name = 'AncientMechanism',
        Size = Vector3.new(6, 3, 6),
        CFrame = CFrame.new(0, 1.5, 180),
        Color = Color3.fromRGB(125, 130, 135),
        Material = Enum.Material.Metal,
    }, caveZone)

    -- 洞穴壁上的发光矿物
    for i, mineralPos in ipairs({
        Vector3.new(-8, 5, 160),
        Vector3.new(8, 4, 165),
        Vector3.new(-6, 6, 175),
        Vector3.new(7, 5, 180),
    }) do
        createPart({
            Name = 'GlowingMineral' .. i,
            Size = Vector3.new(1.5, 1.5, 1.5),
            CFrame = CFrame.new(mineralPos),
            Color = Color3.fromRGB(200, 150, 100),
            Material = Enum.Material.Neon,
            Shape = Enum.PartType.Ball,
        }, caveZone)
    end

    -- ==================== 迷宫入口 ====================
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

    -- ==================== 初始化叙事交互系统 ====================
    local NarrativeInteractionSystem = require(script.Parent.NarrativeInteractionSystem)
    NarrativeInteractionSystem.initialize(outdoorFolder)

    -- ==================== 初始化可交互对象 ====================
    local InteractableObjectsSetup = require(script.Parent.InteractableObjectsSetup)
    InteractableObjectsSetup.setupInteractables(outdoorFolder)

    return {
        MazePrompt = mazePrompt,
    }
end

OutdoorAreaBuilder.MazeGateMarkerCFrame = MAZE_GATE_MARKER_CFRAME

return OutdoorAreaBuilder
