--[[
    MazeWorldScanner Spec Tests

    测试 MazeWorldScanner 的扫描、过滤和数据构建逻辑。
    由于 Scan() 需要 Workspace 运行时，这里主要测试其内部辅助函数和构建逻辑。
]]

return function()
    local ReplicatedStorage = game:GetService('ReplicatedStorage')
    local Packages = ReplicatedStorage:WaitForChild('Packages')
    local Shared = require(Packages:WaitForChild('Shared'))
    local MazeWorldScanner = Shared.Runtime.MazeWorldScanner

    -- ============================================
    -- Helper: 创建模拟房间 Instance
    -- ============================================
    local function createMockRoom(name, _roomType, attributes, tags, children)
        local room = Instance.new('Model')
        room.Name = name

        -- 设置 Attributes
        for attrName, attrValue in pairs(attributes or {}) do
            room:SetAttribute(attrName, attrValue)
        end

        -- 设置 Tags
        for _, tag in ipairs(tags or {}) do
            room:AddTag(tag)
        end

        -- 添加子级（SpawnPoint、LootSocket 等）
        for _, childData in ipairs(children or {}) do
            local child = Instance.new('Part')
            child.Name = childData.name
            child.Position = childData.position or Vector3.new(0, 0, 0)
            child:SetAttribute('Direction', childData.direction or 'Unknown')
            child.Parent = room
        end

        return room
    end

    -- ============================================
    -- Test: extractRoomType 从 Tag 中提取房间类型
    -- ============================================
    do
        local room = createMockRoom('TestRoom', 'DeadEnd', {}, { 'RoomType/DeadEnd' }, {})
        local roomType = MazeWorldScanner.GetRoomTypeFromInstance(room)
        assert(roomType == 'DeadEnd', string.format('Expected DeadEnd, got %s', tostring(roomType)))
        room:Destroy()
        print('[PASS] MazeWorldScanner.GetRoomTypeFromInstance extracts correct room type')
    end

    -- ============================================
    -- Test: 未知房间类型
    -- ============================================
    do
        local room = createMockRoom('TestRoom', 'Unknown', {}, {}, {})
        local roomType = MazeWorldScanner.GetRoomTypeFromInstance(room)
        assert(roomType == 'Unknown', string.format('Expected Unknown, got %s', tostring(roomType)))
        room:Destroy()
        print('[PASS] MazeWorldScanner.GetRoomTypeFromInstance returns Unknown for untagged room')
    end

    -- ============================================
    -- Test: isSceneryInstance 识别造景
    -- ============================================
    do
        -- 测试 IsScenery 属性
        local sceneryRoom = createMockRoom('SceneryRoom', 'Unknown', { IsScenery = true }, {}, {})
        assert(
            MazeWorldScanner.IsSceneryInstance(sceneryRoom) == true,
            'Room with IsScenery=true should be detected as scenery'
        )
        sceneryRoom:Destroy()

        -- 测试正常房间
        local normalRoom = createMockRoom(
            'NormalRoom',
            'DeadEnd',
            { IsScenery = false },
            { 'RoomType/DeadEnd' },
            {}
        )
        assert(
            MazeWorldScanner.IsSceneryInstance(normalRoom) == false,
            'Room with IsScenery=false should not be scenery'
        )
        normalRoom:Destroy()

        print('[PASS] MazeWorldScanner.IsSceneryInstance correctly identifies scenery')
    end

    -- ============================================
    -- Test: Scan 收集带 RoomType Tag 的房间
    -- ============================================
    do
        -- 创建 mock Workspace 结构
        local mockRoot = Instance.new('Folder')
        mockRoot.Name = 'MockWorkspace'

        -- 添加普通房间
        local room1 = createMockRoom(
            'Room_DeadEnd_01',
            'DeadEnd',
            { DifficultyTier = 2, MonsterBudget = 3, IsCamp = false },
            { 'RoomType/DeadEnd', 'HasMonsterSpawner' },
            {
                { name = 'SpawnPoint_1', position = Vector3.new(10, 0, 0) },
                { name = 'SpawnPoint_2', position = Vector3.new(15, 0, 0) },
            }
        )
        room1.Parent = mockRoot

        -- 添加 Camp 房间
        local campRoom = createMockRoom(
            'Room_Camp_01',
            'OpenHub',
            { DifficultyTier = 0, MonsterBudget = 0, IsCamp = true },
            { 'RoomType/OpenHub' },
            {}
        )
        campRoom.Parent = mockRoot

        -- 添加 Extraction 房间
        local extractRoom = createMockRoom(
            'Room_Extraction_01',
            'Straight',
            { DifficultyTier = 1, MonsterBudget = 0, IsExtraction = true },
            { 'RoomType/Straight' },
            {}
        )
        extractRoom.Parent = mockRoot

        -- 添加无 Tag 的非房间物体（应该被跳过）
        local nonRoom = Instance.new('Part')
        nonRoom.Name = 'SomeDecoration'
        nonRoom.Parent = mockRoot

        -- 执行扫描
        local scanResult = MazeWorldScanner.Scan(mockRoot)

        -- 验证
        local roomIds = MazeWorldScanner.GetRoomIds(scanResult)
        assert(#roomIds == 3, string.format('Expected 3 rooms, got %d', #roomIds))

        -- 验证 CampRoomId 识别
        assert(
            scanResult.campRoomId == 'Room_Camp_01',
            string.format(
                'Expected campRoomId Room_Camp_01, got %s',
                tostring(scanResult.campRoomId)
            )
        )

        -- 验证房间数据
        local deadEndRoom = MazeWorldScanner.GetRoomById(scanResult, 'Room_DeadEnd_01')
        assert(deadEndRoom ~= nil, 'DeadEnd room should exist')
        assert(
            deadEndRoom.DifficultyTier == 2,
            string.format('Expected DifficultyTier 2, got %s', tostring(deadEndRoom.DifficultyTier))
        )
        assert(
            deadEndRoom.MonsterBudget == 3,
            string.format('Expected MonsterBudget 3, got %s', tostring(deadEndRoom.MonsterBudget))
        )
        assert(
            deadEndRoom.Type == 'DeadEnd',
            string.format('Expected Type DeadEnd, got %s', tostring(deadEndRoom.Type))
        )

        -- 验证 IsExtraction 识别
        local extract = MazeWorldScanner.GetRoomById(scanResult, 'Room_Extraction_01')
        assert(extract.IsExtraction == true, 'Extraction room should have IsExtraction=true')

        -- 验证非房间物体被跳过
        local decoration = mockRoot:FindFirstChild('SomeDecoration')
        assert(decoration ~= nil, 'Non-room object should still exist in workspace')

        -- 清理
        mockRoot:Destroy()

        print('[PASS] MazeWorldScanner.Scan correctly collects rooms and metadata')
    end

    -- ============================================
    -- Test: Scan 跳过 Scenery 文件夹
    -- ============================================
    do
        local mockRoot = Instance.new('Folder')
        mockRoot.Name = 'MockWorkspace'

        -- 添加正常房间
        local room = createMockRoom('Room_Normal', 'DeadEnd', {}, { 'RoomType/DeadEnd' }, {})
        room.Parent = mockRoot

        -- 添加 Scenery 文件夹（内容应被跳过）
        local sceneryFolder = Instance.new('Folder')
        sceneryFolder.Name = 'Scenery'
        local hiddenRoom = createMockRoom('HiddenRoom', 'Straight', {}, { 'RoomType/Straight' }, {})
        hiddenRoom.Parent = sceneryFolder
        sceneryFolder.Parent = mockRoot

        -- 执行扫描
        local scanResult = MazeWorldScanner.Scan(mockRoot)
        local roomIds = MazeWorldScanner.GetRoomIds(scanResult)

        assert(#roomIds == 1, string.format('Expected 1 room (scenery skipped), got %d', #roomIds))
        assert(roomIds[1] == 'Room_Normal', 'Only normal room should be collected')

        mockRoot:Destroy()

        print('[PASS] MazeWorldScanner.Scan correctly skips Scenery folder')
    end

    -- ============================================
    -- Test: Scan 跳过 IsScenery=true 的实例
    -- ============================================
    do
        local mockRoot = Instance.new('Folder')
        mockRoot.Name = 'MockWorkspace'

        -- 添加正常房间
        local normalRoom = createMockRoom('Room_Normal', 'DeadEnd', {}, { 'RoomType/DeadEnd' }, {})
        normalRoom.Parent = mockRoot

        -- 添加 IsScenery 房间
        local sceneryRoom = createMockRoom(
            'Room_Scenery',
            'Straight',
            { IsScenery = true },
            { 'RoomType/Straight' },
            {}
        )
        sceneryRoom.Parent = mockRoot

        -- 执行扫描
        local scanResult = MazeWorldScanner.Scan(mockRoot)
        local roomIds = MazeWorldScanner.GetRoomIds(scanResult)

        assert(#roomIds == 1, string.format('Expected 1 room (scenery skipped), got %d', #roomIds))
        assert(roomIds[1] == 'Room_Normal', 'Only normal room should be collected')

        mockRoot:Destroy()

        print('[PASS] MazeWorldScanner.Scan correctly skips IsScenery=true instances')
    end

    -- ============================================
    -- Test: GetEligibleMonsterRooms 返回有怪物的房间
    -- ============================================
    do
        local mockRoot = Instance.new('Folder')
        mockRoot.Name = 'MockWorkspace'

        local roomWithMonster = createMockRoom(
            'Room_WithMonster',
            'DeadEnd',
            { MonsterBudget = 2 },
            { 'RoomType/DeadEnd', 'HasMonsterSpawner' },
            { { name = 'SpawnPoint_1', position = Vector3.new(0, 0, 0) } }
        )
        roomWithMonster.Parent = mockRoot

        local roomWithoutMonster = createMockRoom(
            'Room_NoMonster',
            'Straight',
            { MonsterBudget = 0 },
            { 'RoomType/Straight' },
            {}
        )
        roomWithoutMonster.Parent = mockRoot

        local scanResult = MazeWorldScanner.Scan(mockRoot)
        local eligibleRooms = MazeWorldScanner.GetEligibleMonsterRooms(scanResult)

        assert(
            #eligibleRooms == 1,
            string.format('Expected 1 eligible room, got %d', #eligibleRooms)
        )
        assert(
            eligibleRooms[1] == 'Room_WithMonster',
            'Only room with HasMonsterSpawner tag should be eligible'
        )

        mockRoot:Destroy()

        print('[PASS] MazeWorldScanner.GetEligibleMonsterRooms correctly filters rooms')
    end

    -- ============================================
    -- Test: GetRoomsByDifficultyTier 按难度筛选
    -- ============================================
    do
        local mockRoot = Instance.new('Folder')
        mockRoot.Name = 'MockWorkspace'

        createMockRoom('Room_Tier1', 'DeadEnd', { DifficultyTier = 1 }, { 'RoomType/DeadEnd' }, {}).Parent =
            mockRoot
        createMockRoom(
            'Room_Tier2',
            'Straight',
            { DifficultyTier = 2 },
            { 'RoomType/Straight' },
            {}
        ).Parent =
            mockRoot
        createMockRoom(
            'Room_Tier3',
            'ObtuseTurn',
            { DifficultyTier = 3 },
            { 'RoomType/ObtuseTurn' },
            {}
        ).Parent =
            mockRoot
        createMockRoom(
            'Room_Tier2b',
            'AcuteTurn',
            { DifficultyTier = 2 },
            { 'RoomType/AcuteTurn' },
            {}
        ).Parent =
            mockRoot

        local scanResult = MazeWorldScanner.Scan(mockRoot)
        local tier2Rooms = MazeWorldScanner.GetRoomsByDifficultyTier(scanResult, 2)

        assert(#tier2Rooms == 2, string.format('Expected 2 tier-2 rooms, got %d', #tier2Rooms))

        mockRoot:Destroy()

        print('[PASS] MazeWorldScanner.GetRoomsByDifficultyTier correctly filters by tier')
    end

    -- ============================================
    -- Test: ToWorldFormat 转换为世界格式
    -- ============================================
    do
        local mockRoot = Instance.new('Folder')
        mockRoot.Name = 'MockWorkspace'

        local campRoom = createMockRoom(
            'Room_Camp',
            'OpenHub',
            { DifficultyTier = 0, IsCamp = true },
            { 'RoomType/OpenHub' },
            {}
        )
        campRoom.Parent = mockRoot

        local normalRoom = createMockRoom(
            'Room_Normal',
            'DeadEnd',
            { DifficultyTier = 2 },
            { 'RoomType/DeadEnd' },
            { { name = 'SpawnPoint_1', position = Vector3.new(0, 0, 0) } }
        )
        normalRoom.Parent = mockRoot

        local scanResult = MazeWorldScanner.Scan(mockRoot)
        local worldFormat = MazeWorldScanner.ToWorldFormat(scanResult)

        -- 验证格式
        assert(worldFormat.RoomIds ~= nil, 'World format should have RoomIds')
        assert(worldFormat.RoomById ~= nil, 'World format should have RoomById')
        assert(worldFormat.RoomAffordances ~= nil, 'World format should have RoomAffordances')
        assert(worldFormat.CampRoomId == 'Room_Camp', 'World format should have correct CampRoomId')
        assert(
            worldFormat.PatrolPoints ~= nil,
            'World format should have PatrolPoints (even if empty)'
        )
        assert(
            #worldFormat.RoomIds == 2,
            string.format('Expected 2 room IDs, got %d', #worldFormat.RoomIds)
        )

        -- 验证 Affordance 中的 PatrolAnchors
        local normalAff = worldFormat.RoomAffordances['Room_Normal']
        assert(normalAff ~= nil, 'Normal room should have affordance')
        assert(
            #normalAff.PatrolAnchors == 1,
            string.format('Expected 1 patrol anchor, got %d', #normalAff.PatrolAnchors)
        )
        assert(
            normalAff.HasMonsterSpawner == false,
            'Room without HasMonsterSpawner tag should have HasMonsterSpawner=false'
        )

        mockRoot:Destroy()

        print('[PASS] MazeWorldScanner.ToWorldFormat produces correct world format')
    end

    -- ============================================
    -- Test: PatrolAnchors 收集
    -- ============================================
    do
        local mockRoot = Instance.new('Folder')
        mockRoot.Name = 'MockWorkspace'

        local room = createMockRoom('Room_WithPatrols', 'DeadEnd', {}, { 'RoomType/DeadEnd' }, {
            { name = 'SpawnPoint_1', position = Vector3.new(0, 5, 0) },
            { name = 'SpawnPoint_2', position = Vector3.new(10, 5, 0) },
            { name = 'SpawnPoint_3', position = Vector3.new(20, 5, 0) },
            { name = 'LootSocket_1', position = Vector3.new(5, 0, 5) },
        })
        room.Parent = mockRoot

        local scanResult = MazeWorldScanner.Scan(mockRoot)
        local worldFormat = MazeWorldScanner.ToWorldFormat(scanResult)
        local affordance = worldFormat.RoomAffordances['Room_WithPatrols']

        assert(
            #affordance.PatrolAnchors == 3,
            string.format('Expected 3 patrol anchors, got %d', #affordance.PatrolAnchors)
        )
        assert(
            #affordance.SpawnSockets == 1,
            string.format('Expected 1 loot socket, got %d', #affordance.SpawnSockets)
        )
        assert(
            affordance.PatrolAnchors[1].Position == Vector3.new(0, 5, 0),
            'First patrol anchor position incorrect'
        )
        assert(
            affordance.SpawnSockets[1].Position == Vector3.new(5, 0, 5),
            'Loot socket position incorrect'
        )

        mockRoot:Destroy()

        print('[PASS] MazeWorldScanner correctly collects PatrolAnchors and SpawnSockets')
    end

    print('[PASS] All MazeWorldScanner spec tests passed')
end
