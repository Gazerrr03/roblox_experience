# Formal Terminology And Player-Facing Language

## Purpose

这篇文档回答两个问题：

1. 当前 deadline slice 里，玩家到底应该听到什么词？
2. 哪些词可以留在系统兼容层，哪些词必须避免混用？

主要读者：策划、文案、UI/UX、系统设计、实现任务状态与反馈的人。

## Current Decision

- 当前 slice 的正式玩家目标语言是：`书页 / Pages`。
- 玩家被派往 Maze 的最直接任务，是“进入迷宫、回收书页、活着带回来”。
- `Pages` 在玩家表层理解里，首先是任务目标和营地经济资源。
- `loot`、`banked loot`、`quota item`、`mission cargo` 这类词，不应作为当前玩家主叙述词。
- `Run`、`Maze` 可以继续作为团队内部与文档中的结构词，但玩家视角应优先使用“营地 / 荒野 / 迷宫 / 船”这类具象表达。
- “你是谁、书页到底是什么、为何会循环”这些深层真相，不在当前 formal 里明牌解释。

## Slice Rule

### 玩家可直接看到或听到的主词

- 书页 / Pages
- 任务 / Assignment / 回收任务
- 营地 / 船
- 迷宫
- 撤离 / 带回 / 存活返回
- 工具 / 补给

### 允许存在但不能抢主叙述位的兼容词

- loot
- banked item count
- target item count
- mission cargo
- quota

这些词可以暂时存在于：
- 代码命名
- 兼容字段
- 临时调试文案
- 尚未迁完的内部面板

但不能继续作为：
- 玩家主 HUD 文案
- 核心任务提示
- clue 正文叙述主词
- 商店和结算的外显语言

### 当前禁止混用的方向

- 一处叫“书页”，另一处又把同一目标直接叫“loot”
- 一边说玩家是在执行任务，一边又把目标写成无意义的 generic 收集物
- 一边强调 Pages 是当前表层经济，一边在主 UI 上用过于抽象的“quota cargo”替代它

## Long-term Direction

- 长期可以让 `Pages` 保持双层意义：表层是任务资源，深层是更异常的记忆 / 认知载体。
- 长期可以把上位系统语言和玩家语言做出明确错位，例如玩家听到的是“书页”，而系统内部另有更冷酷的分类。
- 但在当前 slice，不能因为想提前埋深层真相，就把表层任务语言做得含混。

## Examples / Canonical Scenes

### 正例 1：任务板

- 写法：`进入迷宫，回收书页并带回营地。`
- 玩家一眼能明白：目标、地点、结果。

### 正例 2：撤离反馈

- 写法：`你带回了 3 页书页。`
- 而不是：`You banked 3 loot items.`

### 正例 3：商店提示

- 写法：`用书页换取下一轮更稳妥的工具。`
- 保留“书页是营地经济”的表层逻辑，不急着暴露其深层真相。

## Anti-goals / Failure Modes

- 用“系统更准确”为理由，让玩家主语言继续充满 `loot / quota / item count`。
- 为了保留神秘感，把任务目标写得太抽象，导致新玩家不知道自己到底要拿什么。
- 提前把 Pages 的深层意义明牌说破，削弱后续揭示空间。
- 让不同场景各写各的术语，最后同一件事出现三种叫法。

## Open Questions

- 后续是否要把 `Pages` 统一固定译名为“书页”，还是在部分界面保留 `Pages` 英文并列？
- 商店是否需要一个更强的叙事实体命名，而不只是“商店”功能描述？
- 营地广播 / 任务板 / clue 文本是否需要区分不同说话者语气层级？

## Repo Hooks

- 设计根本：`candidate/deadline-slice.md`
- 执行 companion：`candidate/deadline-sprint.md`
- 当前兼容痕迹：`places/run/src/StarterPlayer/StarterPlayerScripts/RunClient.client.luau`
- 当前兼容字段：`places/run/src/ServerScriptService/Run/RunSnapshotBuilder.luau`
- 深层来源：`candidate/systems/resource-pages-and-economy.md`
