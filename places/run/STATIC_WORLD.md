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
- `DoorLeft`
- `DoorRight`
- Root attribute `OutdoorThresholdZ`
  Defines the authored Z threshold between `Temple Hall` and `Wilderness`.

Rules:

- Keep all run-only geometry and prompts under `Workspace/RunStaticWorld`.
- `RunStaticWorld` is the only formal runtime source for the `run` place.
- `RunWorldBuilder` no longer generates fallback camp or wilderness geometry at runtime.
- Missing required markers, prompts, doors, or root attributes must fail loudly at runtime so content issues are fixed in Studio instead of hidden in code.
- `MazeGateMarker` is the run-to-maze transition object. Scene code only identifies it; cross-place teleport is handled by the dedicated transition layer.
