# Run Static World Contract

`RunStaticWorld` is the local authored content root for the `run` place.

Required authored parts with `ProximityPrompt`s:

- `ShopTerminal`
- `SalvageTerminal`
- `ObjectiveBoard`
- `LoadoutBench`
- `UgcLabConsole`
- `GateSwitch`
- `MazeGateMarker`

Required markers:

- `SpawnMarker`
- `ReturnMarker`
- `MazeReturnMarker`
- Root attribute `OutdoorThresholdZ`
  Defines the authored Z threshold between `Temple Hall` and `Wilderness`.

Required authored collision structure:

- `Collision/Scene`

Optional authored collision structure:

- `Collision/Ship`

Required authored trigger structure:

- `Triggers/Ocean`

Rules:

- Keep all run-only geometry and prompts under `Workspace/RunStaticWorld`.
- `RunStaticWorld` is the only formal runtime source for the `run` place.
- `RunWorldBuilder` no longer generates fallback camp or wilderness geometry at runtime.
- `Collision/Scene` must contain invisible anchored collision shells.
- `Collision/Ship`, when authored, must also contain invisible anchored collision shells.
- Collision shell parts must use `Anchored=true`, `CanCollide=true`, `CanTouch=false`, `CanQuery=true`, and `Transparency=1`.
- `Triggers/Ocean` must contain invisible anchored non-collidable trigger parts for water-entry feedback.
- Missing required markers, prompts, or root attributes must fail loudly at runtime so content issues are fixed in Studio instead of hidden in code.
- `SpawnMarker` must have a collidable authored floor within 32 studs below it.
- `MazeGateMarker` is the run-to-maze transition object. Scene code only identifies it; cross-place teleport is handled by the dedicated transition layer.
- `GateSwitch` only advances gate-open state; the run place no longer depends on top-level `DoorLeft` / `DoorRight` parts for temple-door animation.
- Flyship door interaction is provided by `ServerScriptService/Run/ShipDoors.luau`; do not keep a separate embedded `ShipDoors` Workspace script under the dropship model.
