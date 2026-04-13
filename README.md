# roblox_experience

[English](./README.md) | [简体中文](./README.zh-CN.md)

Roblox game skeleton for a multi-place experience:

- `places/lobby`: team assembly, ready checks, and run launch
- `places/run`: camp, wilderness, maze entry, and settlement handoff
- `places/maze`: maze expedition, loot, extraction, and return to the Run place
- `packages/shared`: shared enums, networking, schema helpers, and utilities
- `packages/gameplay`: pure gameplay data and stateful domain modules
- `packages/ui`: lightweight UI helpers for the first vertical slice
- `DevPackages`: Wally-generated third-party dependencies, kept separate from repo-owned source

## Place Delivery Lines

Parallel work on the experience is split into four long-lived lines:

- `lobby`
- `run`
- `maze`
- `contract`

Use one worktree per line so place content stays isolated and cross-place
handoff changes stay on the `contract` line. See
`references/place-parallel-development.md` for ownership, worktree commands,
merge order, and validation rules.

## Local Setup And Startup

### One-Click Windows Start

For the fastest local startup on Windows, use the helper entrypoint from the
repository root:

```powershell
.\start-run.cmd
```

That script will:

- install the repo toolchain with `aftman install` if the local Rojo/Wally
  binaries are missing
- run `wally install` if `DevPackages/` is empty or missing
- start `rojo serve` for the `run` place on port `34872`

You still need these installed once on your machine before using the one-click
entrypoint:

- Roblox Studio
- the Rojo Studio plugin
- `aftman`

If you want a different place or port, use the PowerShell helper directly:

```powershell
.\scripts\dev.ps1 -Place lobby
.\scripts\dev.ps1 -Place maze -Port 34873
.\scripts\dev.ps1 -Place run -RefreshDeps
```

### Prerequisites

- Install Roblox Studio.
- Install the Rojo Studio plugin.
- Install `aftman` on your machine.

### First-Time Toolchain Setup

Run these commands from the repository root:

```powershell
aftman self-install
```

Restart your terminal after `aftman self-install` so `~/.aftman/bin` is added to
`PATH`.

Then install the repo-managed tools and dependencies:

```powershell
aftman install
wally install
```

You can verify the local toolchain with:

```powershell
rojo --version
wally --version
stylua --version
selene --version
```

### Start A Place Locally

Run one of these commands from the repository root, depending on which place you
want to work on:

```powershell
rojo serve
```

Serves the root project, which is currently wired to the run place.

```powershell
rojo serve places/lobby/default.project.json
```

Serves the lobby place.

```powershell
rojo serve places/run/default.project.json
```

Serves the run place directly.

```powershell
rojo serve places/maze/default.project.json
```

Serves the maze place directly.

If you need to run more than one Rojo server at the same time, give each one a
different port, for example:

```powershell
rojo serve places/lobby/default.project.json --port 34873
```

If you want one Studio harness file per place that can be opened and published
directly, build:

```bash
./scripts/build-harnesses.sh
```

Or on Windows PowerShell:

```powershell
.\scripts\build-harnesses.ps1
```

This writes:

- `places/lobby/harness/lobby.rbxlx`
- `places/run/harness/run.rbxlx`
- `places/maze/harness/maze.rbxlx`

Keep authored scene content under the matching static world root:

- `Workspace/LobbyStaticWorld`
- `Workspace/RunStaticWorld`
- `Workspace/MazeStaticWorld`

### Connect Roblox Studio

1. Start the desired `rojo serve` command and keep that terminal open.
2. Open Roblox Studio.
3. Open the Rojo plugin.
4. Connect to `localhost` on the port printed by Rojo, usually `34872`.
5. Sync the project into Studio from the plugin.

### Local Startup vs Published Teleports

- `start-run.cmd`, `scripts/dev.ps1`, and `rojo serve` only start local source sync and place composition.
- They do **not** turn a local `.rbxl` or Studio session into a published Roblox place.
- In a local Studio session, `game.PlaceId` and `game.GameId` may still be `0`, so cross-place maze teleports can remain blocked even when Rojo is connected.
- To test the real maze teleport flow, use published `Lobby` / `Run` / `Maze` place ids.
- `Run` and `Maze` no longer provide an in-place debug fallback. If teleport is blocked locally, the authored maze gate stays blocked until real place ids are configured.

### Validation Commands

Run these from the repository root when you need local validation:

```powershell
stylua --check .
selene .
```

For logic tests on Windows, write the built place into a local temp file instead
of `/tmp`:

```powershell
New-Item -ItemType Directory -Force .\tmp | Out-Null
rojo build tests/default.project.json -o .\tmp\roblox_experience-tests.rbxlx
run-in-roblox --place .\tmp\roblox_experience-tests.rbxlx --script tests/run-in-roblox.lua
```

## Source vs Dependency Directories

- `packages/` contains the active project-owned source wired into the Rojo project files and should be committed.
- `DevPackages/` is generated by Wally and should stay untracked.
- After `wally install`, the generated dependency tree should only live under `DevPackages/` and must not replace `packages/`.

## Development Rules

Project-specific guardrails for AI and human contributors live in `AGENTS.md`.
Use that file as the default playbook for architecture boundaries, networking
contracts, validation, and integration hygiene.
The repo-wide vibe index lives in `references/place-parallel-development.md`.
Each long-lived code domain also keeps local `VIBE.md` and `NOW.md` files next
to the owned code so humans and agents can load the right context without
scanning the full repository.
Contributor-facing setup, validation, and CI/platform notes live in
`CONTRIBUTING.md`.

Pull requests should follow the repository PR template so Roblox-specific
integration checks stay attached to every change.

## Vibe Map

The repository currently treats these as first-class vibes:

- `places/lobby` -> lobby launch and ready flow
- `places/run` -> camp orchestration and maze entry
- `places/maze` -> expedition runtime and maze return
- `packages/shared` -> the `contract` workstream for shared handoff definitions

Use the local files when you enter one of those domains:

- `VIBE.md` for the stable handbook
- `NOW.md` for current pressure points and short-lived notes
- local `AGENTS.md` / `CLAUDE.md` as thin agent adapters

### Why This Exists

If you do not come from a CS background, you can think of the vibe system as a
"working map" for the project.

Without it, a change that looks local can easily spill into shared handoff
rules, another place's runtime flow, or cross-place teleport behavior. That
creates confusion about:

- who owns the change
- where to start reading
- which files are safe to edit
- when a task must be split into a shared `contract` change first

The vibe system exists to make those boundaries visible before work starts. It
helps humans and AI collaborators avoid mixing place content, shared contracts,
and integration work in the same blurry patch.

### What The System Contains

Each vibe has a small set of files with different jobs:

- `references/place-parallel-development.md`
  The repo-wide map. It explains how `lobby`, `run`, `maze`, and `contract`
  relate to each other.
- local `VIBE.md`
  The stable handbook for one code domain. It explains the purpose, mental
  model, entry files, allowed change graph, and validation path.
- local `NOW.md`
  The loose-leaf page. It records today's pressure points, temporary
  exceptions, and cleanup notes without polluting the stable handbook.
- local `AGENTS.md` / `CLAUDE.md`
  Thin adapters that tell an agent where to look. They should not become a
  second source of truth.

In practice, the normal reading order is:

1. Read the repo-wide map once.
2. Enter the code domain you need.
3. Read that domain's `VIBE.md`.
4. Read `NOW.md` only if you need the current edge cases or temporary context.

## Place Flow And Runtime Routing

### Published Runtime Path

- `Lobby -> Run -> Maze -> Run`
- `LobbyService` starts the experience by reserving a private `Run` server and teleporting the ready crew there.
- `RunSessionService` owns the camp session, opens wilderness access, and teleports players into the shared `Maze` server when the maze gate is used.
- `MazeSessionService` owns the maze-side expedition and teleports players back to `Run` when they return early or when settlement completes.

### Local Studio Path

- `rojo serve` only syncs source into Studio; it does not assign real Roblox `PlaceId` or `GameId` values.
- If a local Studio session has `PlaceId == 0` or `GameId == 0`, the formal maze teleport path is treated as unavailable.
- The maze gate stays blocked until the published place ids are configured, and the reason is reported back through the run HUD/status text.

## Runtime Assumptions

- Teleport flow needs real place IDs for `Lobby`, `Run`, and `Maze`.
- You can configure place IDs in either of these ways:
  - source-controlled defaults in `packages/shared/src/Config/SessionConfig.luau`
  - Studio attributes on `game` or `ReplicatedStorage`: `SessionPlaceIdLobby`, `SessionPlaceIdRun`, `SessionPlaceIdMaze`
- You can enable the local in-place maze debug route with `SessionDebugLocalMazeHandoff` on `game` or `ReplicatedStorage`.
- The run loop is intentionally simple: camp, expedition, loot, extract, settle, reset.
- Hidden-role gameplay is deferred, but visibility and permission interfaces are already present.

## Tests

Pure logic tests live under `tests/` for:

- state machine transitions
- maze generation structure
- inventory capacity and deposit math
- visibility filtering for private role data

`tests/src/Shared` is the authoritative location for pure logic coverage. Any
non-trivial shared/gameplay behavior change should update or add deterministic
tests there.

CI always gates formatting and linting. When the repository secret
`ROBLOSECURITY` is configured, the `roblox-tests` job also runs
`run-in-roblox` against the data model built from `tests/default.project.json`
and reports pass/fail from Studio on a Windows runner.

### Roblox Studio CI Enablement

- The `roblox-tests` job depends on the repository secret `ROBLOSECURITY`.
- Without that secret, the workflow stays green but skips every Studio-backed step.
- With that secret present, the workflow path is: install Aftman -> install Roblox Studio -> build `tests/default.project.json` -> run `tests/run-in-roblox.lua`.

### Roblox Studio CI Triage

- `ROBLOSECURITY` missing:
  The workflow summary will classify this as a configuration issue. Add the repository secret before treating `roblox-tests` as a real end-to-end signal.
- `Install Roblox Studio` fails:
  Treat it as a Studio installation or authentication problem first. Inspect that step before looking at gameplay code.
- `Build test place` fails:
  Treat it as a Rojo mapping or source/build problem. Re-run `rojo build tests/default.project.json -o /tmp/roblox_experience-tests.rbxlx` locally if possible.
- `Run Roblox logic tests` fails:
  Inspect that step first. If Studio never boots, treat it as a runner or Studio startup problem. If Studio boots and the test output reports failures, treat it as a test logic problem.

### Local Approximation Of The CI Path

- If your machine can run Roblox Studio, the closest local reproduction path is:
  `aftman install`
  `rojo build tests/default.project.json -o /tmp/roblox_experience-tests.rbxlx`
  `run-in-roblox --place /tmp/roblox_experience-tests.rbxlx --script tests/run-in-roblox.lua`
- If your machine cannot run Studio locally, rely on `stylua --check .`, `selene .`, and the GitHub Actions `roblox-tests` logs as the authoritative signal.
