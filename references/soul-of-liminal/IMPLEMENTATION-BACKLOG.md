# Soul of Liminal Implementation Backlog

## Purpose

这份 backlog 把当前 `deadline-slice`、新增 formal 文档和保留的 candidate 方向，反向映射成下一批最值得落地的任务。

它回答的是：
- 内容先做什么
- 代码先改什么
- 哪些只是支撑，不要抢主线
- 每批任务完成后应该验证什么

## Current Decision

当前落地顺序固定为：

1. 先统一玩家语言和任务 framing
2. 再做首局 clue 教学与 Maze payoff 闭环
3. 再做 headline threat 的可读追逐与风险收益节奏
4. 最后才碰更远的社交层和真相揭示增强

换句话说：
- 先把单层 loop 做硬
- 再谈未来辨识度增强

## Slice Rule

### Batch 1 — 统一表层语言与任务 framing

#### 内容任务

- 把营地任务板、提示语、撤离反馈统一成“书页 / Pages”语言
- 清理当前面向玩家的 `loot / quota / generic resource` 说法
- 给营地 / 船 / 商店 / 任务系统写出一套一致口吻

#### 代码与实现钩子

- 检查 `places/run/src/StarterPlayer/StarterPlayerScripts/RunClient.client.luau` 的玩家可见词汇
- 检查 `places/run/src/ServerScriptService/Run/RunSnapshotBuilder.luau` 与相关 UI 数据映射
- 只在不破坏兼容层的前提下替换玩家外显文案，不急着先重命名内部字段

#### 完成定义

- 新玩家不再在主界面同时看到 `Pages` 和 `loot item count` 作为同一目标的两套说法
- 团队能用一句话准确说出当前任务：进入迷宫、回收书页、活着带回营地

### Batch 2 — 首局 clue 教学闭环

#### 内容任务

- 固化第一条 corpse clue 作为首局 canonical teaching clue
- 再补 1 条次级 clue，服务同一条威胁语言，但不抢主 clue 的位置
- 为每条 clue 补齐：教什么、不教什么、payoff 在哪、玩家看完后最可能改什么行为

#### 代码与实现钩子

- 继续用 `RunClueMarker` 现有结构承载第一批 clue
- 不新造 clue 系统，先复用 `ReadableTitle` / `ReadableText` / `ThreatHintId`
- 若需要补字段，优先只加能服务 payoff 绑定和内容维护的最小字段

#### 完成定义

- 首局玩家较高概率能碰到至少一条 teachable clue
- 复盘时玩家能说出“因为前面看到/听到 X，所以后面没有继续做 Y”

### Batch 3 — Maze encounter grammar 落地

#### 内容任务

- 用当前 authored Maze 明确标出：入口缓冲、威胁预告、资源诱惑、追击触发、呼吸点、撤离抉择这些节点的至少一个实例
- 调整房间职责，让首局不再只是“走路 -> 捡东西 -> 被追”
- 把资源点与高压点的组合改成可复盘的风险诱惑，而不是纯随机堆叠

#### 代码与实现钩子

- 优先复用当前 `MazeWorldBuilder` / `MazeScene` / `MazeWorldScanner` 的 authored-world 流程
- 如果要新增标记或节点属性，优先放在 Maze authored contract 里，不在 session service 写死特殊逻辑

#### 完成定义

- 关卡设计能指出每个关键节点的体验职责
- 玩家首局能明显感受到节奏层次，而不是一直处于单一压力状态

### Batch 4 — Headline threat 可读化

#### 内容任务

- 让声音驱动 predator 的 warning、逼近、追逐、失手四段都更可读
- 保证第一次高压接触前至少有一个 warning read
- 补一到两个“玩家因为克制而多活一会儿”的读得出来的时刻

#### 代码与实现钩子

- 继续使用现有 `MonsterService` 和 monster config 路径
- 优先做“声音反应更清楚”的薄扩展，而不是重写 monster 平台
- 若需要更强内容控制，优先补事件、状态或调参接口，不做通用 AI 大改

#### 完成定义

- 玩家死后能说出自己下次应该少做什么
- 玩家不会主要把失败归因到脚本杀或黑箱锁定

### Batch 5 — 5 回合节奏与工具职责对齐

#### 内容任务

- 明确每回合的心理功能：第 1 回合学规则，第 2-3 回合试探收益，第 4-5 回合升压收束
- 把工具定位成“提高可读性与执行稳定性”，而不是成长主轴
- 调整撤离反馈与死亡痛感，让“带回几页也值”成立

#### 代码与实现钩子

- 以 `SessionConfig`、玩家脆弱性参数、工具配置为主调节点
- 不急着做完整经济系统重构，先把当前 5 回合体验做出差异
- 保持 Pages 作为表层目标语言，深层意义仍只做暗示

#### 完成定义

- 不同回合的心理结构开始分化
- 玩家会讨论“要不要现在撤”而不是总是只存在一种最优解
- 工具不会被理解成“刷到强装备就能无脑过”的通道

### Batch 6 — 暂缓但保持接口意识的方向

#### 当前只记录，不作为近期依赖

- 角色分工、私有信息、误导层
- traitor 或系统化欺骗玩法
- 身份真相和 Pages 真相的强揭示
- 麦克风风险或多 threat ecology

#### 要求

- 新任务不能把这些方向悄悄变成当前 slice 的硬依赖
- 如果实现层需要为未来留口子，也要先证明不会影响当前单层 loop 的清晰度

## Long-term Direction

- 当 Batch 1-5 稳定后，可以再把 `crew-dynamics-and-information-asymmetry.md` 与 `reveal-ladder.md` 逐步转化成新的内容/系统 backlog
- 到那时，社交层和真相层应该是“建立在现有 loop 已成立之上的增强”，而不是补救当前基础不清的问题

## Examples / Canonical Scenes

### 正例 1：先改玩家词，再改怪逻辑

- 因为如果目标语言还在摇摆，后面所有内容与节奏讨论都会继续跑偏

### 正例 2：先固化一主一辅 clue，再扩更多 clue

- 因为当前 slice 需要先证明 clue 真能改变行为，而不是先做 clue 数量

### 正例 3：先做薄扩展 threat 可读性，而不是重写 monster 平台

- 因为当前 deadline slice 要证明的是体验成立，不是架构优雅

## Anti-goals / Failure Modes

- 一上来就做大规模共享契约重命名、系统重构或 monster 平台重写
- clue 还没稳定，先把误导层和 traitor 做成近期重点
- 还没统一玩家语言，就直接调经济和任务节奏
- Maze 节点职责还没做清楚，就急着扩更多房间和更多 threat

## Open Questions

- Batch 1 是否需要先做一次“所有玩家可见文案盘点表”？
- Batch 3 是否需要一份 Maze 节点标注清单，直接对照当前 authored world 来审查？
- Batch 5 是否需要先给 5 回合写一个非常粗粒度的目标曲线，再落到参数？

## Repo Hooks

- 根本 framing：`candidate/deadline-slice.md`
- 执行 companion：`candidate/deadline-sprint.md`
- 文档地图：`DESIGN-MAP.md`
- 玩家语言：`formal/terminology-and-player-facing-language.md`
- 判断标准：`formal/understanding-standards.md`
- clue 标准：`formal/clue-authoring-standard.md`
- Maze grammar：`formal/maze-encounter-grammar.md`
- threat 规范：`formal/threat-design-bible.md`
- 节奏与经济：`formal/round-pacing-and-economy.md`
