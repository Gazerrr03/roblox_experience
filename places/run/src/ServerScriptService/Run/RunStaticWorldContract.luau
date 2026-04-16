local RunStaticWorldContract = table.freeze({
    RootName = 'RunStaticWorld',
    CollisionRootName = 'Collision',
    SceneCollisionName = 'Scene',
    ShipCollisionName = 'Ship',
    TriggersRootName = 'Triggers',
    OceanTriggerName = 'Ocean',
    BuildFingerprint = 'run-collision-contract-v3',
    SpawnGroundCheckDepth = 32,
    SpawnLiftStuds = 4,
    OceanSplashCooldownSeconds = 1.5,

    -- Collision mesh (dedicated low-poly collision, visually transparent)
    -- Lives at Workspace.Scene_collision (sibling of RunStaticWorld)
    CollisionMeshContract = table.freeze({
        Name = 'Scene_collision',
        MeshPartName = 'RunTerrain_CollisionMesh',
        NodeName = 'RunTerrain_CollisionMesh_Node',
        ExpectedCollisionFidelity = Enum.CollisionFidelity.PreciseConvexDecomposition,
        ExpectedTransparency = 1,
        ExpectedCanCollide = true,
        ExpectedAnchored = true,
    }),

    -- Visual terrain (texture/mesh only, collision handled by CollisionMeshContract)
    VisualTerrainContract = table.freeze({
        RootName = 'RunTerrain_Main',
        SceneFolderName = 'Scene',
        TerrainGroupName = 'RunTerrain_OriginalHigh',
        MeshPartName = 'RunTerrain_OriginalHighMesh',
        ExpectedCanCollide = false,
        ExpectedTransparency = 0,
    }),
})

return RunStaticWorldContract
