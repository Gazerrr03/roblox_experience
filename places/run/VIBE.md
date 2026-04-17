# Run Vibe

## Human First

### Gameplay Template

- `run` is the camp and expedition hub of the published flow
  `Run (entry) -> Maze -> Run`.
- The player loop here is: arrive at camp, start the run, explore the outdoor
  shell, enter maze, receive returning players, settle, and reset.
- This place is the orchestration center of the current vertical slice.

### Mental Model

- Server authority lives in `RunSessionService` and its supporting
  builders/services.
- Client presentation and input live in `RunClient.client.luau`.
- `run` owns camp session orchestration, authored world assembly, the
  player-facing run snapshot, and the run-to-maze transition handoff.
- `run` does not own maze-side expedition logic or the shared handoff schema.

### Key State Flow

1. Players arrive with optional teleport data from maze.
2. `RunSessionService` reconciles the incoming session state.
3. The place starts or resumes the camp session and broadcasts snapshots.
4. Players request maze entry through the run gate.
5. Run teleports players to maze through the dedicated run-to-maze transition.
6. Returned summaries are applied and run progresses toward settlement.

## Agent First

### Entry Files

- Server bootstrap: `places/run/src/ServerScriptService/Bootstrap.server.luau`
- Main service: `places/run/src/ServerScriptService/Run/RunSessionService.luau`
- Supporting builders and services:
  `RunWorldBuilder.luau`, `RunScene.luau`, `RunToMazeTransition.luau`,
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

- `places/lobby/**` — lobby has been removed; if re-adding a lobby layer is needed, start with `packages/shared/VIBE.md`
- `places/maze/**` unless the issue is explicitly about the run-to-maze seam
- shared contract files when changing handoff schema, remote names, or return
  summary meaning

Boundary interfaces:

- Remotes currently used by run clients and maze clients:
  `RunAction`, `RunSnapshot`, `PrivateState`
- Shared handoff:
  `CampMazeSessionContract`,
  `MazeEntryAvailability`,
  `SessionConfig.PlaceIds`
- Deterministic tests:
  `tests/src/Shared/CampMazeSessionContract.spec.luau`,
  `tests/src/Shared/MazeEntryAvailability.spec.luau`,
  `tests/src/Shared/Remotes.spec.luau`

### When To Start In Contract Instead

- If run needs new teleport payload fields
- If run and maze should stop sharing the current
  `RunAction` / `RunSnapshot` / `PrivateState` remotes
- If return summaries or camp-session reconciliation rules change
- If the meaning of place-id availability changes across places

### Validation

- `stylua --check .`
- `selene .`
- `rojo build places/run/default.project.json -o .\\tmp\\run.rbxlx`
- If shared handoff behavior changed:
  `rojo build tests/default.project.json -o .\\tmp\\roblox_experience-tests.rbxlx`

## Notes

- `run` is the easiest place to accidentally turn into a god object. Prefer
  extracting local modules or contract-first seams over piling unrelated duties
  into `RunSessionService`.
- `RunStaticWorld` is the formal runtime source for camp and wilderness content.
