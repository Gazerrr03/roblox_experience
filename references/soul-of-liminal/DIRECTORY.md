# Soul of Liminal Directory

给同事看的快速路由文档。

第一次进入 `Soul of Liminal`，请按下面顺序读：

1. `candidate/deadline-slice.md`
2. `candidate/deadline-sprint.md`
3. `DESIGN-MAP.md`
4. `IMPLEMENTATION-BACKLOG.md`
5. 再按角色进入对应 formal 文档

## Root

- `README.md`
  - 总入口；讲清当前文档体系怎么使用。
- `DESIGN-MAP.md`
  - 文档地图；说明九板块关系、旧文档定位、推荐阅读路径。
- `IMPLEMENTATION-BACKLOG.md`
  - 落地清单；说明内容、代码、验证下一步先做什么。
- `DIRECTORY.md`
  - 当前这份快速目录。

## Formal — 当前确认版

- `formal/terminology-and-player-facing-language.md`
  - 锁定玩家表层语言与禁用词边界。
- `formal/understanding-standards.md`
  - 锁定设计评判标准与 playtest 复盘口径。
- `formal/first-30-minutes-slice-blueprint.md`
  - 锁定首局前 30 分钟体验链。
- `formal/clue-authoring-standard.md`
  - 锁定 clue 的生产规则与 payoff 要求。
- `formal/maze-encounter-grammar.md`
  - 锁定 Maze 节点语法与组合节奏。
- `formal/threat-design-bible.md`
  - 锁定 headline threat 的规则、公平边界与反馈闭环。
- `formal/round-pacing-and-economy.md`
  - 锁定 5 回合节奏、Pages 经济和死亡/撤离价值结构。

适合谁先读：
- 新策划 / 内容设计 / 关卡设计 / 系统设计
- 需要把讨论转成明确任务的人
- 需要统一语言与判断标准的人

## Candidate — 根本、来源、未来方向

### 当前仍然优先级最高的两篇

- `candidate/deadline-slice.md`
  - 当前 slice 的根本 framing。
- `candidate/deadline-sprint.md`
  - 当前 slice 的 execution companion。

### 当前新增的未来方向

- `candidate/crew-dynamics-and-information-asymmetry.md`
  - 角色分工、私有信息、未来误导层。
- `candidate/reveal-ladder.md`
  - 身份真相、Pages 真相、上位系统揭示节奏。

### 旧的来源 / 样例文档

- `candidate/game-pillars.md`
- `candidate/project-philosophy.md`
- `candidate/core-loop-and-motivation.md`
- `candidate/systems/first-round-experience-chain.md`
- `candidate/systems/first-run-clue-archetype.md`
- `candidate/clues/CL-0001-first-corpse-clue.md`
- `candidate/systems/maze-rule-pillars.md`
- `candidate/systems/primary-threat-audio-predator.md`
- `candidate/systems/resource-pages-and-economy.md`
- `candidate/systems/run-clue-and-deception.md`
- `candidate/cards/*`

## Situation

- `situation/current-situation.md`
  - 当前项目现状快照。

## Checkpoints

- `checkpoints/README.md`
  - checkpoint 机制说明。
- `checkpoints/CP-0001-open.md`
  - 当前开放区间；作为后续回收输入，不是结论文档。

## Quick Route By Role

- 策划 / 设计
  - `candidate/deadline-slice.md` -> `DESIGN-MAP.md` -> `formal/terminology-and-player-facing-language.md` -> `formal/understanding-standards.md`
- 内容设计
  - `formal/first-30-minutes-slice-blueprint.md` -> `formal/clue-authoring-standard.md` -> `IMPLEMENTATION-BACKLOG.md`
- 关卡 / 场景设计
  - `formal/maze-encounter-grammar.md` -> `formal/threat-design-bible.md` -> `IMPLEMENTATION-BACKLOG.md`
- 系统 / 技术设计
  - `candidate/deadline-sprint.md` -> `formal/round-pacing-and-economy.md` -> `IMPLEMENTATION-BACKLOG.md`
- 只想知道这一轮做什么
  - `candidate/deadline-slice.md` + `candidate/deadline-sprint.md` + `IMPLEMENTATION-BACKLOG.md`
