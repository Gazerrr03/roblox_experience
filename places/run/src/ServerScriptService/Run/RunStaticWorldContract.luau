local RunStaticWorldContract = table.freeze({
    RootName = 'RunStaticWorld',
    CollisionRootName = 'Collision',
    SceneCollisionName = 'Scene',
    ShipCollisionName = 'Ship',
    TriggersRootName = 'Triggers',
    OceanTriggerName = 'Ocean',
    BuildFingerprint = 'run-collision-contract-v2',
    SpawnGroundCheckDepth = 32,
    SpawnLiftStuds = 4,
    OceanSplashCooldownSeconds = 1.5,
})

return RunStaticWorldContract
