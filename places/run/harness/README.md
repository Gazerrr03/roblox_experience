# Run Harness

Create the initial run harness scaffold with:

```bash
rojo build places/run/default.project.json -o places/run/harness/run.rbxlx
```

Open `places/run/harness/run.rbxlx` in Roblox Studio and publish it only to the Run place.

After the scaffold exists, treat `places/run/harness/run.rbxlx` as the authored place file.

- Edit `Workspace/RunStaticWorld` directly in Studio.
- Do not rebuild the harness from Rojo unless you intentionally want to reset it back to the source scaffold.
- If you do need a reset, run `./scripts/build-harnesses.sh --force`.
- Follow [STATIC_WORLD.md](../STATIC_WORLD.md) for the required authored structure.
