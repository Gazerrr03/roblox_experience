---
name: vibe-issue-router
description: Route a GitHub issue in this Roblox repo to the correct vibe, worktree, and delivery mode. Use when triaging a new issue or deciding whether work is place-local, cross-vibe, or contract-first.
context: fork
agent: Plan
disable-model-invocation: true
argument-hint: "[issue-number-or-url]"
allowed-tools: Read, Grep, Glob, Bash(gh *), Bash(git *), Bash(rg *)
---

Route issue $ARGUMENTS for this repository.

Read references only as needed:

- `references/routing-playbook.md` for the full decision tree and output format
- `references/issue-34-case.md` for the onboarding example based on issue `#34`

## Required context

Read:

- `AGENTS.md`
- `references/place-parallel-development.md`
- the relevant local `VIBE.md` first and `NOW.md` second

Use `gh issue view` when $ARGUMENTS is an issue number or URL.

## Classification

Choose one of:

1. `place-local`
2. `cross-vibe integration`
3. `contract-first`

Mark the issue `contract-first` if it changes teleport payloads, remote meaning, snapshot shape, place ids, or the shared handoff surface under:

- `packages/shared/src/Session/**`
- `packages/shared/src/Network/**`
- `packages/shared/src/Config/SessionConfig.luau`

## Deliverable

Return the routing brief defined in `references/routing-playbook.md`.

If routing is ambiguous, stop after the brief and say what needs confirmation.
