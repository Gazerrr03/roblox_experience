local MonsterCompiler = require(script.MonsterCompiler)

return {
    MonsterAuthorProfile = require(script.MonsterAuthorProfile),
    MonsterBehaviorCatalog = require(script.MonsterBehaviorCatalog),
    MonsterCompiler = MonsterCompiler,
    MonsterEffectCatalog = require(script.MonsterEffectCatalog),
    MonsterLogic = require(script.MonsterLogic),
    MazeMonsterSpawnPolicy = require(script.MazeMonsterSpawnPolicy),
    MonsterRuntimeProfile = require(script.MonsterRuntimeProfile),
    compileMonsterForMaze = MonsterCompiler.compileMonsterForMaze,
}
