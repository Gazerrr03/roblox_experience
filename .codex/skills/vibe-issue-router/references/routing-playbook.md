# Routing Playbook

## Decision Tree

1. Read the issue body and acceptance criteria.
2. Identify the player-facing owner domain.
3. Check whether the change alters any of these shared seams:
   - teleport payloads
   - remote meaning
   - replicated snapshot shape
   - `SessionConfig.PlaceIds`
   - any file under `packages/shared/src/Session/**`
   - any file under `packages/shared/src/Network/**`
4. Classify the issue:
   - `place-local`: one vibe owns it and shared meaning does not change
   - `cross-vibe integration`: more than one vibe consumes it, but one integrated PR is the right delivery
   - `contract-first`: multiple sides must agree on a new shared meaning first

## Owner Heuristics

- `lobby`: rooming, roster, ready state, launch into run
- `run`: camp orchestration, camp UI, run snapshot behavior, run-owned gate logic
- `maze`: expedition runtime, loot, extraction, maze UI, maze world behavior
- `contract`: teleport/session/remotes/config seams shared across places

## Branch And Worktree Rules

- Use the matching long-lived worktree for place-local work.
- Use a feature branch off `main` when one integration PR is the cleanest delivery vehicle.
- Use `contract` first only when reviewability or dependency order demands it.
- Explain that PRs land on `main`; they do not merge into `main`, `contract`, `run`, and `maze` at once.

## Output Template

- `Issue`
- `Owner vibe`
- `Affected vibes`
- `Recommended worktree`
- `Base branch`
- `Landing branch`
- `Delivery mode`
- `Why this is not <other vibe>`
- `Review surface`

## Plan Mode Note

When a planning agent or plan mode is available, use it first for routing. The output should be a decision brief, not code.
