-- RunMonsterSpawnPolicy.luau
-- 纯策略函数：收集巡逻点 + 选择初始/随机巡逻索引
-- Run 的巡逻点由 Studio 人工摆放（SpawnPoint_* BasePart）

local RunMonsterSpawnPolicy = {}

-- 船只碰撞体中心（ship 附近作为 exclusion zone，不生成怪物）
local SHIP_EXCLUSION_RADIUS = 60

-- 收集所有有效巡逻点，排除 ship 附近 exclusion zone
-- patrolPositions: Vector3[] — 所有扫描到的 SpawnPoint_* 位置
-- shipPosition: Vector3 — 船只位置（用于计算 exclusion zone）
-- 返回 {eligiblePositions[], shipPosition}
function RunMonsterSpawnPolicy.collectEligiblePatrolPoints(patrolPositions, shipPosition)
    if not shipPosition or type(shipPosition.X) ~= 'number' then
        -- 没有 ship 位置时，全部可用
        return patrolPositions
    end

    local eligible = {}
    for _, pos in ipairs(patrolPositions) do
        local offset = pos - shipPosition
        local dist2D = Vector3.new(offset.X, 0, offset.Z).Magnitude
        if dist2D > SHIP_EXCLUSION_RADIUS then
            table.insert(eligible, pos)
        end
    end

    return eligible
end

-- 选择初始巡逻索引：返回第一个有效巡逻点索引
-- patrolPositions: Vector3[] — 可用巡逻点
function RunMonsterSpawnPolicy.selectInitialPatrolIndex(patrolPositions)
    if #patrolPositions == 0 then
        return nil
    end
    return 1
end

-- 随机选择有效巡逻索引
-- patrolPositions: Vector3[] — 可用巡逻点
-- randomSource: Random — 随机源（用于确定性）
function RunMonsterSpawnPolicy.selectRandomEligiblePatrolIndex(patrolPositions, randomSource)
    if #patrolPositions == 0 then
        return nil
    end

    local random = randomSource or Random.new()
    return random:NextInteger(1, #patrolPositions)
end

return RunMonsterSpawnPolicy
