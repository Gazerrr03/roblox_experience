# Maze Harness

Create or reset the Maze harness with:

```bash
./scripts/build-harnesses.sh --force
```

Open `places/maze/harness/maze.rbxlx` in Roblox Studio and publish it only to the Maze place.

The reset scaffold hydrates `Workspace/MazeStaticWorld` from the Maze overlay
and chunk assets so the harness opens with visible scenery in Studio.

After the scaffold exists, treat `places/maze/harness/maze.rbxlx` as the
authored place file and source of truth for Maze world layout.

- Edit `Workspace/MazeStaticWorld` directly in Studio.
- Keep formal static map geometry under `Workspace/MazeStaticWorld/Scenery`.
- Do not rebuild the harness unless you intentionally want to reset it back to
  the source scaffold.
- If you do need a reset, run `./scripts/build-harnesses.sh --force`.
- Follow [STATIC_WORLD.md](../STATIC_WORLD.md) for the required authored structure.
- Follow [CONTENT_TEST_PLAN.md](../CONTENT_TEST_PLAN.md) for the current Maze content validation checklist before importing external map assets.
