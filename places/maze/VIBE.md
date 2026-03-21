# Maze Vibe

## Human First

### Gameplay Template

- `maze` 是正式流程 `Run -> Maze -> Run` 中的 expedition place。
- 玩家在这里的体验是第一人称探索迷宫、收集 loot、承受 extraction 压力、并把结算结果 handoff 回 run。
- 这个 place 应该像一个聚焦的 expedition runtime，而不是第二个 camp。

### Mental Model

- Server authority 在 `MazeSessionService` 和 `MazeWorldBuilder`。
- Client presentation 与 expedition input 在 `MazeClient.client.luau`。
- `maze` 拥有 maze 侧 world setup、expedition progression、loot/extract flow、以及回到 run 的 return trigger。
- `maze` 不拥有 lobby readiness，也不拥有 run 侧 settlement rules。

### Key State Flow

1. 玩家带着来自 run 的 maze teleport data 进入。
2. `MazeSessionService` 合并并验证 incoming camp session。
3. maze world 被构建，expedition snapshots 推送给客户端。
4. 玩家与 maze objective 和 extraction flow 交互。
5. return summary 被构造并通过共享 contract 回传。
6. 玩家被 teleport 回 run，进入 settlement 或 early return 流程。

## Agent First

### Entry Files

- Server bootstrap: `places/maze/src/ServerScriptService/Bootstrap.server.luau`
- Main service: `places/maze/src/ServerScriptService/Maze/MazeSessionService.luau`
- Main world builder:
  `places/maze/src/ServerScriptService/Maze/MazeWorldBuilder.luau`
- Main client:
  `places/maze/src/StarterPlayer/StarterPlayerScripts/MazeClient.client.luau`
- Place project file: `places/maze/default.project.json`

### Allowed Change Graph

Owner zone:

- `places/maze/**`

Direct dependency zone:

- `packages/shared/src/Session/CampMazeSessionContract.luau`
- `packages/shared/src/Network/Remotes.luau`
- `packages/shared/src/Config/SessionConfig.luau`
- `packages/shared/src/Runtime/**`
- `packages/gameplay/src/**`

No-touch zone:

- `places/lobby/**`
- `places/run/**` unless the issue is explicitly about the maze return seam
- shared contract files when changing teleport shape, return summary semantics,
  remote naming, or replicated snapshot meaning

Boundary interfaces:

- Remotes currently reused from the run surface:
  `RunAction`, `RunSnapshot`, `PrivateState`
- Shared handoff:
  `CampMazeSessionContract.buildMazeToCampTeleportData`,
  `CampMazeSessionContract.buildReturnSummary`,
  `CampMazeSessionContract.reconcileIncomingCampSession`
- Shared config:
  `SessionConfig.PlaceIds.Run`,
  `SessionConfig.DebugLocalMazeHandoff`,
  Studio attribute `SessionDebugLocalMazeHandoff`
- Deterministic tests:
  `tests/src/Shared/CampMazeSessionContract.spec.luau`,
  `tests/src/Shared/Remotes.spec.luau`,
  `tests/src/Shared/MazeModuleAssetContract.spec.luau`

### When To Start In Contract Instead

- 如果 maze 需要新的 return summary data
- 如果 maze 不应继续通过当前 run-flavored remote surface 说话
- 如果 maze-to-run teleport payload 或 reconciliation 规则变化
- 如果 snapshot fields 变成 maze 代码域以外也要依赖的共享约定

### Validation

- `stylua --check .`
- `selene .`
- `rojo build places/maze/default.project.json -o .\\tmp\\maze.rbxlx`
- If shared handoff behavior changed:
  `rojo build tests/default.project.json -o .\\tmp\\roblox_experience-tests.rbxlx`

## Notes

- 尽量把 maze-specific behavior 关在 maze 自己的模块内。
- 如果一次改动让 maze client 或 service 越来越像 run 的 clone，说明 seam 很可能放错了，应该先往 `contract` 方向移动。
