# Run NOW

## Current Focus

- Keep `run` centered on ship orchestration + wilderness clue discovery for the
  new 5-round mission loop.
- Retire player-facing `Book of Sand` / `Pages` language in favor of banked loot,
  round count, and mission outcome language.
- Preserve authored clue markers and tower sightline as the main first-round
  teaching layer.

## Open Questions

- When the shared `RunAction` / `RunSnapshot` / `PrivateState` surface should be
  renamed to reflect cross-place mission semantics instead of legacy run naming.

## Temporary Exceptions

- Run still emits a few compatibility fields (`TeamPages`, `BookGoalAmount`) so
  older clients and harnesses do not break while migration finishes.

## Near-Term Cleanup

- Split remaining legacy camp/store UI assumptions away from the ship mission UI.
- Add richer authored wilderness clue content now that the clue-item pipeline is
  in place.
