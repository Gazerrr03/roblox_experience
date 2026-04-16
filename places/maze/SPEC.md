# Maze 重构执行规范
> version: 0.1 (draft)
> 状态: 待执行
> 依赖: Blender MCP 标注工具链

---

## 1. 核心概念

### 回合（Round）
- 1 回合 = 15 现实分钟
- 每现实分钟 = 游戏内 1 小时（6:00 → 20:00，覆盖早出晚归）
- 回合结束 → TOD 日夜推进 → 天空盒切换 → 玩家在 Ship 复活

### 局（Mission / Session）
- 1 局 = 多个回合组成，完整任务周期
- 局结束条件：完成大目标 或 所有玩家全部死亡

### 死亡机制（回合级）
| 行为 | 描述 |
|------|------|
| 死亡掉落 | 玩家死亡后物品掉落在原地形成"尸体" |
| 切换视角 | 死亡后可切换到任意存活队友的视角观察 |
| 回合复活 | 这回合死亡 → 下回合在 Ship 营地复活，继续游戏 |
| 彻底死亡 | 当前局所有回合结束后仍未复活 → 物品永久丢失（待确认） |

---

## 2. DCC 资产规范（Blender → Roblox）

### 格式
- 导出格式：fbx 或 glb
- Blender MCP 做关键点标注（Empty 物体创建+命名）

### Blender Empty 命名约定

| 类型 | Empty 名称格式 | 说明 |
|------|---------------|------|
| 门轴心 | `DOOR_Pivot_<id>` | 放置在门铰链位置（旋转中心） |
| 门本体 | `Door_<id>`（mesh） | 门板几何体 |
| 战利品点 | `LOOT_Socket_<id>` | 战利品生成位置（Roblox 端手动创建 LootSocket_* BasePart，位置与 Empty 对齐） |
| 通用标记 | `MARKER_<type>_<id>` | 其他功能节点 |

### 门规范（Blender 层）
- 门本体：单独 mesh，命名 `Door_<id>`
- 轴心 Empty：`DOOR_Pivot_<id>`，放置于门铰链位置
- 旋转轴：MCP 读取 Empty 的 world position + rotation，写入 Roblox Attachment
- 图层规范：门相关的所有物体放在 Blender 层 `Layer 10`（专用层）
- Blender MCP 操作：创建 Empty、命名、设置 transform、设置层

### 怪物刷新点
- **不在 DCC 里做**
- Roblox 端手动摆放 `SpawnPoint_*` BasePart（与 run 相同）

### 战利品节点
- **沿用 `LootSocket_*` BasePart**，Roblox 端手动摆放

---

## 3. TOD 时间系统

### Roblox 实现方案

**Lighting.ClockTime 驱动**（推荐）：
```
Lighting.ClockTime 范围 0-24（小时）
回合开始：ClockTime = 6（早上）
回合内：TweenService 插值推进，每 1 现实秒推进 (14/900) 游戏小时
回合结束：ClockTime ≈ 20（日落）
```

**天空盒**：
- Roblox 内置 sky 随 `ClockTime` 自动更新太阳角度和颜色
- 可叠加 `ColorCorrectionEffect` + `AtmosphereEffect` 做氛围增强

### TODProfile 配置表
```lua
-- packages/shared/src/Config/TODProfile.luau
local TODProfile = {
    Dawn   = { ClockTime = 5.5, Brightness = 0.1, Saturation = 0.3 },
    Morning = { ClockTime = 8.0, Brightness = 0.5, Saturation = 0.6 },
    Noon   = { ClockTime = 12.0, Brightness = 0.8, Saturation = 0.7 },
    Sunset = { ClockTime = 17.5, Brightness = 0.4, Saturation = 0.5 },
    Night  = { ClockTime = 21.0, Brightness = -0.2, Saturation = 0.2 },
}
```

> ⚠️ TOD 系统具体实现见 GitHub Issue: `maze重构 - TOD-001`

---

## 4. 怪物系统（保留不变）

- 完整保留 `MonsterService` + `EnemyRuntime` + `EnemyStateMachine`
- 刷新点：Roblox 端手动摆放 `SpawnPoint_*`
- 行为（Patrol/Chase/Attack/Sense）：不变

---

## 5. 物资系统（保留不变）

- 完整保留 `InventoryService`
- 战利品节点：沿用 `LootSocket_*` BasePart

---

## 6. Library Place ID + 撤离结算

> ⚠️ `SessionConfig.PlaceIds.Library = 0` 标记 TODO，需替换为真实 Place ID
> ⚠️ `CampMazeSessionContract.applyReturn` 有 `WasSettled` 标记但流程未激活

---

## 7. 改造优先级

| 优先级 | 内容 | 工作量 |
|--------|------|--------|
| P0 | SPEC.md（本文件）+ DCC 标注规范验证 | 0.5d |
| P0 | Library Place ID + 撤离结算打通 | 2d |
| P1 | TOD 时间系统 | 2-3d |
| P1 | 回合级死亡/复活 | 3d |
| P1 | 回合管理 UI | 1d |
| P2 | 关卡拼装脚本 | 3-4d |

**总工作量估算：~13-17d（含美术等待时间）**

---

## 8. 待调研项（GitHub Issues）

| Issue | 标题 | 内容 |
|-------|------|------|
| TOD-001 | Roblox 天空盒动态切换实现 | 是否需要自定义 skybox 贴图，还是 Roblox 内置 sky 已够用 |
| TOD-002 | 回合时间流速调优 | 1 现实秒 = ? 游戏秒，需实际体验调整 |
| TOD-003 | 天空盒美术资源规格 | 需要什么规格的贴图？Roblox 官方 sky 还是自定？ |

---

## 9. 待确认项

- [ ] 彻底死亡后物品是否参与撤离结算
- [ ] TOD 时间流速最终值（等 TOD-002 调研后确认）
- [ ] 天空盒美术资源（等 TOD-003 调研后确认）
