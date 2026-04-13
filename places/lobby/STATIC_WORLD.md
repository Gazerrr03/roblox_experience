# Lobby Static World Contract

`LobbyStaticWorld` is the local authored content root for the `lobby` place.

Required authored parts:

- `SpawnMarker`
  Character spawn location for local Studio iteration.
- `ReadyPrompt`
  A `BasePart` with a `ProximityPrompt` that toggles the triggering player's ready state.
- `StartRunPrompt`
  A `BasePart` with a `ProximityPrompt` that launches the ready crew into `run`.

Rules:

- Keep all lobby-only geometry and prompts under `Workspace/LobbyStaticWorld`.
- `LobbyService` owns state and teleport behavior; authored content only provides positions and interaction surfaces.
- Missing required prompts must fail loudly at runtime so broken harness files are obvious.
