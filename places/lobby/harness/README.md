# Lobby Harness

Build or refresh the local harness file with:

```bash
rojo build places/lobby/default.project.json -o places/lobby/harness/lobby.rbxlx
```

Open `places/lobby/harness/lobby.rbxlx` in Roblox Studio and publish it only to the Lobby place.

When authoring local content, keep lobby-only geometry under `Workspace/LobbyStaticWorld` and follow [STATIC_WORLD.md](../STATIC_WORLD.md).
