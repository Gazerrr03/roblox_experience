# Contract Vibe

## Human First

### Gameplay Template

- `contract` 不是玩家可见的 place，它是防止 `lobby`、`run`、`maze` 各自发明不兼容含义的 handoff layer。
- 它的职责是给 remotes、session shape、teleport payload、共享 place-routing config 提供稳定的跨 place 语言。
- 如果一个改动让你直觉上觉得“多边都得先达成共识”，那它大概率应该先落这里。

### Mental Model

- contract 线今天落在 `packages/shared` 下，是因为共享 handoff definitions 当前就 source-controlled 在这里。
- 这个 vibe 并不拥有所有 shared helper。它主要拥有的是 cross-place handoff surface，以及锁定这些行为的 deterministic tests。
- `contract` 应保持显式、deterministic、且容易 review diff。

### Key State Flow

1. 某个 place 提出新的 cross-place requirement。
2. `contract` 先更新共享定义。
3. deterministic tests 描述新的 handshake behavior。
4. place-local vibes 再 rebase 到这个基线并改各自 consumer。

## Agent First

### Entry Files

- Session contract entry:
  `packages/shared/src/Session/CampMazeSessionContract.luau`
- Maze availability gate:
  `packages/shared/src/Session/MazeEntryAvailability.luau`
- Shared remotes:
  `packages/shared/src/Network/Remotes.luau`
- Shared routing config:
  `packages/shared/src/Config/SessionConfig.luau`
- Session package entry: `packages/shared/src/Session/init.luau`
- Matching tests:
  `tests/src/Shared/CampMazeSessionContract.spec.luau`,
  `tests/src/Shared/MazeEntryAvailability.spec.luau`,
  `tests/src/Shared/Remotes.spec.luau`

### Allowed Change Graph

Owner zone:

- `packages/shared/src/Session/**`
- `packages/shared/src/Network/**`
- `packages/shared/src/Config/SessionConfig.luau`
- shared contract-related assertions in `tests/src/Shared/**`

Direct dependency zone:

- Place services that consume the contract:
  `places/lobby/src/ServerScriptService/Lobby/LobbyService.luau`
  `places/run/src/ServerScriptService/Run/RunSessionService.luau`
  `places/maze/src/ServerScriptService/Maze/MazeSessionService.luau`

No-touch zone:

- place-local orchestration logic when the issue can be solved by clarifying the
  shared contract alone
- unrelated shared runtime helpers under `packages/shared/src/Runtime/**`
  unless the issue is truly cross-cutting

Boundary interfaces:

- Remotes:
  `LobbyAction`, `LobbyState`, `RunAction`, `RunSnapshot`, `PrivateState`
- Session contract:
  `CampMazeSessionContract`
- Gate policy:
  `MazeEntryAvailability`
- Config:
  `SessionConfig.PlaceIds`, `SessionConfig.DebugLocalMazeHandoff`

### When Contract Should Not Expand

- 不要把只属于某个 place 的 world-building concern 搬进 `contract`。
- 不要让 `contract` 变成只为单个 place 服务的 convenience helper 垃圾场。
- 如果一个 shape 并不会跨 place boundary，也不会被 deterministic tests 锁定，就让它留在拥有它的本地 vibe。

### Validation

- `stylua --check .`
- `selene .`
- `rojo build tests/default.project.json -o .\\tmp\\roblox_experience-tests.rbxlx`
- `run-in-roblox --place .\\tmp\\roblox_experience-tests.rbxlx --script tests/run-in-roblox.lua`

## Notes

- 最干净的 `contract` 改动应该足够小、由行为驱动、并且立刻体现在 deterministic tests 中。
- 如果某个 place 需要新的 seam，优先给出狭窄而显式的 contract，而不是把副作用偷偷塞进某个 service。
