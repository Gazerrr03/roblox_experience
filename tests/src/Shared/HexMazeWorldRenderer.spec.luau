return function()
    local Workspace = game:GetService('Workspace')
    local ReplicatedStorage = game:GetService('ReplicatedStorage')
    local packages = ReplicatedStorage:WaitForChild('Packages')
    local gameplay = require(packages:WaitForChild('Gameplay'))
    local sharedPackage = packages:WaitForChild('Shared')
    local shared = require(sharedPackage)
    local renderer = shared.Runtime.HexMazeWorldRenderer
    local lightingProfile = shared.Runtime.MazeLightingProfile

    local layout = gameplay.ProcGen.MazeBuilder.build(12345, {
        RoomCount = 12,
        ExitMin = 2,
        ExitMax = 4,
        RoomSpacing = 40,
        RoomApothem = 20,
        DoorLeafChance = 0.6,
    })

    local moduleAssetsRoot = Instance.new('Folder')
    moduleAssetsRoot.Name = 'MazeModuleAssets'
    moduleAssetsRoot.Parent = Workspace

    local runtime = sharedPackage:WaitForChild('Runtime')
    local contract = require(runtime:WaitForChild('MazeModuleAssetContract'))

    for _, moduleName in ipairs(contract.RequiredModuleNames) do
        local child = Instance.new('Folder')
        child.Name = moduleName
        child.Parent = moduleAssetsRoot
    end

    local rendered = renderer.build({
        WorldName = 'RendererSpecMazeWorld',
        Layout = layout,
        Parent = Workspace,
        ModuleAssetsRoot = moduleAssetsRoot,
        IncludeRoomMarker = true,
        RoomApothem = 20,
        SurfacePalette = lightingProfile.SurfacePalette,
    })

    local root = rendered.Root
    assert(root ~= nil and root.Parent == Workspace, 'Renderer should create world root folder')

    for _, roomId in ipairs(rendered.RoomIds) do
        local roomFolder = root:FindFirstChild(roomId)
        assert(roomFolder ~= nil, string.format('Room folder should exist for %s', roomId))

        local floorTiles = roomFolder:FindFirstChild('FloorTiles')
        local ceilingTiles = roomFolder:FindFirstChild('CeilingTiles')
        assert(floorTiles ~= nil, 'Room should include tiled floor geometry')
        assert(ceilingTiles ~= nil, 'Room should include tiled ceiling geometry')
        assert(#floorTiles:GetChildren() > 1, 'Floor should not be a single square slab')
        assert(#ceilingTiles:GetChildren() > 1, 'Ceiling should not be a single square slab')
        assert(
            roomFolder:FindFirstChild('Floor') == nil,
            'Legacy rectangular floor part should stay removed'
        )
        assert(
            roomFolder:FindFirstChild('Ceiling') == nil,
            'Legacy rectangular ceiling part should stay removed'
        )

        local authoringSockets = roomFolder:FindFirstChild('AuthoringSockets')
        assert(authoringSockets ~= nil, 'Each room should expose authoring sockets')
        assert(
            authoringSockets:FindFirstChild('ShellModelSocket') ~= nil,
            'Each room should expose an external-shell attachment socket'
        )
        assert(
            roomFolder:FindFirstChild('RoomTemplateDecor') ~= nil,
            'Each room should expose blockout decor for its room template'
        )
    end

    local firstRoomFolder = root:FindFirstChild(rendered.RoomIds[1])
    local firstFloorTile = firstRoomFolder
        and firstRoomFolder:FindFirstChild('FloorTiles')
        and firstRoomFolder.FloorTiles:GetChildren()[1]
    assert(firstFloorTile ~= nil, 'Renderer should still produce tiled floor geometry')
    assert(
        firstFloorTile.Material == lightingProfile.SurfacePalette.FloorMaterial,
        'Renderer should honor the maze lighting profile floor material'
    )
    assert(
        firstFloorTile.Color == lightingProfile.SurfacePalette.FloorColor,
        'Renderer should honor the maze lighting profile floor color'
    )

    for doorwayId, connector in pairs(rendered.Connectors) do
        assert(
            connector.Root ~= nil and connector.Root.Parent == root,
            string.format('Renderer should create a connector root for doorway %s', doorwayId)
        )
        assert(
            connector.AuthoringSockets ~= nil,
            string.format('Connector %s should expose authoring sockets', doorwayId)
        )
        assert(
            connector.AuthoringSockets:FindFirstChild('ShellModelSocket') ~= nil,
            string.format('Connector %s should expose a shell attachment socket', doorwayId)
        )
        assert(
            connector.Root:FindFirstChild(string.format('Connector_%s_Floor', doorwayId)) ~= nil,
            string.format(
                'Renderer should build fallback connector floor geometry for %s',
                doorwayId
            )
        )
        assert(
            connector.Root:FindFirstChild(string.format('Connector_%s_Ceiling', doorwayId)) ~= nil,
            string.format(
                'Renderer should build fallback connector ceiling geometry for %s',
                doorwayId
            )
        )
        assert(
            connector.Root:FindFirstChild(string.format('Connector_%s_Accent', doorwayId)) ~= nil,
            string.format(
                'Renderer should build a readable connector accent strip for %s',
                doorwayId
            )
        )
    end
    assert(
        next(rendered.Connectors) ~= nil,
        'Renderer should build connectors between doorway-linked rooms'
    )
    assert(
        next(rendered.ExitPassages) == nil,
        'Renderer should not build exterior passages in the sealed indoor baseline'
    )

    local leafDoorwayId = nil
    for doorwayId, doorway in pairs(rendered.Doorways) do
        if doorway.HasDoorLeaves then
            leafDoorwayId = doorwayId
            break
        end
    end

    assert(leafDoorwayId ~= nil, 'Rendered world should include at least one door-leaf doorway')

    local doorway = rendered.Doorways[leafDoorwayId]
    local fromCenter = rendered.RoomCenters[doorway.RoomA]
    local toCenter = rendered.RoomCenters[doorway.RoomB]
    assert(
        rendered.CanTraverseBetweenPositions(fromCenter, toCenter) == false,
        'Closed door leaves should block traversal between neighboring rooms'
    )

    assert(rendered.ToggleDoor(leafDoorwayId), 'ToggleDoor should work for door-leaf doorway')
    assert(
        rendered.CanTraverseBetweenPositions(fromCenter, toCenter) == true,
        'Open door leaves should allow traversal between neighboring rooms'
    )

    root:Destroy()

    local roomArchetypes = Instance.new('Folder')
    roomArchetypes.Name = contract.OptionalAuthoringFolderName
    roomArchetypes.Parent = moduleAssetsRoot

    local entrySafeAssets = Instance.new('Folder')
    entrySafeAssets.Name = 'EntrySafe'
    entrySafeAssets.Parent = roomArchetypes

    local authoredRoomShell = Instance.new('Model')
    authoredRoomShell.Name = contract.OptionalShellModelName
    local authoredRoomShellPart = Instance.new('Part')
    authoredRoomShellPart.Name = 'ShellPart'
    authoredRoomShellPart.Size = Vector3.new(2, 2, 2)
    authoredRoomShellPart.Anchored = true
    authoredRoomShellPart.Parent = authoredRoomShell
    authoredRoomShell.Parent = entrySafeAssets

    local connectorArchetypes = Instance.new('Folder')
    connectorArchetypes.Name = contract.OptionalConnectorAuthoringFolderName
    connectorArchetypes.Parent = moduleAssetsRoot

    local industrialHallAssets = Instance.new('Folder')
    industrialHallAssets.Name = 'IndustrialHall'
    industrialHallAssets.Parent = connectorArchetypes

    local connectorShell = Instance.new('Model')
    connectorShell.Name = contract.OptionalShellModelName
    local connectorShellPart = Instance.new('Part')
    connectorShellPart.Name = 'ConnectorShellPart'
    connectorShellPart.Size = Vector3.new(2, 2, 6)
    connectorShellPart.Anchored = true
    connectorShellPart.Parent = connectorShell
    connectorShell.Parent = industrialHallAssets

    local authoredRendered = renderer.build({
        WorldName = 'RendererSpecMazeWorldAuthoredAssets',
        Layout = layout,
        Parent = Workspace,
        ModuleAssetsRoot = moduleAssetsRoot,
        IncludeRoomMarker = true,
        RoomApothem = 20,
        SurfacePalette = lightingProfile.SurfacePalette,
    })

    root = authoredRendered.Root
    local campRoomFolder = root:FindFirstChild(layout.CampRoomId)
    assert(campRoomFolder ~= nil, 'Camp room folder should exist in the authored render')
    assert(
        campRoomFolder:FindFirstChild('AuthoredShell_EntrySafe') ~= nil,
        'Camp room should accept authored room shell assets by authoring asset id'
    )

    local foundAuthoredConnectorShell = false
    for doorwayId, connector in pairs(authoredRendered.Connectors) do
        if connector.Shell ~= nil then
            foundAuthoredConnectorShell = true
            assert(
                connector.Root:FindFirstChild('AuthoredPassageShell_IndustrialHall') ~= nil,
                string.format('Connector %s should attach the authored connector shell', doorwayId)
            )
        end
    end
    assert(
        foundAuthoredConnectorShell,
        'At least one connector should consume the authored connector shell'
    )

    authoredRendered.Root:Destroy()
    moduleAssetsRoot:Destroy()
end
