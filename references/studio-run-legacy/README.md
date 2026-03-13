# Studio Run Legacy Snapshot

Snapshot captured from the current Studio `Run` prototype on 2026-03-13.

## Legacy scripts

- `MazeGenerator.server.luau`
- `InteractionHandler.server.luau`

These files are backups only. They should not overwrite the new run skeleton.

## Prefab contract observed in Studio

The current run place contains three room prefabs under `ReplicatedStorage`:

- `RoomA`
  - `Doors` attribute: `North,South`
  - children: `Floor`, `WallNorth_L`, `WallNorth_R`, `WallSouth_L`, `WallSouth_R`, `WallEast`, `WallWest`
- `RoomB`
  - `Doors` attribute: `North,South,East`
  - children: `Floor`, `WallNorth_L`, `WallNorth_R`, `WallSouth_L`, `WallSouth_R`, `WallEast_L`, `WallEast_R`, `WallWest`
- `RoomC`
  - `Doors` attribute: `South`
  - children: `Floor`, `WallNorth`, `WallSouth_L`, `WallSouth_R`, `WallEast`, `WallWest`

## Migration intent

- keep `RoomA/B/C` as the first official room prefab set
- retire the legacy scripts after the new run session logic has taken over
- preserve this folder as rollback/reference material

