# Maze Vibe

## Human First

### Gameplay Template

- `maze` is the fixed authored high-risk loot layer in the published flow
  `Run -> Maze -> Run`.
- The same logical maze persists across all 5 rounds of a mission.
- Players should feel information pressure here: clues found in `run` help them
  interpret threat tells, but do not hard-gate entry.
- Success is not about raw value; it is about safely extracting enough loot
  items back to the ship before the final round ends.

### Mental Model

- Server authority lives in `MazeSessionService` and `MazeWorldBuilder`.
- Client presentation and expedition input live in `MazeClient.client.luau`.
- `maze` owns authored world scan/bind, loot pickup, death drops, persistent
  drop recovery, extraction, and return-to-run handoff.
- `maze` does not own ship-side intermission, host/start logic, or final mission
  debrief presentation.

### Key State Flow

1. Players arrive with maze teleport data from run.
2. `MazeSessionService` merges the shared mission session.
3. The authored maze world is rebuilt and persistent loot/drop state is applied.
4. Players loot, dodge threats, recover drops, and return or get forced out.
5. Banked loot counts and remaining inventory are sent back through the shared
   contract.
6. Later rounds rebuild the same logical maze state from shared persistence.

## Agent First

### Entry Files

- Server bootstrap: `places/maze/src/ServerScriptService/Bootstrap.server.luau`
- Main service: `places/maze/src/ServerScriptService/Maze/MazeSessionService.luau`
- Main world builder:
  `places/maze/src/ServerScriptService/Maze/MazeWorldBuilder.luau`
- Scene bindings:
  `MazeScene.luau`, `MazeLootNode.luau`, `MazeInteractionRegistry.luau`
- Main client:
  `places/maze/src/StarterPlayer/StarterPlayerScripts/MazeClient.client.luau`
- Place project file: `places/maze/default.project.json`

### Allowed Change Graph

Owner zone:

- `places/maze/**`

Direct dependency zone:

- `packages/shared/src/Session/CampMazeSessionContract.luau`
- `packages/shared/src/Runtime/MazeWorldScanner.luau`
- `packages/shared/src/Network/Remotes.luau`
- `packages/shared/src/Config/SessionConfig.luau`
- `packages/shared/src/Runtime/**`
- `packages/gameplay/src/**`

No-touch zone:

- `places/run/**` unless the issue is explicitly about the return seam
- shared contract files when changing teleport shape, persistent-world state, or
  return summary semantics
- shared contract files when changing remote naming or replicated snapshot
  meaning across both places

Boundary interfaces:

- Shared handoff:
  `CampMazeSessionContract.buildMazeToCampTeleportData`,
  `CampMazeSessionContract.buildReturnSummary`,
  `CampMazeSessionContract.reconcileIncomingCampSession`
- Shared config:
  `SessionConfig.PlaceIds.Run`
- Deterministic tests:
  `tests/src/Shared/CampMazeSessionContract.spec.luau`,
  `tests/src/Shared/Inventory.spec.luau`,
  `tests/src/Shared/MazeRunTracker.spec.luau`

### When To Start In Contract Instead

- If maze needs new persistent-world state fields
- If loot/clue return summaries change meaning
- If the maze-to-run teleport payload changes shape
- If snapshot fields become shared expectations outside maze code

### Validation

- `stylua --check .`
- `selene .`
- `rojo build places/maze/default.project.json -o .\\tmp\\maze.rbxlx`
- If shared handoff behavior changed:
  `rojo build tests/default.project.json -o .\\tmp\\roblox_experience-tests.rbxlx`

## Notes

- The live maze path is authored-world scan/bind, not procgen.
- Loot already banked at the ship must not respawn in later rounds.
- Death drops and unrecovered clue items are part of the persistent mission state.
- Keep maze-specific behavior inside maze modules whenever possible.
- `MazeStaticWorld` is the formal runtime source for expedition content.
- If a change makes the maze client or service read more and more like a run
  clone, the seam is probably in the wrong place and should move toward
  `contract` first.
