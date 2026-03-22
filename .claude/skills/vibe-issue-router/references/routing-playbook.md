# Routing Playbook

## Decision Tree

1. Read the issue body and acceptance criteria.
2. Identify the player-facing owner domain.
3. Check whether the change alters any shared seam:
   - teleport payloads
   - remote meaning
   - replicated snapshot shape
   - `SessionConfig.PlaceIds`
   - `packages/shared/src/Session/**`
   - `packages/shared/src/Network/**`
4. Classify the issue as `place-local`, `cross-vibe integration`, or `contract-first`.

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

Use the planning agent first. Return a routing brief, not code.
