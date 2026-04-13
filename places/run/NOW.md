# Run NOW

## Current Focus

- Keep `run` as the orchestration place without letting it absorb maze-only
  logic or contract-only shape decisions.
- Keep `RunSessionService` as an orchestrator over authored scene objects and
  transition adapters instead of a god object.

## Open Questions

- When the currently shared `RunAction`, `RunSnapshot`, and `PrivateState`
  remote surface should split into a clearer run-vs-maze contract

## Temporary Exceptions

- Maze currently reuses the run remote set. Treat that as active coupling to pay
  down through `contract`, not as an endorsed long-term design.

## Near-Term Cleanup

- Any future seam cleanup should start by shrinking `RunSessionService`
  responsibilities instead of adding more cross-place branching inside it.
