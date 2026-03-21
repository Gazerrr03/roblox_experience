# Run Vibe

## Human First

### Gameplay Template

- `run` 是正式流程 `Lobby -> Run -> Maze -> Run` 的营地与 expedition hub。
- 玩家在这里的主循环是：到达营地、启动 run、探索 outdoor shell、进入 maze、接回返程玩家、结算、重置。
- 这个 place 是当前 vertical slice 的 orchestration center。

### Mental Model

- Server authority 在 `RunSessionService` 及其支撑 builders/services。
- Client presentation 和 input 在 `RunClient.client.luau`。
- `run` 拥有 camp session orchestration、world shell 组装、本地 debug maze fallback、以及面向玩家的 run snapshot。
- `run` 不拥有 maze 侧 expedition logic，也不拥有共享 handoff schema。

### Key State Flow

1. 玩家带着来自 lobby 或 maze 的可选 teleport data 进入。
2. `RunSessionService` 协调 incoming session state。
3. place 启动或恢复 camp session，并广播 snapshots。
4. 玩家通过 run gate 请求进入 maze。
5. run 要么把玩家 teleport 到 maze，要么走本地 debug fallback。
6. 回传 summary 被应用后，run 继续推进到 settlement。

## Agent First

### Entry Files

- Server bootstrap: `places/run/src/ServerScriptService/Bootstrap.server.luau`
- Main service: `places/run/src/ServerScriptService/Run/RunSessionService.luau`
- Supporting builders and services:
  `RunWorldBuilder.luau`, `LocalDebugMazeWorldBuilder.luau`,
  `InventoryService.luau`, `MonsterService.luau`, `RoleService.luau`
- Main client:
  `places/run/src/StarterPlayer/StarterPlayerScripts/RunClient.client.luau`
- Place project file: `places/run/default.project.json`

### Allowed Change Graph

Owner zone:

- `places/run/**`

Direct dependency zone:

- `packages/shared/src/Session/CampMazeSessionContract.luau`
- `packages/shared/src/Session/MazeEntryAvailability.luau`
- `packages/shared/src/Config/SessionConfig.luau`
- `packages/shared/src/Network/Remotes.luau`
- `packages/shared/src/Runtime/**`
- `packages/gameplay/src/**`
- `packages/ui/src/**`

No-touch zone:

- `places/lobby/**` unless the issue is explicitly about the lobby-to-run seam
- `places/maze/**` unless the issue is explicitly about the run-to-maze seam
- shared contract files when changing handoff schema, remote names, or return
  summary meaning

Boundary interfaces:

- Remotes currently used by run clients and maze clients:
  `RunAction`, `RunSnapshot`, `PrivateState`
- Shared handoff:
  `CampMazeSessionContract`,
  `MazeEntryAvailability`,
  `SessionConfig.PlaceIds`,
  `SessionConfig.DebugLocalMazeHandoff`,
  Studio attribute `SessionDebugLocalMazeHandoff`
- Deterministic tests:
  `tests/src/Shared/CampMazeSessionContract.spec.luau`,
  `tests/src/Shared/MazeEntryAvailability.spec.luau`,
  `tests/src/Shared/Remotes.spec.luau`

### When To Start In Contract Instead

- 如果 run 需要新的 teleport payload fields
- 如果 run 和 maze 不该再继续共享当前这组 `RunAction` / `RunSnapshot` /
  `PrivateState` remotes
- 如果 return summary 或 camp-session reconciliation 规则变化
- 如果 place-id 或 debug handoff config 在多 place 之间的含义变化

### Validation

- `stylua --check .`
- `selene .`
- `rojo build places/run/default.project.json -o .\\tmp\\run.rbxlx`
- If shared handoff behavior changed:
  `rojo build tests/default.project.json -o .\\tmp\\roblox_experience-tests.rbxlx`

## Notes

- `run` 最容易不小心长成 god object。优先抽本地模块或 contract-first seam，不要把无关职责继续堆进 `RunSessionService`。
- 本地 debug maze path 是 run 自己的 fallback，不是正式 maze contract。
