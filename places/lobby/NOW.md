# Lobby NOW

## Current Focus

- Keep lobby intentionally thin while the rest of the multi-place flow settles.
- Treat lobby as the launch adapter into run, not as a place that owns run or
  maze state.

## Open Questions

- Whether lobby should eventually gain a dedicated local portal adapter module,
  matching the direction explored on `origin/contract`
- How much crew or session preview should remain in lobby versus moving into run

## Temporary Exceptions

- None currently.

## Near-Term Cleanup

- If the lobby-to-run handoff grows further, extract the teleport boundary into
  a local adapter instead of expanding `LobbyService` indefinitely.
