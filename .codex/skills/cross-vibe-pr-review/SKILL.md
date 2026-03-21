---
name: cross-vibe-pr-review
description: Review a pull request in this Roblox repo with a cross-vibe mindset. Use when a PR may touch `contract`, `lobby`, `run`, or `maze` together, when the merge target or branch sync story is unclear, or when review needs to separate code correctness from cross-place handoff and integration risks.
---

# Cross Vibe PR Review

Review with findings first. Prefer a planning pass first when the environment supports a dedicated plan mode or planning subagent.

Read references only as needed:

- Read `references/review-checklist.md` when you need the full cross-vibe review checklist and merge-story rules.
- Read `references/pr-95-case.md` when the user wants a concrete onboarding example based on issue `#34` and PR `#95`.

## Resolve Scope

Start by collecting:

- PR metadata (`gh pr view`)
- changed files (`gh pr diff --name-only`)
- full diff when needed (`gh pr diff`)
- current base branch freshness (`git fetch origin`)

## Map The Vibes

Map changed files to vibe surfaces:

- `packages/shared/src/Session/**`, `packages/shared/src/Network/**`, `packages/shared/src/Config/SessionConfig.luau`, and matching tests are `contract`
- `places/lobby/**` is `lobby`
- `places/run/**` is `run`
- `places/maze/**` is `maze`

Read the touched vibe's `VIBE.md` first and `NOW.md` second before judging whether the change is in the right owner zone.

## Review Priorities

Look for concrete failures, not style nits:

- contract drift between producers, consumers, and tests
- teleport or join lifecycle regressions
- replicated snapshot mismatches between server and client
- run/maze ownership confusion
- missing `rojo build` or `run-in-roblox` coverage for shared gameplay changes
- incorrect merge story, especially when the PR is described as updating multiple long-lived branches at once

## Output Format

Always produce:

1. `Findings`
2. `Open Questions / Assumptions`
3. `Summary`

Follow the detailed output and review rules in `references/review-checklist.md`.

## Merge Readiness Language

- `Approve-ready`: no blocking code findings remain
- `Merge-ready`: code is approve-ready and no process blockers remain
- `Blocked`: code issue or merge gate still needs action
