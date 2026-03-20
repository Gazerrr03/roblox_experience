# Contributing

This repository uses a source-driven Roblox workflow built around Rojo, Wally,
Luau formatting/linting, and a Studio-backed test job in GitHub Actions.

This guide is for contributors who need one place to answer:

- what to install locally
- which checks should run on your machine
- which checks are better treated as CI-only or Windows-only signals
- how to reason about common platform differences

## Toolchain Checklist

Install these first:

1. `aftman install`
2. `wally install`

That gives you the tools used by the repository today:

- `rojo`
- `wally`
- `stylua`
- `selene`
- `run-in-roblox`

## Source Layout You Should Edit

The active runtime package source lives under:

- `packages/shared/src`
- `packages/gameplay/src`
- `packages/ui/src`

The current Rojo project files point at `packages/**`, including:

- `default.project.json`
- `places/lobby/default.project.json`
- `places/run/default.project.json`
- `places/maze/default.project.json`
- `tests/default.project.json`

If a document or comment disagrees with those project files, trust the project
files first.

## Parallel Place Workflow

Use these long-lived delivery lines for multi-place work:

- `lobby`
- `run`
- `maze`
- `contract`

The `contract` line owns cross-place teleport payloads, shared remote names,
session handoff records, and the deterministic tests that lock those contracts.
Place lines should stay focused on their own `places/<name>/**` content plus
their local portal adapter.

For the full ownership and worktree layout, see
`references/place-parallel-development.md`.

## Local Validation

These checks are the default local baseline:

1. `stylua --check .`
2. `selene .`

If you touch shared or gameplay logic, also update deterministic coverage under
`tests/src/Shared`.

If you touch Rojo wiring, package layout, remotes, or runtime bootstrap, also
verify the relevant project files still build or serve correctly.

Useful local commands:

- `rojo serve`
- `cd places/lobby && rojo serve`
- `cd places/run && rojo serve`
- `rojo build tests/default.project.json -o <output.rbxlx>`

## Studio-Backed Tests

The closest local reproduction of the CI Roblox test path is:

1. `aftman install`
2. `rojo build tests/default.project.json -o <output.rbxlx>`
3. `run-in-roblox --place <output.rbxlx> --script tests/run-in-roblox.lua`

Use this when:

- your machine can launch Roblox Studio
- you changed shared/gameplay logic and want the most realistic automated signal
- you need to compare local behavior with the `roblox-tests` GitHub Actions job

If your local machine cannot run Studio reliably, treat `stylua --check .`,
`selene .`, and the GitHub Actions logs as the primary validation path.

## What CI Verifies

The GitHub Actions workflow currently has two layers:

- `luau-quality`
  Verifies `stylua --check .` and `selene .`.
- `roblox-tests`
  Builds `tests/default.project.json` and runs `tests/run-in-roblox.lua`
  through Roblox Studio on a Windows runner.

Important boundary:

- `luau-quality` is expected to be reproducible locally on most development
  machines.
- `roblox-tests` is the stronger integration signal, but it depends on
  GitHub-hosted Windows runners plus Roblox Studio installation.

## CI Prerequisites

The `roblox-tests` job depends on the repository secret `ROBLOSECURITY`.

Current behavior:

- if `ROBLOSECURITY` is configured, the workflow installs Roblox Studio, builds
  the test place, and runs `run-in-roblox`
- if `ROBLOSECURITY` is missing, the workflow stays green but skips the
  Studio-backed steps

That means:

- a green `luau-quality` run is always meaningful for formatting and linting
- a green `roblox-tests` run is only an end-to-end Studio signal when the
  secret is present

## Platform Differences

The main platform split in this repository is:

- local dev can happen on many machines
- Studio-backed automation currently relies on GitHub Actions Windows runners

Common examples:

- You may be able to run `stylua`, `selene`, and `rojo build` locally even when
  Studio is unavailable.
- A GitHub Actions failure in `Install Roblox Studio` is usually a CI setup or
  authentication problem first, not a gameplay bug.
- A failure in `Build test place` usually points to Rojo mapping, file layout,
  or source/build problems.
- A failure in `Run Roblox logic tests` may be either Studio startup trouble or
  actual test logic failure, so inspect that step before changing gameplay code.

## Suggested Verification Order

For most changes, use this order:

1. Run `stylua --check .`
2. Run `selene .`
3. If applicable, update `tests/src/Shared`
4. If applicable, run `rojo build tests/default.project.json -o <output.rbxlx>`
5. If Studio is available, run `run-in-roblox --place <output.rbxlx> --script tests/run-in-roblox.lua`
6. Use GitHub Actions as the final source of truth for the Windows/Studio path

## When To Ask For Help

Pull in a maintainer when:

- the workflow behavior suggests a missing repository secret or permission issue
- project files and docs disagree about active source paths
- a change spans package contracts, place bootstrap, and networking at once
- you cannot tell whether a failure belongs to CI environment setup or gameplay
  logic
