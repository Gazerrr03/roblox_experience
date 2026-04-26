# Maze Static World Contract

`MazeStaticWorld` is the local authored content root for the `maze` place.

Authoring workflow:

- `places/maze/harness/maze.rbxlx` is the everyday authoring source of truth.
- Open the harness in Studio and edit `Workspace/MazeStaticWorld` directly.
- Keep visible floors, walls, shell meshes, imported local assets, and other
  non-gameplay geometry under `Workspace/MazeStaticWorld/Scenery`.
- The overlay/chunk assets in `places/maze/assets/**` are scaffold/reset inputs;
  runtime only falls back to them when the authored root is missing.

Required root authored parts:

- `SpawnMarker`
  Player spawn point when entering the maze place.
- `ReturnHoldPad`
  A `BasePart` with a `ProximityPrompt` used for the maze's only formal return exit.

Authored room contract:

- Each room is a `Model` tagged `RoomType/<TypeId>`.
- Supported room metadata lives on Attributes such as `IsCamp`, `DifficultyTier`, `MonsterBudget`, `LootBudget`, `DetectionRadius`, `RoomTemplateId`, and `RoomCategory`.
- Supported authored room nodes include `MonsterSpawns/SpawnPoint_*`, `LootSocket_*`, `LootPrompt`, and `Doorway_*`.
- A formal authored maze must contain at least one room, one loot interaction, and one doorway.

Runtime behavior:

- `MazeWorldScanner` is the source of truth for the authored maze format and builds the world data consumed by `MazeSessionService`.
- Loot, return, and door interactions are bound from authored prompt parts instead of runtime-generated geometry.
- `MazeStaticWorld` is the only formal runtime source for the `maze` place.
- `MazeWorldBuilder` no longer falls back to runtime formal maze generation during place boot.
- `Run` handoff back from the maze is handled by a dedicated transition layer; scene objects only expose the authored return nodes.
- Runtime prefers an existing authored `Workspace/MazeStaticWorld` and only
  assembles a scaffold root when that authored root is absent.
