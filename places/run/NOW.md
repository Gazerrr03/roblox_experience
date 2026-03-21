# Run NOW

## Current Focus

- Keep `run` as the orchestration place without letting it absorb maze-only
  logic or contract-only shape decisions.
- Preserve the local debug maze fallback as a debugging tool, not as the main
  architecture story.

## Open Questions

- Whether the run-to-maze seam should be formalized through a dedicated local
  portal adapter module, matching the direction explored on `origin/contract`
- When the currently shared `RunAction`, `RunSnapshot`, and `PrivateState`
  remote surface should split into a clearer run-vs-maze contract

## Temporary Exceptions

- Maze currently reuses the run remote set. Treat that as active coupling to pay
  down through `contract`, not as an endorsed long-term design.

## Near-Term Cleanup

- Any future seam cleanup should start by shrinking `RunSessionService`
  responsibilities instead of adding more cross-place branching inside it.
