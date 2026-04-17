# Contract Vibe

## Human First

### Gameplay Template

- `contract` is not a player-facing place. It is the handoff layer that keeps
  `run` and `maze` from inventing incompatible meanings.
- Its job is to provide stable cross-place language for remotes, session shape,
  teleport payloads, and shared place-routing config.
- If a change feels like "multiple sides need to agree on this first," it
  probably belongs here before it lands elsewhere.

### Mental Model

- The contract line currently lives under `packages/shared` because that is
  where the shared handoff definitions are source-controlled today.
- This vibe does not own every shared helper. It primarily owns the cross-place
  handoff surface plus the deterministic tests that lock it down.
- `contract` should stay explicit, deterministic, and easy to review in diff
  form.

### Key State Flow

1. A place proposes a new cross-place requirement.
2. `contract` updates the shared definition first.
3. Deterministic tests describe the new handshake behavior.
4. Place-local vibes rebase onto that baseline and update their consumers.

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
  `places/run/src/ServerScriptService/Run/RunSessionService.luau`
  `places/maze/src/ServerScriptService/Maze/MazeSessionService.luau`

No-touch zone:

- place-local orchestration logic when the issue can be solved by clarifying the
  shared contract alone
- unrelated shared runtime helpers under `packages/shared/src/Runtime/**`
  unless the issue is truly cross-cutting

Boundary interfaces:

- Remotes:
  `RunAction`, `RunSnapshot`, `PrivateState`
- Session contract:
  `CampMazeSessionContract`
- Gate policy:
  `MazeEntryAvailability`
- Config:
  `SessionConfig.PlaceIds`, `SessionConfig.DebugLocalMazeHandoff`

### When Contract Should Not Expand

- Do not move place-only world-building concerns into `contract`.
- Do not let `contract` become a dumping ground for convenience helpers needed
  by only one place.
- If a shape does not cross a place boundary and is not locked by deterministic
  tests, keep it local to the owning vibe.

### Validation

- `stylua --check .`
- `selene .`
- `rojo build tests/default.project.json -o .\\tmp\\roblox_experience-tests.rbxlx`
- `run-in-roblox --place .\\tmp\\roblox_experience-tests.rbxlx --script tests/run-in-roblox.lua`

## Notes

- The cleanest `contract` change is small, behavior-driven, and immediately
  reflected in deterministic tests.
- If a place needs a new seam, prefer a narrow explicit contract over hiding
  side effects inside one service.
