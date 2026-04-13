# Maze Harness

Create the initial maze harness scaffold with:

```bash
rojo build places/maze/default.project.json -o places/maze/harness/maze.rbxlx
```

Open `places/maze/harness/maze.rbxlx` in Roblox Studio and publish it only to the Maze place.

After the scaffold exists, treat `places/maze/harness/maze.rbxlx` as the authored place file.

- Edit `Workspace/MazeStaticWorld` directly in Studio.
- Do not rebuild the harness from Rojo unless you intentionally want to reset it back to the source scaffold.
- If you do need a reset, run `./scripts/build-harnesses.sh --force`.
- Follow [STATIC_WORLD.md](../STATIC_WORLD.md) for the required authored structure.
