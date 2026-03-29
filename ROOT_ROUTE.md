# Root Route

This file is the routing map for contributors who start from repository root.
Use it to quickly decide what to read, what to run, and what should stay in root.

## Start Here

- Project overview and runtime flow: `README.md`
- Contribution and validation workflow: `CONTRIBUTING.md`
- Architecture guardrails and cross-place rules: `AGENTS.md`
- Agent entry adapter: `CLAUDE.md`
- Multi-place ownership map: `references/place-parallel-development.md`

## Root Files By Purpose

### Keep In Root: repo entry and toolchain

- `README.md`, `README.zh-CN.md`
- `CONTRIBUTING.md`, `AGENTS.md`, `CLAUDE.md`
- `start-run.cmd`
- `default.project.json`
- `aftman.toml`, `wally.toml`, `wally.lock`
- `stylua.toml`, `selene.toml`, `.gitignore`, `.styluaignore`

### Runtime Source (edit here for gameplay/features)

- `packages/shared/src`
- `packages/gameplay/src`
- `packages/ui/src`
- `places/lobby/src`
- `places/run/src`
- `places/maze/src`

### Specs and deterministic test coverage

- `tests/src/Shared`
- `tests/default.project.json`
- `tests/run-in-roblox.lua`

### References and templates (not runtime)

- `references/place-parallel-development.md`
- `references/templates/place-vibe/*`
- `references/studio-run-legacy/*`

### Prototypes and snapshots

- UI/scene prototypes: `assets/prototypes/ui/`
- Local Studio snapshot (`.rbxl`): `references/local-snapshots/`

## Fast Task Routing

- I need to implement gameplay logic: start in `packages/gameplay/src`
- I need to change cross-place handoff fields/remotes: start in `packages/shared/src` (`contract` line)
- I need to modify one place flow only: start in that place's `places/<place>/src`
- I need to validate shared logic changes: run `stylua --check .`, `selene .`, then test via `run-in-roblox`

## Hygiene Rules

- Do not hand-edit `DevPackages/`.
- Do not put temporary build outputs in root. Use `tmp/` (gitignored) for local build artifacts.
- Keep root focused on entry docs, toolchain config, and launch scripts.
