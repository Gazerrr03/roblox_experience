# Maze Static World Contract

`MazeStaticWorld` is the local authored content root for the `maze` place.

Required root authored parts:

- `SpawnMarker`
  Player spawn point when entering the maze place.
- `ReturnHoldPad`
  A `BasePart` with a `ProximityPrompt` used when players return early or when run handoff fails.

Authored room contract:

- Each room is a `Model` tagged `RoomType/<TypeId>`.
- Supported room metadata lives on Attributes such as `IsCamp`, `IsExtraction`, `DifficultyTier`, `MonsterBudget`, `LootBudget`, `DetectionRadius`, `RoomTemplateId`, and `RoomCategory`.
- Supported authored child parts include `SpawnPoint_*`, `LootSocket_*`, `LootPrompt`, `Doorway_*`, and `ExtractionMarker`.
- A formal authored maze must contain at least one room, one loot interaction, one doorway, and one extraction marker.

Runtime behavior:

- `MazeWorldScanner` is the source of truth for the authored maze format and builds the world data consumed by `MazeSessionService`.
- Loot, extraction, and door interactions are bound from authored prompt parts instead of runtime-generated geometry.
- `MazeStaticWorld` is the only formal runtime source for the `maze` place.
- `MazeWorldBuilder` no longer falls back to runtime formal maze generation during place boot.
- `Run` handoff back from the maze is handled by a dedicated transition layer; scene objects only expose the authored return nodes.
