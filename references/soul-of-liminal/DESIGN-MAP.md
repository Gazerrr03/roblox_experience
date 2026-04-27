# Soul of Liminal Design Map

## Purpose

这份文档负责回答一件事：
当前 `Soul of Liminal` 里，哪几篇是当前硬约束，哪几篇是来源材料，哪几篇是未来方向。

它不替代 `candidate/deadline-slice.md` 或 `candidate/deadline-sprint.md`。
它只是把这批未提交文档整理成一个清楚的使用地图。

## Current Decision

当前文档优先级顺序固定如下：

1. `candidate/deadline-slice.md`
2. `candidate/deadline-sprint.md`
3. 本轮新增 `formal/*`
4. 旧 `candidate/*`
5. `checkpoints/*`

也就是说：
- `deadline-slice.md` 仍然是根本 framing
- `deadline-sprint.md` 仍然是 execution companion
- formal 负责把 slice 变成当前确认版规则
- 旧 candidate 默认作为来源、样例和未来方向保留

## Slice Rule

### 当前九个板块

#### Formal：当前确认版

- `formal/terminology-and-player-facing-language.md`
- `formal/understanding-standards.md`
- `formal/first-30-minutes-slice-blueprint.md`
- `formal/clue-authoring-standard.md`
- `formal/maze-encounter-grammar.md`
- `formal/threat-design-bible.md`
- `formal/round-pacing-and-economy.md`

#### Candidate：未来增强方向

- `candidate/crew-dynamics-and-information-asymmetry.md`
- `candidate/reveal-ladder.md`

### 推荐阅读路径

- 新策划 / 新设计同学
  - `candidate/deadline-slice.md` -> `formal/terminology-and-player-facing-language.md` -> `formal/understanding-standards.md` -> `formal/first-30-minutes-slice-blueprint.md`
- 内容设计
  - `candidate/deadline-slice.md` -> `formal/first-30-minutes-slice-blueprint.md` -> `formal/clue-authoring-standard.md` -> `formal/threat-design-bible.md`
- 关卡 / 场景设计
  - `candidate/deadline-slice.md` -> `formal/maze-encounter-grammar.md` -> `formal/threat-design-bible.md`
- 系统 / 技术设计
  - `candidate/deadline-sprint.md` -> `formal/round-pacing-and-economy.md` -> `formal/understanding-standards.md`

### 写作依赖

- Phase 0：`DESIGN-MAP.md`、`README.md`、`DIRECTORY.md`
- Phase 1：语言、判断标准、首 30 分钟体验
- Phase 2：clue、Maze grammar、threat
- Phase 3：循环节奏、crew dynamics、reveal ladder

## Long-term Direction

- 未来如果 slice 改向，先改 `candidate/deadline-slice.md`，再回收 formal。
- 未来如果 formal 继续膨胀，应该继续拆成更清晰的职能文档，而不是再堆新的总纲。
- 未来 checkpoint 累积的新碎片，优先回收到 formal 或 candidate，而不是直接再长出平行文档。

## Examples / Canonical Scenes

### 正例 1：要改玩家任务文案时

- 先看 `candidate/deadline-slice.md`
- 再看 `formal/terminology-and-player-facing-language.md`
- 不直接翻旧 systems 文档找术语

### 正例 2：要设计一条新 corpse clue 时

- 先看 `formal/first-30-minutes-slice-blueprint.md`
- 再看 `formal/clue-authoring-standard.md`
- 最后把 `candidate/clues/CL-0001-first-corpse-clue.md` 当 canonical example

### 正例 3：要决定未来是否上 traitor 时

- 先看 `candidate/crew-dynamics-and-information-asymmetry.md`
- 确认它不会压过当前 slice 根本

## Anti-goals / Failure Modes

- 继续把旧 candidate 文档当成同级总纲并行引用。
- 不先看 `deadline-slice.md`，直接从局部系统文档开始做决定。
- 讨论已经进入 formal 范围，却还把关键信息留在 checkpoint 或零散样例文档里。
- 每次出现新方向都新建总纲，导致文档层级再次失控。

## Open Questions

- 未来是否需要再加一层只面向实现团队的 docs index？
- 当 backlog 持续扩大时，是否要把 `IMPLEMENTATION-BACKLOG.md` 拆成内容 / 系统 / 验证三份？
- 未来更稳定的 worldview 是否应该从 `candidate/reveal-ladder.md` 上收进 `formal/product-worldview.md`？

## Repo Hooks

- 根本 framing：`candidate/deadline-slice.md`
- 执行 companion：`candidate/deadline-sprint.md`
- 落地清单：`IMPLEMENTATION-BACKLOG.md`
- 现状快照：`situation/current-situation.md`

## 旧文档到新文档的映射

| 旧文档 | 当前角色 | 主要流向 |
| --- | --- | --- |
| `candidate/deadline-slice.md` | slice 根本 framing | 约束全部新增文档 |
| `candidate/deadline-sprint.md` | execution companion | 约束 formal 的 slice rule |
| `candidate/game-pillars.md` | 价值主轴来源 | `formal/understanding-standards.md`, `formal/round-pacing-and-economy.md` |
| `candidate/project-philosophy.md` | 世界观与反目标来源 | `candidate/reveal-ladder.md`, `formal/terminology-and-player-facing-language.md` |
| `candidate/systems/first-round-experience-chain.md` | 首局链路来源 | `formal/first-30-minutes-slice-blueprint.md` |
| `candidate/systems/first-run-clue-archetype.md` | clue archetype 来源 | `formal/clue-authoring-standard.md` |
| `candidate/clues/CL-0001-first-corpse-clue.md` | canonical clue example | `formal/clue-authoring-standard.md` |
| `candidate/systems/maze-rule-pillars.md` | Maze 规则来源 | `formal/maze-encounter-grammar.md`, `formal/threat-design-bible.md` |
| `candidate/systems/primary-threat-audio-predator.md` | headline threat 来源 | `formal/threat-design-bible.md` |
| `candidate/systems/resource-pages-and-economy.md` | Pages 深层含义来源 | `formal/round-pacing-and-economy.md`, `candidate/reveal-ladder.md` |
| `candidate/systems/run-clue-and-deception.md` | clue 与社交层来源 | `formal/clue-authoring-standard.md`, `candidate/crew-dynamics-and-information-asymmetry.md` |
