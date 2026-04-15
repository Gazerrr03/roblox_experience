# Run Terrain Collision Setup

## Architecture

The `run` place uses a **decoupled collision system**:

| Layer | Object | Role | Collision |
|-------|--------|------|-----------|
| Visual | `RunTerrain_Main.Scene.RunTerrain_OriginalHigh.RunTerrain_OriginalHighMesh` | Renders terrain texture/mesh | `CanCollide=false` |
| Collision | `Workspace.Scene_collision` (dedicated low-poly mesh) | Provides precise collision surface | `CanCollide=true`, `Transparency=1` |
| Native | `Workspace.Terrain` | Roblox built-in terrain | Present but not used for gameplay collision |

The dedicated collision mesh is a **56k-polygon low-poly** derived from the original high-poly terrain. It provides significantly better collision fidelity than Roblox's default convex decomposition while being lightweight enough for real-time physics.

## Collision Mesh Source File

**Location**: `places/run/assets/RunTerrain_CollisionMesh_LowPoly.glb`

This GLB file is the **source of truth** for the collision mesh. Commit it to git and re-import whenever an updated collision mesh is needed.

## Import Instructions

When setting up a new place or after pulling changes:

1. Open **Roblox Studio**
2. Open the `run` place (`places/run/default.project.json` via Rojo, or directly open `run.rbxlx`)
3. Go to **Asset Manager** (View → Asset Manager)
4. Click **Import** → navigate to `places/run/assets/RunTerrain_CollisionMesh_LowPoly.glb`
5. Wait for upload to complete; you will get an asset ID (e.g. `rbxassetid://XXXXXXXX`)
6. In the **Explorer**, find or create `Workspace.Scene_collision`:
   - If it does not exist: Right-click Workspace → Insert Object → **Model** → name it `Scene_collision`
   - Inside `Scene_collision`: Insert Object → **Model** → name it `RunTerrain_CollisionMesh_Node`
   - Inside `RunTerrain_CollisionMesh_Node`: Insert Object → **MeshPart**
7. Set the MeshPart's **MeshId** to the uploaded asset ID
8. Apply the **Properties Checklist** below

## Properties Checklist

After importing or when reviewing the collision mesh, verify these properties on `Workspace.Scene_collision.RunTerrain_CollisionMesh_Node.RunTerrain_CollisionMesh`:

| Property | Expected Value | Why |
|----------|---------------|-----|
| `CanCollide` | `true` | Must be true for collision detection |
| `Anchored` | `true` | Must not move or fall |
| `Transparency` | `1` | Fully invisible — only collision |
| `CollisionFidelity` | `PreciseConvexDecomposition` | Uses actual mesh triangles for collision |
| `Position` | Matches visual terrain: `(≈0, ≈47, ≈0)` | Must align with visual terrain |

## Adding New Content (Vegetation, Buildings)

When adding vegetation, props, or buildings to the terrain:

### Rule 1: New parts should have `CanCollide = false` by default

Unless the object explicitly needs to block player movement (e.g. walls, floors, obstacles), set `CanCollide = false`. This prevents interference with the spawn ground raycast validation.

### Rule 2: If you need physics interaction, use CollisionGroup or RaycastFilter

For objects that need collision but should not block spawn ground checks, add them to a **CollisionGroup** or include them in the spawn raycast filter. See `RunWorldBuilder.luau` for how `buildSpawnGroundParams` is constructed.

### Rule 3: Do not move or edit `Scene_collision`

The collision mesh is a **read-only base**. If you need a different collision shape, consult the team before modifying the GLB source and re-exporting.

## Troubleshooting

### Error: "Scene_collision not found"

The collision mesh is missing from the workspace. Re-import from `places/run/assets/RunTerrain_CollisionMesh_LowPoly.glb` following the import instructions above.

### Error: "Visual terrain has CanCollide=true"

Someone accidentally enabled collision on the visual terrain mesh. Fix: In Studio, select `RunTerrain_Main.Scene.RunTerrain_OriginalHigh.RunTerrain_OriginalHighMesh` and set `CanCollide = false`.

### Error: "SpawnMarker must raycast onto..."

The spawn ground raycast cannot find a valid surface. Check:
1. `Scene_collision` is present and `CanCollide = true`
2. Visual terrain `CanCollide = false` (not interfering)
3. The spawn marker is positioned above the terrain surface

### Floating / sinking feeling when walking

The collision mesh Y position may need adjustment. It is currently tuned to minimize floating vs. sinking. If adjustments are needed, move `Scene_collision.RunTerrain_CollisionMesh_Node.RunTerrain_CollisionMesh` by small increments (1-2 studs) and playtest.
