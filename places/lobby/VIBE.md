# Lobby Vibe

## Human First

### Gameplay Template

- `lobby` 是正式流程 `Lobby -> Run` 的组队和出发空间。
- 玩家在这里的体验应该非常直接：进入队伍、切换 ready、确认全员准备完毕、一起进入私有 `Run` server。
- 这个 place 应该像一个轻量出发房间，而不是 `run` 的前置复制品。

### Mental Model

- Server authority 在 `LobbyService`。
- Client presentation 在 `LobbyClient.client.luau`。
- `lobby` 拥有 ready 状态、队伍可见性、以及第一次 teleport 触发。
- `lobby` 不拥有 run 玩法、maze 玩法、也不拥有共享 handoff schema。

### Key State Flow

1. 玩家进入队伍。
2. 玩家通过 `LobbyAction` 切换 ready。
3. `LobbyService` 组装 snapshot 并广播 `LobbyState`。
4. 当队伍满足条件后，`LobbyService` 预留私有 `Run` server。
5. teleport data 通过 `CampMazeSessionContract` 构造并发送到 run。

## Agent First

### Entry Files

- Server bootstrap: `places/lobby/src/ServerScriptService/Bootstrap.server.luau`
- Main service: `places/lobby/src/ServerScriptService/Lobby/LobbyService.luau`
- Main client:
  `places/lobby/src/StarterPlayer/StarterPlayerScripts/LobbyClient.client.luau`
- Place project file: `places/lobby/default.project.json`

### Allowed Change Graph

Owner zone:

- `places/lobby/**`

Direct dependency zone:

- `packages/shared/src/Config/SessionConfig.luau`
- `packages/shared/src/Network/Remotes.luau`
- `packages/shared/src/Session/CampMazeSessionContract.luau`
- `packages/shared/src/Util/TeleportDiagnostics.luau`

No-touch zone:

- `places/run/**` unless the issue is explicitly about the lobby-to-run adapter
- `places/maze/**`
- shared contract modules when the payload or remote shape itself changes

Boundary interfaces:

- Remotes: `LobbyAction`, `LobbyState`
- Shared handoff: `CampMazeSessionContract.buildLobbyToCampTeleportData`
- Shared config: `SessionConfig.PlaceIds.Run`, team size defaults
- Deterministic tests:
  `tests/src/Shared/CampMazeSessionContract.spec.luau`,
  `tests/src/Shared/Remotes.spec.luau`

### When To Start In Contract Instead

- 如果 `lobby -> run` 的 teleport payload shape 要变
- 如果 `LobbyAction` 或 `LobbyState` 的名称、语义、用途要变
- 如果 run 需要消费新的 handoff data，而这些数据还不在共享 contract 中

### Validation

- `stylua --check .`
- `selene .`
- `rojo build places/lobby/default.project.json -o .\\tmp\\lobby.rbxlx`

## Notes

- 保持 bootstrap 足够薄。新增规则应进入 `LobbyService` 或其支撑模块。
- 如果 lobby 需要更复杂的 runtime state，不要先发明 ad-hoc replicated state。
  一旦其他 place 或 tests 也要依赖，就应先定义共享 shape。
