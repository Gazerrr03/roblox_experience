# Issue 34 Case

## The Prompt

Issue `#34` started as a glow orb pilot for held light and visibility.

At first glance it looked `maze`-local because:

- pickup happens in the maze
- equip and hand-held feedback already existed more fully in `maze`

## Why It Was Not Maze-Only

The requirement became cross-vibe once the product intent was clarified:

- backpack should exist in both `run` and `maze`
- the player should keep the same inventory across `run -> maze -> run`
- the held item state should survive cross-place handoff

That means the issue was no longer just "maze pickup UX." It became a player-centric capability spanning:

- `contract`
- `run`
- `maze`

## Recommended Routing

- `Owner vibe`: `contract`
- `Affected vibes`: `contract`, `run`, `maze`
- `Recommended worktree`: feature work off `main` for one integrated PR
- `Base branch`: `main`
- `Landing branch`: `main`
- `Delivery mode`: `cross-vibe integration` with contract-first reasoning

## Why This Case Matters

This is the canonical example for teaching teammates that:

- the place where interaction happens is not always the true owner
- player-centric state often crosses vibe boundaries
- `main` is the integration branch even when the work touches multiple long-lived vibe domains
