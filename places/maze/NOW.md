# Maze NOW

## Current Focus

- Keep maze as the fixed authored expedition layer for the new 5-round mission.
- Preserve mission persistence: collected loot stays gone, dropped packs can be
  recovered later, and clue items travel back and forth with players.
- Present loot success in item counts, not value/weight language.

## Open Questions

- When to stop reusing the still run-flavored shared remote surface and define a
  clearer maze-specific transport contract.

## Temporary Exceptions

- Maze still emits a few compatibility inventory/session fields so older clients
  and harnesses keep working during the mission-loop migration.

## Near-Term Cleanup

- Add more authored threat-tell nodes that explicitly echo wilderness clue text.
- Replace remaining direct-boot wording that still sounds like a one-off
  expedition instead of a multi-round mission.
