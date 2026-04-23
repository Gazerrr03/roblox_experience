## Monster Asset Sources

`assets/Monsters/` is the source-of-truth folder for monster import sources and import notes.

Rules:

- Keep raw import files here, not under `tmp/`.
- Do not map raw `.fbx` files directly into Rojo.
- Import models and animations into Roblox Studio through 3D Importer / Asset Manager.
- Store published Roblox asset IDs in code or in a nearby import note after upload.
- Prefer one folder per monster candidate or shipped monster.

Suggested structure:

```text
assets/Monsters/
  Mixamo/
    <monster-id>/
      source-fbx/
      README.md
```

For Mixamo-based monsters:

- Use one canonical character source for the visible model.
- Keep all actions downloaded from that same Mixamo character in the same monster folder.
- Treat `source-fbx/` as archival import sources, not runtime assets.
