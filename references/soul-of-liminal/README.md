# Soul of Liminal

`Soul of Liminal` 是 `Liminal` 的长期设计文档中心。

当前这套未提交文档的核心原则很简单：

- `candidate/deadline-slice.md` 是当前 deadline slice 的根本
- `candidate/deadline-sprint.md` 是当前 slice 的执行 companion
- 本轮新增 `formal/*` 负责把 slice 精神翻译成当前确认版规则
- 旧 `candidate/*` 默认作为来源、样例和未来方向保留

## 先读什么

推荐顺序：

1. `candidate/deadline-slice.md`
2. `candidate/deadline-sprint.md`
3. `DESIGN-MAP.md`
4. `IMPLEMENTATION-BACKLOG.md`
5. `formal/terminology-and-player-facing-language.md`
6. `formal/understanding-standards.md`
7. `formal/first-30-minutes-slice-blueprint.md`

如果你只想知道“当前 slice 是什么”，读到第 3 篇就够了。
如果你要继续往内容和实现上落，就继续读 backlog 和 formal。

## 当前结构

- `DESIGN-MAP.md`
  - 文档地图：讲清楚哪些是当前硬约束、哪些是来源碎片、哪些是未来方向。
- `IMPLEMENTATION-BACKLOG.md`
  - 落地地图：把 formal / candidate 反向映射成下一批内容、代码与验证任务。
- `formal/`
  - 当前确认版；用于约束当前 slice 的设计、内容生产、调参与复盘。
- `candidate/`
  - 根本 framing、来源文档、样例与未来增强方向。
- `situation/`
  - 当前项目现状快照。
- `checkpoints/`
  - 对话区间与后续回收输入。

## 当前方向

当前 `Liminal` 的 slice 仍然围绕以下主轴：

- `Run -> Maze -> Run` mission loop
- `Run` 是认知层与任务 framing 层
- `Maze` 是 lethal rule-execution layer
- 玩家表层目标是回收书页 / Pages
- 真正成长首先来自知识和判断
- 社交误导与身份真相仍是未来增强，不压过当前基础 loop

## 使用规则

- 要统一玩家语言，先看 `formal/terminology-and-player-facing-language.md`
- 要判断一条内容或规则成不成立，先看 `formal/understanding-standards.md`
- 要设计首局体验，先看 `formal/first-30-minutes-slice-blueprint.md`
- 要把文档转成任务，先看 `IMPLEMENTATION-BACKLOG.md`
- 要回收旧讨论，先通过 `DESIGN-MAP.md` 找它现在对应到哪个 formal 或 candidate 文档
