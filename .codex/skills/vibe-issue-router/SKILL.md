---
name: vibe-issue-router
description: Route a GitHub issue or feature request in this Roblox repo to the correct vibe (`lobby`, `run`, `maze`, or `contract`) and recommend the worktree, base branch, landing branch, and review surface. Use when triaging a new issue, explaining code ownership, deciding whether a request is place-local or cross-place, or checking whether work should start contract-first.
---

# Vibe Issue Router

Route an issue before code is written. Prefer a planning pass first when the environment supports a dedicated plan mode or planning subagent.

Read references only as needed:

- Read `references/routing-playbook.md` when you need the full decision tree or the exact output format.
- Read `references/issue-34-case.md` when the user wants an onboarding example or a concrete cross-vibe case.

## Load The Right Context

Read these files before making a routing call:

- `AGENTS.md`
- `references/place-parallel-development.md`
- the relevant local `VIBE.md` first and `NOW.md` second for any vibe that looks involved

Use `gh issue view <id>` when the user gives an issue number or URL.

## Classify The Work

Classify the issue into one of three buckets:

1. `place-local`
   - One vibe owns the change.
   - No cross-place contract meaning changes.
   - Start in the matching long-lived worktree or branch.

2. `cross-vibe integration`
   - More than one vibe consumes the feature.
   - The issue still belongs in one integration PR.
   - Start from `main` and explain which vibes are touched.

3. `contract-first`
   - The issue changes teleport payloads, remote meaning, snapshot shape, place ids, or shared handoff semantics.
   - Start with the `contract` owner zone under `packages/shared/src/Session/**`, `packages/shared/src/Network/**`, `packages/shared/src/Config/SessionConfig.luau`, and the matching tests.
   - Call out downstream consumer vibes explicitly.

## Routing Rules

- Choose `lobby` when the issue is about rooming, roster, ready state, or lobby-to-run launch.
- Choose `run` when the issue is about camp orchestration, camp-only UI, run snapshots, or the run-to-maze seam from the run side.
- Choose `maze` when the issue is about expedition runtime, loot, extraction, maze world flow, or maze-side UI.
- Choose `contract` when multiple sides need to agree on a new shared meaning before place code can safely evolve.
- Choose `main` as the landing branch for integration PRs.
- Do not describe a PR as "merging into `main`, `contract`, `run`, and `maze` at once." Explain that the PR lands on `main`, then `main` is synced back into the long-lived vibe branches.

## Output Contract

Produce the routing brief defined in `references/routing-playbook.md`.

## Special Cases

- If the issue is really a player-centric ability that must survive `run -> maze -> run`, bias toward `contract-first` or `cross-vibe integration`, not a maze-only call.
- If the issue only changes place-local composition while reading shared state, keep the owner local and note shared files as dependency zone only.
- If the routing is ambiguous, stop after the routing brief and ask for confirmation instead of coding.
