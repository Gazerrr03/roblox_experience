# Multi-Place Vibe Framework

这个仓库把多 place 长期开发线视为代码域 `vibe`。目标不是再写一份大而全的总文档，而是让人类和 AI 进入某个代码域后，能立刻读懂：

- 这个单元负责什么
- 从哪里进
- 允许改哪里
- 什么时候必须先改 `contract`
- 改完怎么验证

当前的一等 `vibe` 有四条：

- `lobby`
- `run`
- `maze`
- `contract`

当前代码域锚点如下：

- `lobby` -> `places/lobby/**`
- `run` -> `places/run/**`
- `maze` -> `places/maze/**`
- `contract` ->
  `packages/shared/src/Session/**`,
  `packages/shared/src/Network/**`,
  `packages/shared/src/Config/SessionConfig.luau`,
  以及 `tests/src/Shared/**` 中对应的 deterministic 覆盖

## Progressive Disclosure

每个 `vibe` 都分成两层：

1. `VIBE.md`
   稳定层 handbook。优先记录职责、心智模型、入口、允许改动图谱、验证方式。
2. `NOW.md`
   活页层。只记录当前压力点、临时例外、近期待收敛问题，不把这些短期信息塞进稳定层。

可以存在 agent 适配层：

- `AGENTS.md`
- `CLAUDE.md`

这些文件必须保持很薄，只负责引导 agent 回到 `VIBE.md` 和 `NOW.md`，不能自己变成第二套事实来源。

## Code Domain Before Branch

代码域优先，分支和 worktree 次之。

- 分支、worktree、issue、PR 都只是围绕代码域工作的协作载体，不是 `vibe` 本体。
- 一个 issue 或 PR 首先属于“拥有这段代码的代码域”。
- 如果任务同时跨 `contract` 和某个 place，需要先把 handoff 讲清楚，再决定是否按 `contract first` 分阶段落地。

推荐的 worktree 形态：

```bash
git worktree add -b lobby ../roblox_experience-lobby origin/lobby
git worktree add -b run ../roblox_experience-run origin/run
git worktree add -b maze ../roblox_experience-maze origin/maze
git worktree add -b contract ../roblox_experience-contract origin/contract
```

当你希望某一条长期线拥有更干净的本地上下文、更小的 review 面时，用专门 worktree。

## 什么时候必须 Contract First

以下变更默认先在 `contract` 落地，再让各 place 跟进：

- teleport payload shape 变化
- `CampMazeSessionContract` state shape 或 reconciliation 规则变化
- shared remote 名称或语义变化
- `SessionConfig` 中跨 place handoff 相关字段变化
- deterministic test 中定义的共享行为变化

`contract` 落地后，再让 place 分支 rebase 或 merge 到新基线，保持 place PR 聚焦于各自 adapter 或 consumer。

## Allowed Change Graph

每个 `VIBE.md` 都必须显式写出四件事：

1. Owner zone
   这个 vibe 可以直接改的目录和入口。
2. Direct dependency zone
   这个 vibe 常依赖的共享模块。可以影响，但不应随手改。
3. No-touch zone
   非跨域 issue 时，不该从这里直接碰的相邻 place 或 package。
4. Boundary interfaces
   允许跨域时必须经过的 contract module、remote、config、test fixture。

## Required Local Files

每个一等 `vibe` 都需要把这些文件放在所拥有代码附近：

- `VIBE.md`
- `NOW.md`
- `AGENTS.md`
- `CLAUDE.md`

`VIBE.md` 的首屏必须同时兼顾两类读者：

- 对人类：玩法模板、心智模型、关键状态流
- 对 AI：入口文件、允许改动图谱、验证方式、跨域规则

## New Place Onboarding

新增 place 时，不要等代码变乱了再补规则。新 place 从第一天就要被建成新的 `vibe`。

最低要求：

1. 创建 `places/<new-place>/VIBE.md`
2. 创建 `places/<new-place>/NOW.md`
3. 创建 `places/<new-place>/AGENTS.md`
4. 创建 `places/<new-place>/CLAUDE.md`
5. 同步更新相关 `default.project.json`
6. 写清楚 allowed change graph 和 contract interface
7. 如果改到 shared behavior，同步补 deterministic tests

模板入口：`references/templates/place-vibe/`

## Review And Merge Flow

当一个 feature 横跨多条开发线时，默认顺序是：

1. 如果 handoff 变化，先落 `contract`
2. 受影响的 place rebase 到这个基线
3. place-local adapter / orchestration 分开提 PR
4. PR 描述显式说明这次变更归属哪个 `vibe`

如果一个任务完全可以在单一 `vibe` 内解决，就不要为了“看起来解耦”而强行拆成跨线 choreography。这个框架的目标是降低隐藏耦合，不是制造流程负担。
