---
name: roblox-vibe-issue-to-draft-pr
description: Implement a GitHub issue in this Roblox repo using the vibe workflow and finish with a draft PR to `main`. Use for issue-driven development tasks that may touch shared contract files plus place-local consumers, and when the work should end in validated code, a pushed branch, and a draft PR.
---

# Roblox Vibe Issue To Draft PR

Implement one issue cleanly, validate it, and stop at a draft PR. Do not merge.

## Start With Routing

Before editing code:

- read `AGENTS.md`
- read `references/place-parallel-development.md`
- read the owning `VIBE.md` first and `NOW.md` second
- run the issue through the repo's routing logic

If the issue changes cross-place handoff semantics, stage the shared contract before or alongside the place consumers and explain that choice in the PR body.

## Base Branch Rules

- Use a feature branch off `main` when the issue needs one integrated PR.
- Use a `contract`-first sequence only when the user asks to split delivery or when reviewability would materially improve.
- Land the draft PR on `main`.
- Do not silently update the long-lived `run`, `maze`, `lobby`, or `contract` branches as part of this skill. Those branches are synced from `main` after merge.

## Implementation Rules

- Keep changes inside the owner zone and direct dependency zone whenever possible.
- Update producers, consumers, and deterministic tests in the same change whenever contract or shared state shape changes.
- Keep bootstrap scripts thin.
- Treat server state as authoritative and clients as intent senders.
- Prefer the smallest end-to-end slice that satisfies the issue acceptance criteria.

## Validation Rules

Run the checks that match the touched area:

1. `stylua --check` on touched files
2. `selene .`
3. `rojo build` for every affected place project
4. `rojo build tests/default.project.json -o .\\tmp\\roblox_experience-tests.rbxlx` when shared or gameplay logic changes
5. `run-in-roblox --place .\\tmp\\roblox_experience-tests.rbxlx --script tests/run-in-roblox.lua` when shared or gameplay logic changes

Call out validation gaps honestly if a runtime or multi-place flow could not be exercised.

## Draft PR Rules

Create a draft PR that includes:

- a concise summary of the behavior change
- why the issue belongs to the owning vibe or why it became cross-vibe
- the validation commands that actually ran
- the main risks or follow-up items

End the PR body with `Closes #<issue-number>`.

## Stop Conditions

- Stop after the draft PR is created.
- Do not merge, squash, or sync long-lived vibe branches unless the user explicitly asks.
