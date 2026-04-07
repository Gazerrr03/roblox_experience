local MonsterCompiler = require(script.MonsterCompiler)

return {
    MonsterComponentConfig = require(script.MonsterComponentConfig),
    Enemy = require(script.Enemy),
    EnemyBlackboard = require(script.EnemyBlackboard),
    EnemyStateMachine = require(script.EnemyStateMachine),
    MonsterAuthorProfile = require(script.MonsterAuthorProfile),
    MonsterBehaviorCatalog = require(script.MonsterBehaviorCatalog),
    MonsterCompiler = MonsterCompiler,
    MonsterEffectCatalog = require(script.MonsterEffectCatalog),
    MonsterLogic = require(script.MonsterLogic),
    MonsterPresentationCatalog = require(script.MonsterPresentationCatalog),
    MonsterUgcPipeline = require(script.MonsterUgcPipeline),
    MonsterUgcReviewQueue = require(script.MonsterUgcReviewQueue),
    MazeMonsterSpawnPolicy = require(script.MazeMonsterSpawnPolicy),
    MonsterRuntimeProfile = require(script.MonsterRuntimeProfile),
    compileMonsterForMaze = MonsterCompiler.compileMonsterForMaze,
}
