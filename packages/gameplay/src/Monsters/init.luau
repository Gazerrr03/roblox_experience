local MonsterCompiler = require(script.MonsterCompiler)

return {
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
