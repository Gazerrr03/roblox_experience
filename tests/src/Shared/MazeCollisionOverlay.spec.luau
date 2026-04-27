return function()
    local ReplicatedStorage = game:GetService('ReplicatedStorage')
    local Workspace = game:GetService('Workspace')

    local mazeModules = ReplicatedStorage:WaitForChild('PlaceModules'):WaitForChild('Maze')
    local overlay = require(mazeModules:WaitForChild('MazeCollisionOverlay'))

    local root = Instance.new('Folder')
    root.Name = 'MazeStaticWorld'
    root.Parent = Workspace

    local spawnMarker = Instance.new('Part')
    spawnMarker.Name = 'SpawnMarker'
    spawnMarker.Anchored = true
    spawnMarker.Size = Vector3.new(16, 1.2, 16)
    spawnMarker.CFrame = CFrame.new(98, 77.94891357421875, -397)
    spawnMarker.CanCollide = true
    spawnMarker.Parent = root

    local collisionRoot = Instance.new('Folder')
    collisionRoot.Name = 'Collision'
    collisionRoot.Parent = root

    local mapModel = Instance.new('Model')
    mapModel.Name = 'maze-roblox'
    mapModel.Parent = collisionRoot

    local floor = Instance.new('Part')
    floor.Name = '物件_1326'
    floor.Anchored = false
    floor.Size = Vector3.new(24, 1, 24)
    floor.CFrame = CFrame.new(98, 77.4, -397)
    floor.CanCollide = false
    floor.CanQuery = false
    floor.CanTouch = true
    floor.Parent = mapModel

    local wall = Instance.new('Part')
    wall.Name = 'Wall_001'
    wall.Anchored = false
    wall.Size = Vector3.new(2, 18, 24)
    wall.CFrame = CFrame.new(110, 86, -397)
    wall.CanCollide = false
    wall.CanQuery = false
    wall.CanTouch = true
    wall.Parent = mapModel

    local door = Instance.new('Part')
    door.Name = 'door_001'
    door.Anchored = false
    door.Size = Vector3.new(8, 12, 1)
    door.CFrame = CFrame.new(98, 84, -385)
    door.CanCollide = true
    door.CanQuery = false
    door.CanTouch = true
    door.Parent = mapModel

    local doorwayFrame = Instance.new('Part')
    doorwayFrame.Name = 'DoorwayFrame_003'
    doorwayFrame.Anchored = false
    doorwayFrame.Size = Vector3.new(16, 16, 2)
    doorwayFrame.CFrame = CFrame.new(98, 86, -380)
    doorwayFrame.CanCollide = true
    doorwayFrame.CanQuery = false
    doorwayFrame.CanTouch = true
    doorwayFrame.Parent = mapModel

    local originalSpawnCFrame = spawnMarker.CFrame
    local summary = overlay.apply(root)

    assert(summary.Applied == true, 'Collision overlay should apply when maze map geometry exists')
    assert(summary.CreatedCollisionBoxes == 2, 'Overlay should create floor and wall boxes only')
    assert(summary.FloorCollisionBoxes == 1, 'Overlay should create a floor collision box')
    assert(summary.WallCollisionBoxes == 1, 'Overlay should create a wall collision box')
    assert(
        spawnMarker.CFrame == originalSpawnCFrame,
        'Overlay must not move the authored SpawnMarker'
    )
    assert(spawnMarker.Material == Enum.Material.Neon, 'SpawnMarker should be restored to Neon')
    assert(spawnMarker.Color == Color3.fromRGB(0, 255, 255), 'SpawnMarker should be cyan')
    assert(
        spawnMarker.CanCollide == false,
        'SpawnMarker remains semantic and should not carry collision'
    )
    assert(
        spawnMarker:FindFirstChild('SpawnMarkerCyanGuideLight') ~= nil,
        'SpawnMarker should receive the cyan guide light'
    )

    local collisionBoxes = mapModel:FindFirstChild('CollisionBoxes')
    assert(collisionBoxes ~= nil, 'Overlay should create a CollisionBoxes folder')
    assert(
        collisionBoxes:GetAttribute('IsScenery') == true,
        'CollisionBoxes should be scenery so world scan does not promote it to gameplay'
    )

    local doorBoxCount = 0
    for _, child in ipairs(collisionBoxes:GetChildren()) do
        local sourceName = tostring(child:GetAttribute('SourceMeshName') or child.Name)
        if string.find(string.lower(sourceName), 'door', 1, true) ~= nil then
            doorBoxCount += 1
        end
    end
    assert(doorBoxCount == 0, 'Overlay should not create solid boxes over door openings')
    assert(door.CanCollide == false, 'Imported door leaf collision should not block openings')
    assert(
        doorwayFrame.CanCollide == false,
        'Imported doorway frame collision should not fill openings'
    )
    assert(
        floor.Anchored == true and floor.CanCollide == true,
        'Map floors should be anchored and collidable'
    )
    assert(
        wall.Anchored == true and wall.CanCollide == true,
        'Map walls should be anchored and collidable'
    )

    local secondSummary = overlay.apply(root)
    assert(
        secondSummary.CreatedCollisionBoxes == 2,
        'Reapplying the overlay should replace generated boxes without duplicating them'
    )
    assert(#collisionBoxes:GetChildren() == 2, 'CollisionBoxes should stay stable across reapply')

    root:Destroy()
end
