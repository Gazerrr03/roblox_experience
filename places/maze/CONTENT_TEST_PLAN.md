# Maze 当前内容测试计划

基于最新 `main` 的 Maze live path，目标是在**不导入外部地图资产之前**，先把当前 `/Users/qizhi_dong/Projects/roblox_experience/places/maze/harness/maze.rbxlx` 上所有可见 feature 做一轮最基础内容验收。

## 0. 测试基线

- 内容测试基底：`places/maze/harness/maze.rbxlx`
- live authored source：运行时组装出的 `Workspace/MazeStaticWorld`
- 真相源以代码为准，重点覆盖：
  - 静态世界组装
  - authored contract
  - HUD / 快照
  - 交互
  - 怪物
  - 工具与输入
  - 死亡掉包与恢复
  - 返回
  - direct-boot 行为
- 本轮**不把跨 Place 真传送闭环**作为阻塞项；它属于后续集成测试，不阻塞当前 Maze 内容测试

## 1. 测试前准备

- 使用最新 `origin/main` 对应的 Maze harness 内容
- 在 Studio 打开 `places/maze/harness/maze.rbxlx`
- 首轮先做单人 Play；若环境允许，再补 2 人最小同步 smoke
- 注意：`places/maze/harness/maze.rbxlx` 是 authored place file，除非明确要 reset scaffold，不要从 Rojo 重新生成覆盖它

## 2. 功能验收清单

### A. 启动与 authored 世界装配

- 单人 Play 后不出现 bootstrap fail
- 玩家以第一人称进入 Maze
- `MazeBootstrapStatus` 无失败提示
- 世界中至少能确认：
  - `SpawnMarker`
  - `ReturnHoldPad`
  - 1 个 loot 房
  - 1 扇门
  - 1 组 `MonsterSpawns/SpawnPoint_*`
- Lighting 已应用 Maze profile，场景不是默认 Baseplate 外观

### B. HUD、快照与 direct-boot 基线

- 左上 HUD 可见以下内容：
  - `Status`
  - `Objective`
  - `Inventory`
  - `PlayerState`
  - `Roster`
  - `Returned summaries`
- 状态文案体现 direct-boot 语义，不是空白或旧 run 文案
- `MazeState` 驱动的区域、目标、背包、状态会随操作更新
- `MazePrivateState` 当前为空实现，但不应报错或显示脏数据
- 观察项：
  - 右上手表 HUD 若未出现或不更新，记录为观察项，不判失败

### C. Authored 交互面

- 在当前默认 overlay 内容上逐个验证所有 prompt：
  - `Doorway_East` 可开关，碰撞与透明度切换正常，prompt 文案在 `Open/Close` 间切换
  - `LootPrompt` 可拾取；拾取后 prompt / 节点消失，HUD loot 数量增加
  - `ReturnHoldPad` 可触发返回逻辑，至少能看到本地状态变化与 direct-boot fallback 文案
- 要求：
  - 所有交互都必须来自 authored prompt part
  - 不依赖运行时临时生成交互件

### D. 背包、工具与输入

- 验证 `1-3` / `X` / `F` / `LeftShift` 输入链路
- 通过标准：
  - `1-3` 可装备快捷栏前 3 个槽位
  - `X` 可卸下 held item
  - `F` 可触发 `RequestUseTool`
  - `LeftShift` 可触发冲刺开始 / 结束，HUD movement 状态变化正常
- 道具表现：
  - Flashlight：装备后有头灯 / 光源表现
  - Crowbar：按 `F` 有本地 swing feedback，且服务端逻辑正常接收
  - Potion：按 `F` 后不报错，反馈符合当前实现
- 说明：
  - 当前快捷栏就是硬编码 3 槽，本轮不额外测分页

### E. 怪物主循环与近战反击

- 单人内容测试必须把怪物完整跑一遍
- 通过标准：
  - 怪物会在 `MonsterSpawns/SpawnPoint_*` 上生成，不会静默缺失
  - 怪物会 patrol，并能进入 chase / attack
  - 玩家被命中后，血量与状态快照会变化
  - 使用 crowbar 时，至少验证一次“命中有效”和一次“未命中不误伤”
- 失败判据：
  - 怪物完全不生成
  - 怪物只站桩不巡逻
  - 怪物交互后 HUD / 状态不同步

### F. 死亡、尸体包与恢复

- 优先用 Studio `H / J` debug damage 做稳定验证，再补一次真实怪物击杀
- 通过标准：
  - 玩家死亡后会生成 corpse / dropped pack，而不是吞包
  - 玩家会被移到 return hold 区域，不能继续正常交互
  - 场景中出现可恢复的 dropped pack prompt
  - 恢复 dropped pack 后，物品回到背包，场景节点消失或剩余内容正确更新
  - 已掉落 / 已捡回状态与 HUD 一致，不出现重复复制或丢失

### G. 持久化与内容重建最小 smoke

- 先拾取一次 loot
- 再做一次可重建场景的 smoke（推荐重新进场或重开 Play Session）
- 再做一次死亡掉包并恢复
- 验收重点：
  - 已 collected 的 authored loot 不应在同一轮验证里立即复活
  - dropped pack 的 recover 行为前后一致
- 说明：
  - 真正的 5 回合跨 Place 持久化不在本轮 gate 内

### H. 多人最小同步冒烟（可选）

- 若 Studio 环境允许，补一轮 2 人最小同步
- 最低覆盖：
  - 两名玩家能加入同一 Maze session
  - roster / returned summaries 对双方一致
  - 一人开门 / 拿 loot，另一人能看到结果
  - 一人先返回后，另一人仍能继续在 Maze 中活动
- 本轮不要求：
  - 真跨 Place teleport 成功
  - host / camp / debrief 全链路

## 3. 负向 smoke

- 在**测试副本**里做一次 authored contract 破坏验证
- 推荐二选一：
  - 删除 `Room_Loot/MonsterSpawns`
  - 或把 `LootPrompt` / `ReturnHoldPad` 改名
- 通过标准：
  - 启动会 fail loud
  - 错误信息能指出缺失 authored node，而不是 silent fallback

## 4. 退出条件

只有以下项目全部通过，才允许进入“导入外部地图资产”阶段：

- 启动与 authored contract 校验通过
- 门 / loot / return 三类 prompt 全通过
- 快捷栏 / equip / unequip / use-tool / sprint 全通过
- 怪物生成 / patrol / chase / attack / crowbar melee 全通过
- 死亡掉包 / dropped pack recover 全通过
- HUD 快照与实际状态一致，无明显错字、空白、旧语义

以下项目本轮可记录但不阻塞：

- `TODState` 手表 HUD 未完全生效
- `MazePrivateState` 仍为空
- `Library Place ID` 仍未配置
- Run ↔ Maze 真跨 Place 传送与 5 回合闭环尚未验收

## 5. 测试后建议

- 若本轮内容测试通过，再进入外部地图资产导入
- 外部资产导入前，建议先补一轮文档同步，重点更新：
  - `FEATURES.md` 中 live path 描述
  - `MazeEntryAvailability` 状态
  - `TODState` remote
  - dropped pack / corpse / world-build metadata 等当前 live feature
