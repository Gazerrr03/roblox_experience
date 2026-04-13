# Maze NOW

## Current Focus

- Keep maze as a dedicated expedition runtime instead of letting run absorb more
  maze logic.
- Keep maze-to-run return behavior explicit and reviewable as the place evolves.

## Open Questions

- When to stop reusing the run-flavored remote surface and define a clearer maze
  transport contract

## Temporary Exceptions

- Maze still uses `RunAction`, `RunSnapshot`, and `PrivateState`. Treat that as
  transitional coupling, not as the target end state for a fully decoupled
  place.

## Near-Term Cleanup

- If maze grows more unique UI or state, separate the expedition-facing
  transport shape before the current run snapshot turns into a catch-all
  payload.
