---
name: roblox-vibe-issue-to-draft-pr
description: Implement a GitHub issue in this Roblox repo using the vibe workflow and stop at a draft PR to main. Use for issue-driven implementation that should end in validated code, a pushed branch, and a draft PR.
disable-model-invocation: true
argument-hint: "[issue-number-or-url]"
---

Implement issue $ARGUMENTS in this repository and stop at a draft PR.

Read references only as needed:

- `references/execution-checklist.md` for the full execution order
- `references/issue-34-case.md` for the onboarding example based on issue `#34` and PR `#95`

## Start here

Read:

- `AGENTS.md`
- `references/place-parallel-development.md`
- the owning `VIBE.md` first and `NOW.md` second

Route the issue before coding. If it changes cross-place handoff semantics, make the contract change explicit and update the matching tests.

## Branching rules

- Use a feature branch off `main` when one integration PR is the right delivery vehicle.
- Land the draft PR on `main`.
- Do not silently sync `main` back into `run`, `maze`, `lobby`, or `contract`.

## Validation

Run the checks that match the touched area:

1. `stylua --check` on touched files
2. `selene .`
3. `rojo build` for affected place projects
4. test project build plus `run-in-roblox` when shared or gameplay logic changes

## Draft PR requirements

Use the PR structure in `references/execution-checklist.md`.

End the PR body with `Closes #<issue-number>`.

Do not merge.
