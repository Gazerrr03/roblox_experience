# Maze Vibe

## Human First

### Gameplay Template

- `maze` is the expedition place in the published flow `Run -> Maze -> Run`.
- The player experience here is first-person maze exploration, loot collection,
  extraction pressure, and a settlement handoff back to run.
- This place should feel like a focused expedition runtime, not a second camp.

### Mental Model

- Server authority lives in `MazeSessionService` and `MazeWorldBuilder`.
- Client presentation and expedition input live in `MazeClient.client.luau`.
- `maze` owns maze-side authored world setup, expedition progression,
  loot/extract flow, and the return trigger back into run.
- `maze` does not own lobby readiness or run-side settlement rules.

### Key State Flow

1. Players arrive with maze teleport data from run.
2. `MazeSessionService` merges and validates the incoming camp session.
3. The maze world is built and expedition snapshots are pushed to clients.
4. Players interact with maze objectives and extraction flow.
5. Return summaries are built and sent back through the shared contract.
6. Players teleport back into run for settlement or early-return handling.

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
  `SessionConfig.PlaceIds.Run`
- Deterministic tests:
  `tests/src/Shared/CampMazeSessionContract.spec.luau`,
  `tests/src/Shared/Remotes.spec.luau`,
  `tests/src/Shared/MazeModuleAssetContract.spec.luau`

### When To Start In Contract Instead

- If maze needs new return summary data
- If maze should stop speaking through the current run-flavored remote surface
- If the maze-to-run teleport payload or reconciliation rules change
- If snapshot fields become a shared expectation outside the maze code domain

### Validation

- `stylua --check .`
- `selene .`
- `rojo build places/maze/default.project.json -o .\\tmp\\maze.rbxlx`
- If shared handoff behavior changed:
  `rojo build tests/default.project.json -o .\\tmp\\roblox_experience-tests.rbxlx`

## Notes

- Keep maze-specific behavior inside maze modules whenever possible.
- `MazeStaticWorld` is the formal runtime source for expedition content.
- If a change makes the maze client or service read more and more like a run
  clone, the seam is probably in the wrong place and should move toward
  `contract` first.
