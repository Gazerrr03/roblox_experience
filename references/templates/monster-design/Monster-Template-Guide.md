# Monster 模板接入指南

本文档说明如何新增一个怪物模板，确保新怪 90% 只改配置即可落地。

---

## 1. 模板结构

每个怪物模板是一个 author profile，结构如下：

```lua
{
    Id = 'monster-id',           -- 唯一标识， kebab-case
    Name = 'Display Name',       -- 显示名
    Semantics = {                -- 背景叙事（不影响运行时）
        Lore = '背景描述',
        Atmosphere = 'Dread',    -- Dread | Horror | Tense | Rush | Pressure | Brutal
        TriggerIntent = {
            Summary = '触发条件描述',
            Space = '触发空间描述',
        },
        CounterplayIntent = {
            Summary = '玩家反制方式',
            Tool = '反制工具',
        },
    },
    Health = {                   -- 生命值配置
        MaxHp = 3,               -- 整数 >= 1
    },
    Tuning = {                   -- 数值调优
        Speed = 14,              -- 移动速度 (8-20)
        SightRange = 36,         -- 视野范围 (20-60)
        PatrolSpeedMultiplier = 0.45, -- 巡逻速度倍率 (0.2-0.9)
        AttackRange = 4,         -- 攻击范围 (> 0)
        AttackCooldownSeconds = 1, -- 攻击冷却 (秒)
        AttackDamagePips = 1,    -- 伤害等级：1=Light, 2=Heavy
        CombatHitPoints = 3,     -- 默认 MaxHp（可被 Health.MaxHp 覆盖）
        SpawnOffset = Vector3.new(0, 4, 0),
    },
    Executable = {
        Presentation = {
            ModelAssetId = 0,              -- Roblox AssetId
            RigType = 'R6',                -- R6 | R15
            AnimationMode = 'defaultR6',   -- defaultR6 | ...
            ChaseLoopSoundAssetId = 0,     -- 可选
        },
        BehaviorIntents = {
            { Id = 'Patrol', Enabled = false },   -- 巡逻
            { Id = 'SenseNearestTarget' },        -- 感知最近目标
            { Id = 'Chase' },                     -- 追击
            { Id = 'Attack' },                    -- 攻击
            { Id = 'LoseTarget' },                -- 丢失目标
        },
        EffectIntents = {
            { Id = 'SprintSuppressed', DurationSeconds = 2.5 },
            -- 其他效果...
        },
    },
}
```

---

## 2. 分层说明

| 分层 | 用途 | 是否影响运行时行为 |
|---|---|---|
| `Semantics` | 背景叙事、设计师意图文档 | 否 |
| `Health` | 生命值配置 | 是 |
| `Tuning` | 数值调优 | 是 |
| `Executable` | 行为和效果意图 | 是 |

---

## 3. 新增怪物步骤

### Step 1 — 在 `Config/Monsters.luau` 中添加模板

```lua
-- packages/gameplay/src/Config/Monsters.luau
return {
    -- 现有 scrap-wisp...
    {
        Id = 'scrap-brute',
        Name = 'Scrap Brute',
        Semantics = { ... },
        Health = { MaxHp = 5 },
        Tuning = {
            Speed = 11,
            SightRange = 32,
            PatrolSpeedMultiplier = 0.5,
            AttackRange = 5,
            AttackCooldownSeconds = 1.5,
            AttackDamagePips = 2,  -- Heavy damage
            CombatHitPoints = 5,
            SpawnOffset = Vector3.new(0, 4, 0),
        },
        Executable = {
            -- ...
        },
    },
}
```

### Step 2 — 编译验证

在 Roblox Studio 或测试环境中运行：

```lua
local MonsterCompiler = require(Packages.Gameplay.Monsters.MonsterCompiler)
local Monsters = require(Packages.Gameplay.Config.Monsters)

local template = Monsters[2]  -- 新增的模板
local ok, runtimeProfile, report = MonsterCompiler.compileMonsterForMaze(template)
assert(ok, 'Compile failed: ' .. tostring(runtimeProfile))
```

### Step 3 — 接入 MonsterService

在 `MazeSessionService` 或 `RunSessionService` 的怪物生成逻辑中：

```lua
local runtimeProfiles = {}
for _, template in ipairs(Monsters) do
    local ok, profile = MonsterCompiler.compileMonsterForMaze(template)
    if ok then
        table.insert(runtimeProfiles, profile)
    end
end
-- 使用 runtimeProfiles 初始化怪物服务...
```

### Step 4 — 写测试（推荐）

在 `tests/src/Shared/MonsterCompiler.spec.luau` 中添加：

```lua
local bruteProfile = gameplay.Config.Monsters[2]
local bruteOk, bruteRuntime = MonsterCompiler.compileMonsterForMaze(bruteProfile)
assert(bruteOk == true, 'Brute compile must succeed')
assert(bruteRuntime.Components.Health.MaxHp == 5, 'Brute HP must be 5')
```

---

## 4. 组件接口协议

所有组件必须实现以下接口：

| 方法 | 必需 | 说明 |
|---|---|---|
| `new()` | 是 | 构造函数，返回组件实例 |
| `init(blackboard)` | 否 | 初始化，spawn 时调用一次 |
| `update(blackboard, dt)` | 否 | 每 tick 更新 |
| `destroy(blackboard)` | 否 | 销毁，可释放资源 |

组件通过 `blackboard.Context` 读取配置，通过 `blackboard.Transient` 写入结果。

---

## 5. HealthComponent 用法

```lua
-- 在 Enemy 实例上调用
local enemy = Enemy.new(runtimeProfile, options)

-- 扣血
enemy:applyDamage(1, 'player')

-- 加血
enemy:heal(1)

-- 查询状态
local hp = enemy:getHealth()
print(hp.CurrentHp, hp.MaxHp, hp.IsDead)
```

---

## 6. 快速参考：Behavior Intent 含义

| Behavior | 说明 |
|---|---|
| `Patrol` | 在巡逻点之间移动 |
| `SenseNearestTarget` | 检测最近玩家 |
| `Chase` | 朝目标移动 |
| `Attack` | 在攻击范围内造成伤害 |
| `LoseTarget` | 目标丢失后转为搜索/巡逻 |
| `Suppressed` | 被压制（暂停行为） |

## 7. 快速参考：Effect Intent 含义

| Effect | 说明 |
|---|---|
| `SprintSuppressed` | 玩家冲刺速度被压制 |
| `DamageLight` | 轻伤害（1 pip） |
| `DamageHeavy` | 重伤害（2 pip） |
| `MonsterStunned` | 怪物眩晕 |

---

## 8. 常见问题

**Q: `Health.MaxHp` 和 `Tuning.CombatHitPoints` 有什么区别？**

`Health.MaxHp` 是显式生命值配置，`Tuning.CombatHitPoints` 是兜底默认值。优先使用 `Health.MaxHp`，`CombatHitPoints` 保持向后兼容。

**Q: 行为列表可以为空吗？**

可以，但怪物将不会有任何行为（不会移动、不会感知、不会攻击）。至少需要 `SenseNearestTarget` 才能检测玩家。

**Q: 如何禁用某个效果但保留行为？**

在 `EffectIntents` 中使用 `{ Id = 'xxx', Enabled = false }`。
