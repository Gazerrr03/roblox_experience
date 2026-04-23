## old-man-monster-v1

This folder contains the Mixamo source files for the first custom humanoid monster candidate.

Source files live in:

- `source-fbx/`

Current canonical source choices:

- Canonical model import source: `Old Man Idle.fbx`
- Primary walk source: `Zombie Stumbling.fbx`
- Primary attack source: `Zombie Punching.fbx`
- Secondary locomotion candidate: `Wheelbarrow Walk.fbx`
- Future/non-v1 clips: `Surprised.fbx`, `Laying Breathless.fbx`

Planned runtime mapping:

```text
Idle   -> Old Man Idle
Walk   -> Zombie Stumbling
Run    -> Zombie Stumbling
Attack -> Zombie Punching
```

Studio import checklist:

1. Import `Old Man Idle.fbx` first and use it as the canonical monster model source.
2. Import the action clips against that same rig and publish Roblox animation assets.
3. Add a `Hit` marker to the imported `Zombie Punching` animation in Studio.
4. Fill the resulting asset IDs into monster presentation config:

```lua
Presentation = {
    ModelAssetId = <model_asset_id>,
    RigType = "CustomHumanoid",
    AnimationMode = "customHumanoid",
    AnimationAssetIds = {
        Idle = <idle_asset_id>,
        Walk = <walk_asset_id>,
        Run = <run_asset_id>,
        Attack = <attack_asset_id>,
    },
}
```

Notes:

- These files were downloaded with skin and are kept as source material.
- If locomotion drifts badly after import, re-download only the locomotion clip as in-place and replace the corresponding file in `source-fbx/`.
