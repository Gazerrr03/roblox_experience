# Formal Clue Authoring Standard

## Purpose

这篇文档定义当前 slice 中 clue 应该如何被生产、摆放、书写、阅读和 payoff。
它不是讲“clue 很重要”，而是讲“什么样的 clue 才算对”。

主要读者：内容设计、叙事设计、关卡设计、实现 clue marker 的人。

## Current Decision

当前 slice 的 clue 首先服务于三件事：

1. 让 `Run` 真正成为认知层，而不是前厅
2. 让玩家在进入 Maze 前形成可带进去的怀疑或判断
3. 让 Maze 的威胁或节点在之后完成 payoff

前期 clue 以**基本真实**为主。
它可以不完整、不直说、带情绪偏差，但不能让玩家觉得“信息系统本身不可信”。

## Slice Rule

### clue 的最小结构

每条 clue 至少要明确回答：

- 它教什么
- 它不教什么
- 玩家在看完后最可能改变哪一个行为
- 它在 Maze 里由哪个场景或威胁完成 payoff

### 当前允许的 clue 类型

- 怪物行为 clue
- 环境或机制 clue
- 世界与任务 clue
- 资源或 stash 指向 clue

当前 slice 的优先级顺序：
1. 怪物行为 clue
2. 环境 / 机制 clue
3. 任务与世界 clue
4. stash / 资源 clue

### 可信度层级

当前 slice 只正式使用三层：

- `Teaching True`
  - 当前最优先；用于首局、强 teaching、第一批关键 clue
- `Partial True`
  - 内容真实但不完整，允许误解空间
- `Emotionally Distorted`
  - 叙述者惊慌、偏执、片面，但底层规则不能彻底反着来

当前 slice 不主推：
- 完全错误 clue
- 依赖 traitor 才成立的 clue
- 主要作用是误导队友的 clue

### 摆放原则

- 强 teaching clue 优先放在主路侧边一步可到的位置
- 不直接贴脸，不抢走玩家主动性
- 不应被摆到“如果没碰到就彻底失去首局可读性”的程度
- 每条强 clue 都要能在空间上说明“这里为什么会留下这种痕迹”

### 文本与场景关系

clue 不是纯文本条目。
当前 slice 的 clue 必须至少满足以下组合之一：

- 文本 + 尸体 / 装备残留
- 文本 + 环境痕迹
- 音频 + 物理现场
- 交互点 + 后续空间对照

### payoff 绑定

每条强 clue 都必须绑定一个后续 payoff，至少写清：

- `Payoff Target`
- `Expected Player Re-read`
- `Failure Without Clue`

## Long-term Direction

- 长期可以加入真伪混杂、社交误读、角色私有 clue、口头传播失真。
- 长期可以让 clue 不只教 threat，也教路线、资源和更高层的世界真相。
- 但当前 slice 不能让 clue 先变成谜语游戏，必须先成为可靠的认知收益。

## Examples / Canonical Scenes

### 正例 1：尸体 + 录音 + 声音怀疑

- 玩家看到“和自己相似的旧执行体尸体”
- 听到惊慌、金属声、脚步、突然中断的录音
- 玩家形成：`这东西可能不是看见我才追来的`

### 正例 2：门口刮痕 + 锁链残留 + 简短记录

- 不直接写“开门会制造巨大噪音”
- 但让玩家在之后更谨慎对待门和通路

### 正例 3：任务层 clue

- 一份残缺指令或回收记录，强化“你在做被指派的工作”，而不是自由探索

## Anti-goals / Failure Modes

- clue 只负责“增加气氛”，却不改变行为。
- clue 直接把答案说透，像系统弹窗教程。
- clue 太隐，导致当前 slice 的学习价值完全落空。
- clue 和现场没有关系，像把 lore 文本随便贴在路边。
- 让前期 clue 太早进入真假混杂，玩家开始怀疑系统而不是怀疑世界。

## Open Questions

- 是否需要给 clue 增加“发现成本等级”，方便后续内容排布？
- 音频 clue 是否要区分“强 teaching 音频”和“纯氛围音频”？
- 后续若加入私有信息层，哪些 clue 仍然必须保持全队都可能接触到？

## Repo Hooks

- 首局蓝图：`formal/first-30-minutes-slice-blueprint.md`
- 旧方向来源：`candidate/systems/first-run-clue-archetype.md`
- clue 样例：`candidate/clues/CL-0001-first-corpse-clue.md`
- 社交层来源：`candidate/systems/run-clue-and-deception.md`
- 当前实现入口：`places/run/src/ServerScriptService/Run/RunClueMarker.luau`
