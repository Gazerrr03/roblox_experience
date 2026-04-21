# Run Vibe

## Human First

### Gameplay Template

- `run` is the ship camp, wilderness clue layer, and between-round staging layer in
  the published flow `Run -> Maze -> Run`.
- Players spawn at the ship, notice the distant tower, choose how much
  wilderness scouting to do, then enter the maze.
- The wilderness is not filler: it contains authored clue markers that help
  players interpret maze threats and information gaps.
- After each maze round, survivors return to the ship, bank loot automatically,
  regroup, and prepare for the next round.

### Mental Model

- Server authority lives in `RunSessionService` and its authored-world adapters.
- Client presentation and input live in `RunClient.client.luau`.
- `run` owns ship-side mission orchestration, wilderness clue discovery,
  round resets, and the run-to-maze transition handoff.
- `run` does not own maze-side loot persistence or maze threat behavior.

### Key State Flow

1. Players arrive with optional teleport data from maze.
2. `RunSessionService` reconciles the shared mission session.
3. Players explore the ship/wilderness layer and discover private clue items.
4. The host opens the ship door to begin a round and unlock danger + maze entry.
5. Players enter maze through the tower path and later return to the ship.
6. The mission advances across 5 rounds until the loot quota succeeds or fails.

## Agent First

### Entry Files

- Server bootstrap: `places/run/src/ServerScriptService/Bootstrap.server.luau`
- Main service: `places/run/src/ServerScriptService/Run/RunSessionService.luau`
- Authored world layer:
  `RunWorldBuilder.luau`, `RunScene.luau`, `RunInteractionRegistry.luau`,
  `RunClueMarker.luau`, `RunToMazeTransition.luau`
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

- `places/maze/**` unless the issue is explicitly about the run-to-maze seam
- shared contract files when changing handoff schema, round-loop semantics, or
  replicated snapshot meaning

Boundary interfaces:

- Remotes currently used by run clients and maze clients:
  `RunAction`, `RunSnapshot`, `PrivateState`
- Shared handoff:
  `CampMazeSessionContract`,
  `MazeEntryAvailability`,
  `SessionConfig.PlaceIds`
- Deterministic tests:
  `tests/src/Shared/CampMazeSessionContract.spec.luau`,
  `tests/src/Shared/Inventory.spec.luau`,
  `tests/src/Shared/SessionPhase.spec.luau`

### When To Start In Contract Instead

- If run needs new mission-loop session fields
- If run and maze should change how loot/clue summaries cross places
- If return summaries or round outcome meaning changes
- If the shared run/maze remote surface changes shape

### Validation

- `stylua --check .`
- `selene .`
- `rojo build places/run/default.project.json -o .\tmp\run.rbxlx`
- If shared handoff behavior changed:
  `rojo build tests/default.project.json -o .\tmp\roblox_experience-tests.rbxlx`

## Notes

- `run` now presents a multi-round mission board, not a `Book of Sand` goal loop.
- Clues are physical personal inventory items by default; they are not auto-shared.
- The tower/maze pull should stay visually obvious even when clue content grows.
