--[[
    MazeWorldScanner
    运行时扫描 Workspace 中的静态房间实例，建立供其他系统使用的数据结构。

    ============================================
    房间模型设置规范（Authoring Guide）
    ============================================

    在 Roblox Studio 中，每个房间实例需要设置以下内容：

    1. TAG（标签）- 用于识别房间类型
       添加格式如：Tag = "RoomType/DeadEnd"

       常用房间类型 Tag：
       - RoomType/DeadEnd      → 死胡同
       - RoomType/Straight      → 直走廊
       - RoomType/ObtuseTurn    → 钝角转弯
       - RoomType/AcuteTurn     → 锐角转弯
       - RoomType/SymmetricY    → Y 型三岔
       - RoomType/TJunction     → T 型三岔
       - RoomType/Cross4        → 四路交叉
       - RoomType/OpenHub       → 开放中枢

    2. ATTRIBUTE（属性）- 用于配置房间游玩数据
       在实例上右键 → 添加属性，添加以下属性：

       | 属性名          | 类型   | 默认值 | 说明                          |
       |-----------------|--------|--------|-------------------------------|
       | RoomType        | string | -      | 同 Tag 里的类型名              |
       | DifficultyTier  | int    | 1      | 0-4 难度等级                  |
       | MonsterBudget   | int    | 0      | 怪物刷新上限                  |
       | LootBudget      | int    | 0      | 道具刷新上限                  |
       | IsCamp          | bool   | false  | 是否为入口安全区              |
       | IsExtraction    | bool   | false  | 是否为撤离区                  |
       | IsScenery       | bool   | false  | 是否为造景（扫描时跳过）       |

    3. 子级标记点（用于刷新和巡逻）
       在房间实例下创建子级 Part，命名规范：

       - SpawnPoint (如 "SpawnPoint_1", "SpawnPoint_2")
         → 怪物刷新位置标记

       - LootSocket (如 "LootSocket_1")
         → 道具刷新位置标记

       - Doorway (如 "Doorway_North")
         → 出口方向标记（可选）

    4. 特殊 TAG
       - HasMonsterSpawner  → 该房间包含怪物刷新点
       - HasLootSocket     → 该房间包含道具刷新点

    5. 造景处理
       - 将造景物体放入名为 "Scenery" 的 Folder 下
       - 或给造景物体设置 IsScenery = true 属性
       → 扫描时会自动跳过，不影响游戏逻辑

    ============================================
    示例：创建一个死胡同怪物房间
    ============================================

    1. 在 Workspace 下创建 Model，命名为 "Room_DeadEnd_Monster_01"
    2. 给 Model 添加 Tag: "RoomType/DeadEnd"
    3. 给 Model 添加 Attribute:
       - DifficultyTier = 2
       - MonsterBudget = 3
       - IsCamp = false
    4. 添加 Tag: "HasMonsterSpawner"
    5. 在 Model 下创建 3 个 Part 作为刷新点:
       - Part 命名 "SpawnPoint_1"，Position 设置在房间内
       - Part 命名 "SpawnPoint_2"，Position 设置在房间内
       - Part 命名 "SpawnPoint_3"，Position 设置在房间内
    6. 完成！

    扫描规则：
    - 跳过 Scenery 文件夹或其 IsScenery=true 的实例
    - 收集所有带 RoomType/* Tag 的实例作为房间
    - 子级 SpawnPoint/LootSocket 用于建立 Affordance 数据
]]

local Workspace = game:GetService('Workspace')

local MazeWorldScanner = {}
MazeWorldScanner.__index = MazeWorldScanner

-- 默认扫描根目录
local DEFAULT_SCAN_ROOT = Workspace

-- 扫描配置
local SCAN_CONFIG = {
    RoomTagPrefix = 'RoomType/',
    HasMonsterSpawnerTag = 'HasMonsterSpawner',
    HasLootSocketTag = 'HasLootSocket',
    DoorwayTagPrefix = 'Doorway/',
    SceneryFolderName = 'Scenery',
    SceneryAttribute = 'IsScenery',
}

-- 默认房间 Attribute
local DEFAULT_ATTRIBUTES = {
    RoomType = 'Unknown',
    DifficultyTier = 1,
    MonsterBudget = 0,
    LootBudget = 0,
    IsCamp = false,
    IsExtraction = false,
    IsScenery = false,
}

-- 类型名称映射
local ROOM_TYPE_ALIASES = {
    DeadEnd = 'DeadEnd',
    Straight = 'Straight',
    ObtuseTurn = 'ObtuseTurn',
    AcuteTurn = 'AcuteTurn',
    SymmetricY = 'SymmetricY',
    TJunction = 'T-Junction',
    Cross4 = 'Cross4',
    OpenHub = 'OpenHub',
}

local function getOrCreateScannerCache(root)
    -- 每个 root 维护自己的扫描缓存
    if not root then
        root = DEFAULT_SCAN_ROOT
    end
    return root
end

local function readAttribute(instance, name, default)
    local value = instance:GetAttribute(name)
    return value ~= nil and value or default
end

local function hasTag(instance, tag)
    return instance:HasTag(tag)
end

local function isSceneryInstance(instance)
    -- 检查 IsScenery 属性
    if readAttribute(instance, SCAN_CONFIG.SceneryAttribute, false) == true then
        return true
    end

    -- 检查父级是否为 Scenery 文件夹
    local parent = instance.Parent
    if parent and parent.Name == SCAN_CONFIG.SceneryFolderName and parent:IsA('Folder') then
        return true
    end

    return false
end

local function collectSpawnPoints(roomInstance)
    local spawnPoints = {}
    for _, child in ipairs(roomInstance:GetChildren()) do
        if child:IsA('Instance') and string.find(child.Name, 'SpawnPoint') then
            table.insert(spawnPoints, {
                Name = child.Name,
                Position = child.Position,
            })
        end
    end
    return spawnPoints
end

local function collectLootSockets(roomInstance)
    local lootSockets = {}
    for _, child in ipairs(roomInstance:GetChildren()) do
        if child:IsA('Instance') and string.find(child.Name, 'LootSocket') then
            table.insert(lootSockets, {
                Name = child.Name,
                Position = child.Position,
            })
        end
    end
    return lootSockets
end

local function collectDoorways(roomInstance)
    local doorways = {}
    for _, child in ipairs(roomInstance:GetChildren()) do
        if child:IsA('Instance') and string.find(child.Name, 'Doorway') then
            table.insert(doorways, {
                Name = child.Name,
                Position = child.Position,
                Direction = child:GetAttribute('Direction') or 'Unknown',
            })
        end
    end
    return doorways
end

local function isRoomInstance(instance)
    -- 必须有 RoomType Tag 才算房间
    for tag in instance:GetTags() do
        if string.sub(tag, 1, string.len(SCAN_CONFIG.RoomTagPrefix)) == SCAN_CONFIG.RoomTagPrefix then
            return true
        end
    end
    return false
end

local function extractRoomType(instance)
    for tag in instance:GetTags() do
        if string.sub(tag, 1, string.len(SCAN_CONFIG.RoomTagPrefix)) == SCAN_CONFIG.RoomTagPrefix then
            return string.sub(tag, string.len(SCAN_CONFIG.RoomTagPrefix) + 1)
        end
    end
    return 'Unknown'
end

local function buildAffordance(instance)
    local affordance = {
        RoomId = instance.Name,
        RoomType = extractRoomType(instance),
        SpawnSockets = collectLootSockets(instance), -- 道具刷新点
        PatrolAnchors = collectSpawnPoints(instance), -- 怪物巡逻点
        SightBreakers = {}, -- 视线阻挡几何，暂用空表
        DoorControlPoints = collectDoorways(instance), -- 门控提示点
        ThreatTags = {},
        HasMonsterSpawner = hasTag(instance, SCAN_CONFIG.HasMonsterSpawnerTag),
        HasLootSocket = hasTag(instance, SCAN_CONFIG.HasLootSocketTag),
    }

    -- ThreatTags 标记
    if hasTag(instance, SCAN_CONFIG.HasMonsterSpawnerTag) then
        table.insert(affordance.ThreatTags, 'RoomKind:Loot')
    end

    return affordance
end

local function buildRoomData(instance)
    local roomData = {
        Id = instance.Name,
        Type = extractRoomType(instance),
        Position = instance.Position,
        DifficultyTier = readAttribute(instance, 'DifficultyTier', DEFAULT_ATTRIBUTES.DifficultyTier),
        MonsterBudget = readAttribute(instance, 'MonsterBudget', DEFAULT_ATTRIBUTES.MonsterBudget),
        LootBudget = readAttribute(instance, 'LootBudget', DEFAULT_ATTRIBUTES.LootBudget),
        IsCamp = readAttribute(instance, 'IsCamp', DEFAULT_ATTRIBUTES.IsCamp),
        IsExtraction = readAttribute(instance, 'IsExtraction', DEFAULT_ATTRIBUTES.IsExtraction),
        Neighbors = {}, -- 稍后通过 Doorway 位置关系建立
    }

    return roomData
end

local function scanRecursive(root, results, visited)
    if not root or visited[root] then
        return
    end
    visited[root] = true

    -- 跳过 Scenery 文件夹
    if root:IsA('Folder') and root.Name == SCAN_CONFIG.SceneryFolderName then
        return
    end

    -- 检查是否为需要跳过的 Scenery 实例
    if isSceneryInstance(root) then
        return
    end

    -- 检查是否为房间实例
    if isRoomInstance(root) then
        table.insert(results.rooms, root)
        return -- 不继续遍历房间内部子级（子级是标记点，不是房间）
    end

    -- 递归遍历子级
    for _, child in ipairs(root:GetChildren()) do
        scanRecursive(child, results, visited)
    end
end

--[[
    扫描 Workspace 中的所有房间实例
    @param scanRoot optional, 扫描起始点，默认 Workspace
    @return rooms, afforances, roomById, roomAffordances
]]
function MazeWorldScanner.Scan(scanRoot)
    local root = scanRoot or DEFAULT_SCAN_ROOT
    local results = {
        rooms = {},
    }
    local visited = {}

    -- 遍历收集所有房间实例
    for _, child in ipairs(root:GetChildren()) do
        scanRecursive(child, results, visited)
    end

    -- 建立房间数据
    local roomById = {}
    local roomAffordances = {}
    local campRoomId = nil

    for _, roomInstance in ipairs(results.rooms) do
        local roomData = buildRoomData(roomInstance)
        local affordance = buildAffordance(roomInstance)

        roomById[roomInstance.Name] = roomData
        roomAffordances[roomInstance.Name] = affordance

        if roomData.IsCamp then
            campRoomId = roomInstance.Name
        end
    end

    -- 建立邻居关系（通过 Doorway 位置近似判断）
    -- 简化版：同一直线方向上距离接近的两个房间视为邻居
    for idA, roomA in pairs(roomById) do
        for idB, roomB in pairs(roomById) do
            if idA ~= idB then
                local delta = roomB.Position - roomA.Position
                local distance = delta.Magnitude
                -- 六边形房间中心距约 40 studs，在此距离内的视为潜在邻居
                if distance < 50 then
                    table.insert(roomA.Neighbors, idB)
                end
            end
        end
    end

    return {
        rooms = results.rooms,
        roomById = roomById,
        roomAffordances = roomAffordances,
        campRoomId = campRoomId,
    }
end

--[[
    异步扫描，返回 Promise（如果可用）或直接返回结果
    简化版：直接同步返回，配合游戏加载阶段的异步调度使用
]]
function MazeWorldScanner.ScanAsync(scanRoot)
    -- Luau 没有原生 Promise，直接同步返回
    -- 调用方可在 spawn() 或 task.spawn() 中调用以不阻塞主线程
    return MazeWorldScanner.Scan(scanRoot)
end

--[[
    根据房间 ID 获取房间数据
]]
function MazeWorldScanner.GetRoomById(scanResult, roomId)
    return scanResult.roomById and scanResult.roomById[roomId]
end

--[[
    获取所有房间 ID 列表
]]
function MazeWorldScanner.GetRoomIds(scanResult)
    local ids = {}
    if scanResult.roomById then
        for id in pairs(scanResult.roomById) do
            table.insert(ids, id)
        end
    end
    return ids
end

--[[
    获取带 HasMonsterSpawner Tag 的房间 ID 列表
]]
function MazeWorldScanner.GetEligibleMonsterRooms(scanResult)
    local eligible = {}
    if scanResult.roomAffordances then
        for roomId, aff in pairs(scanResult.roomAffordances) do
            if aff.HasMonsterSpawner then
                table.insert(eligible, roomId)
            end
        end
    end
    return eligible
end

--[[
    获取难度分区
]]
function MazeWorldScanner.GetRoomsByDifficultyTier(scanResult, tier)
    local rooms = {}
    if scanResult.roomById then
        for id, room in pairs(scanResult.roomById) do
            if room.DifficultyTier == tier then
                table.insert(rooms, id)
            end
        end
    end
    return rooms
end

--[[
    公共函数：检查实例是否为造景

    @param instance Instance 待检查的实例
    @return boolean 是否为造景
]]
function MazeWorldScanner.IsSceneryInstance(instance)
    return isSceneryInstance(instance)
end

--[[
    公共函数：从实例的 Tag 中提取房间类型

    @param instance Instance 待检查的房间实例
    @return string 房间类型名称，如 'DeadEnd'、'Straight' 等
]]
function MazeWorldScanner.GetRoomTypeFromInstance(instance)
    return extractRoomType(instance)
end

--[[
    将扫描结果转换为 MazeSessionService 期望的世界格式

    MazeSessionService.collectPatrolPointsFromWorld() 期望:
    - world.RoomIds: array of room IDs
    - world.RoomById: map of roomId -> room data
    - world.RoomAffordances: map of roomId -> affordance data
    - world.CampRoomId: string
    - world.PatrolPoints: array (optional)
    - world.InitialMonsterPatrolIndex: number (optional)
]]
function MazeWorldScanner.ToWorldFormat(scanResult)
    local roomIds = MazeWorldScanner.GetRoomIds(scanResult)

    return {
        RoomIds = roomIds,
        RoomById = scanResult.roomById,
        RoomAffordances = scanResult.roomAffordances,
        CampRoomId = scanResult.campRoomId,
        PatrolPoints = {}, -- 空的，由 collectPatrolPointsFromWorld 从 Affordances 收集
        InitialMonsterPatrolIndex = nil,
    }
end

return MazeWorldScanner
