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

Return a routing brief with:

- Issue
- Owner vibe
- Affected vibes
- Recommended worktree
- Base branch
- Landing branch
- Delivery mode
- Why this is not another vibe
- Review surface

If routing is ambiguous, stop after the brief and say what needs confirmation.
