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

    local roomArchetypes = Instance.new('Folder')
    roomArchetypes.Name = contract.OptionalAuthoringFolderName
    roomArchetypes.Parent = moduleAssetsRoot

    local cavePocketAssets = Instance.new('Folder')
    cavePocketAssets.Name = 'CavePocket'
    cavePocketAssets.Parent = roomArchetypes

    local authoredShell = Instance.new('Model')
    authoredShell.Name = contract.OptionalShellModelName
    local authoredShellPart = Instance.new('Part')
    authoredShellPart.Name = 'ShellPart'
    authoredShellPart.Size = Vector3.new(2, 2, 2)
    authoredShellPart.Anchored = true
    authoredShellPart.Parent = authoredShell
    authoredShell.Parent = cavePocketAssets

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

    local checkedRooms = 0
    local caveRoomFound = false
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
            'Legacy rectangular floor part should be removed'
        )
        assert(
            roomFolder:FindFirstChild('Ceiling') == nil,
            'Legacy rectangular ceiling part should be removed'
        )

        local wallPartCount = 0
        for _, child in ipairs(roomFolder:GetChildren()) do
            if string.sub(child.Name, 1, 5) == 'Wall_' then
                wallPartCount += 1
            end
        end
        assert(
            wallPartCount >= 6,
            'Each room should render six wall edges with doorway segmentation'
        )
        local authoringSockets = roomFolder:FindFirstChild('AuthoringSockets')
        assert(authoringSockets ~= nil, 'Each room should expose authoring sockets')
        assert(
            authoringSockets:FindFirstChild('ShellModelSocket') ~= nil,
            'Each room should expose an external-shell attachment socket'
        )

        if layout.Rooms[roomId].ArchetypeId == 'CavePocket' then
            caveRoomFound = true
            assert(
                roomFolder:FindFirstChild('CavePocketDecor') ~= nil,
                'Cave archetype rooms should render cave-like interior dressing'
            )
            assert(
                roomFolder:FindFirstChild('AuthoredShell_CavePocket') ~= nil,
                'Cave archetype rooms should accept authored external shell models'
            )
        end

        checkedRooms += 1
        if checkedRooms >= 2 then
            if caveRoomFound then
                break
            end
        end
    end
    assert(caveRoomFound, 'Renderer spec should include at least one cave archetype room')

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
    moduleAssetsRoot:Destroy()
end
