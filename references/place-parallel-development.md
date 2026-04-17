# Multi-Place Vibe Framework

This repository treats long-lived multi-place delivery lines as code-domain
`vibe`s. The goal is not to write one giant master document. The goal is to
make sure a human or an agent can enter one code domain and quickly understand:

- what this unit owns
- where to enter
- what is safe to change
- when to start in `contract` first
- how to validate the change

The current first-class `vibe`s are:

- `run`
- `maze`
- `contract`

The current code-domain anchors are:

- `run` -> `places/run/**`
- `maze` -> `places/maze/**`
- `contract` ->
  `packages/shared/src/Session/**`,
  `packages/shared/src/Network/**`,
  `packages/shared/src/Config/SessionConfig.luau`,
  and the matching deterministic coverage under `tests/src/Shared/**`

## Progressive Disclosure

Each `vibe` has two layers:

1. `VIBE.md`
   The stable handbook. Record responsibilities, mental model, entrypoints,
   allowed change graph, and validation here.
2. `NOW.md`
   The loose-leaf layer. Record current pressure points, temporary exceptions,
   and near-term cleanup here instead of bloating the stable handbook.

Thin agent adapters may also exist:

- `AGENTS.md`
- `CLAUDE.md`

These files must stay thin. Their job is to route the reader back to
`VIBE.md` and `NOW.md`, not to become a second source of truth.

## Code Domain Before Branch

Code domains come first. Branches and worktrees come second.

- Branches, worktrees, issues, and PRs are coordination tools around a code
  domain. They are not the `vibe` itself.
- An issue or PR belongs first to the code domain that owns the touched code.
- If a task crosses `contract` and a place, make the handoff explicit before
  deciding whether it should land as `contract first`.

Recommended worktree layout:

```bash
git worktree add -b run ../roblox_experience-run origin/run
git worktree add -b maze ../roblox_experience-maze origin/maze
git worktree add -b contract ../roblox_experience-contract origin/contract
```

Use a dedicated worktree when you want one long-lived line to keep a cleaner
local context and a smaller review surface.

## When Contract Must Go First

These changes should land in `contract` first by default, then flow into the
places:

- teleport payload shape changes
- `CampMazeSessionContract` state shape or reconciliation rule changes
- shared remote name or meaning changes
- changes to cross-place handoff fields in `SessionConfig`
- changes to shared behavior defined by deterministic tests

After `contract` lands, rebase or merge the place branches onto the new
baseline and keep place PRs focused on local adapters or consumers.

## Allowed Change Graph

Each `VIBE.md` must explicitly describe four things:

1. Owner zone
   The directories and entrypoints this vibe may change directly.
2. Direct dependency zone
   Shared modules this vibe commonly depends on. It may influence them, but
   should not mutate them casually.
3. No-touch zone
   Adjacent places or packages that should not be touched from here unless the
   issue is explicitly cross-domain.
4. Boundary interfaces
   The contract modules, remotes, configs, or test fixtures that define legal
   crossing points.

## Required Local Files

Each first-class `vibe` should keep these files near the code it owns:

- `VIBE.md`
- `NOW.md`
- `AGENTS.md`
- `CLAUDE.md`

The first screen of `VIBE.md` should serve both audiences:

- For humans: gameplay template, mental model, key state flow
- For agents: entry files, allowed change graph, validation, cross-domain rules

## New Place Onboarding

Do not wait until a new place becomes messy before adding its rules. A new
place should be onboarded as a `vibe` on day one.

Minimum checklist:

1. Create `places/<new-place>/VIBE.md`
2. Create `places/<new-place>/NOW.md`
3. Create `places/<new-place>/AGENTS.md`
4. Create `places/<new-place>/CLAUDE.md`
5. Update the relevant `default.project.json`
6. Document the allowed change graph and contract interfaces
7. Add or update deterministic tests if the new place changes shared behavior

Template entrypoint: `references/templates/place-vibe/`

## Review And Merge Flow

When a feature crosses delivery lines, the default order is:

1. If the handoff changes, land `contract` first
2. Rebase affected places onto that baseline
3. Land place-local adapter or orchestration PRs separately
4. Make the PR description explicit about which `vibe` owns the change

If a task can be solved inside one `vibe`, do not force cross-line choreography
just to look decoupled. The framework exists to reduce hidden coupling, not to
create process burden.
