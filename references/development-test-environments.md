# Development Test Environments

This repository supports multiple kinds of validation, but they are not
interchangeable.

For feature work, especially `maze-first` monster development, use the
following four-layer test strategy instead of relying on a single environment.

## Why This Exists

- `main` does not auto-deploy from this repository, but the team currently
  treats `main` as the source for manual Roblox publishes.
- That makes the published production experience valuable and risky to use as a
  daily experimentation sandbox.
- Local Studio, Studio-backed tests, and published teleports each answer
  different questions. Mixing them together leads to false confidence.

## Environment Controls

Use the existing Studio attribute overrides instead of editing
`packages/shared/src/Config/SessionConfig.luau` for day-to-day environment
switching:

- `SessionPlaceIdLobby`
- `SessionPlaceIdRun`
- `SessionPlaceIdMaze`
- `SessionDebugLocalMazeHandoff`

Set those attributes on `game` or `ReplicatedStorage` in Studio when you need
to point a session at staging place ids or enable the local debug maze handoff.

Keep the source-controlled defaults in `SessionConfig` aligned with the formal
published experience, not with a temporary staging setup.

## Layer 0: Deterministic Logic Baseline

Use this before opening Studio and before every PR:

```powershell
stylua --check .
selene .
New-Item -ItemType Directory -Force .\tmp | Out-Null
rojo build tests/default.project.json -o .\tmp\roblox_experience-tests.rbxlx
run-in-roblox --place .\tmp\roblox_experience-tests.rbxlx --script tests/run-in-roblox.lua
```

Questions this layer answers:

- did shared/gameplay logic regress
- did contract expectations drift
- can the test place still build and boot through Studio-backed automation

Questions this layer does not answer:

- does the real cross-place teleport path work
- does the monster feel right in a live session

## Layer 1: Local Maze Iteration

This is the default development environment for `maze-first` monster work.

Run:

```powershell
.\scripts\dev.ps1 -Place maze
```

Use this layer to iterate quickly on:

- spawn logic
- patrol and chase behavior
- player feedback
- local feel and pacing
- single-player expedition loops before return/settlement

Questions this layer answers:

- does the local monster behavior match the intended design
- did the maze-specific runtime stay coherent

Questions this layer does not answer:

- did `run -> maze` orchestration still behave correctly
- did published teleport permissions or place wiring change

## Layer 2: Local Run Handoff Validation

Use this after any meaningful monster milestone that could affect the run-owned
maze entry flow.

Run:

```powershell
.\scripts\dev.ps1 -Place run
```

In Studio, set:

- `SessionDebugLocalMazeHandoff = true`

Then validate the local handoff path from run into the in-place maze sandbox.

Use this layer to answer:

- did the run entry flow still work
- did status text and local handoff expectations stay coherent
- did monster changes accidentally break the run-owned orchestration path

Important boundary:

- a passing local debug fallback is not proof that formal cross-place teleport
  works

## Layer 3: Staging Published Smoke

Use this for milestone checks, multiplayer smoke tests, and final confidence
before merge or publish.

Requirements:

- a separate staging `Lobby / Run / Maze` published setup
- staging place ids injected through `SessionPlaceIdLobby`,
  `SessionPlaceIdRun`, and `SessionPlaceIdMaze`
- no edits to the source-controlled defaults in `SessionConfig`

Recommended smoke coverage:

1. Single-player: `Lobby -> Run -> Maze -> Run`
2. Two-player: shared entry, shared maze presence, at least one return or
   settlement-related path

Questions this layer answers:

- does the formal teleport chain work outside local file mode
- do publish-time permissions and place ownership still line up
- does the feature survive a more realistic multiplayer path

## Recommended Rhythm For Monster Work

For `maze-first` monster development, use this cadence:

1. Build and verify Layer 0
2. Iterate in Layer 1
3. Re-check Layer 2 when the change affects entry, return, or run-facing state
4. Run Layer 3 at every milestone and before merge readiness

Use single-player as the daily default. Add a two-player smoke pass at each
meaningful milestone rather than waiting until the end.

## Do Not Do This

- Do not rewrite `SessionConfig.PlaceIds` to point at staging for normal
  development.
- Do not use the formal published production experience as the default daily
  test sandbox.
- Do not treat a passing local debug fallback as proof that formal teleports are
  healthy.
