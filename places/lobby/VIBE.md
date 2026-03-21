# Lobby Vibe

## Human First

### Gameplay Template

- `lobby` is the crew assembly and launch space for the published flow
  `Lobby -> Run`.
- The player experience here should stay simple: join the roster, toggle ready,
  confirm the crew is prepared, and enter a private `Run` server together.
- This place should feel like a thin staging room, not a pre-copy of `run`.

### Mental Model

- Server authority lives in `LobbyService`.
- Client presentation lives in `LobbyClient.client.luau`.
- `lobby` owns ready state, roster visibility, and the initial teleport trigger.
- `lobby` does not own run gameplay, maze gameplay, or the shared handoff
  schema.

### Key State Flow

1. Players enter the roster.
2. Players toggle ready through `LobbyAction`.
3. `LobbyService` builds a snapshot and broadcasts `LobbyState`.
4. Once the crew is valid, `LobbyService` reserves a private `Run` server.
5. Teleport data is built through `CampMazeSessionContract` and sent to run.

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

- If the `lobby -> run` teleport payload shape changes
- If the name, meaning, or purpose of `LobbyAction` or `LobbyState` changes
- If run needs new handoff data that does not already exist in the shared
  contract

### Validation

- `stylua --check .`
- `selene .`
- `rojo build places/lobby/default.project.json -o .\\tmp\\lobby.rbxlx`

## Notes

- Keep bootstrap thin. New rules should live in `LobbyService` or a supporting
  module.
- If lobby needs richer runtime state, avoid inventing ad-hoc replicated state.
  If other places or tests will rely on it, define the shared shape first.
