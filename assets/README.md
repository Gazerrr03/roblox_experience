# Asset Pipeline

`assets/` is the source-of-truth folder for local reference files and import sources.

- Keep mockups, source textures, audio stems, and raw models here.
- Keep UI/scene prototype sources under `assets/prototypes/`.
- Import runtime assets into Roblox Studio through Asset Manager or 3D Importer.
- Reference imported assets from game code using `rbxgameasset://...` during local game development.
- Promote shared or published assets to `rbxassetid://...` only when they must be reused outside this experience.

Do not design any gameplay system around direct runtime reads from macOS local file paths.

