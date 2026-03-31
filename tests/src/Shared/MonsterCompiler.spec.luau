return function()
    local ReplicatedStorage = game:GetService('ReplicatedStorage')
    local gameplay = require(ReplicatedStorage:WaitForChild('Packages'):WaitForChild('Gameplay'))

    local compiler = gameplay.Monsters.compileMonsterForMaze
    local behaviorCatalog = gameplay.Monsters.MonsterBehaviorCatalog
    local effectCatalog = gameplay.Monsters.MonsterEffectCatalog
    local authorProfileModule = gameplay.Monsters.MonsterAuthorProfile
    local presentationCatalog = gameplay.Monsters.MonsterPresentationCatalog
    local runtimeProfileModule = gameplay.Monsters.MonsterRuntimeProfile

    local scrapWisp = gameplay.Config.Monsters[1]
    local errorCategory = authorProfileModule.ErrorCategory

    local function buildLegacyProfile(layeredProfile)
        return {
            Id = layeredProfile.Id,
            Name = layeredProfile.Name,
            Lore = layeredProfile.Semantics.Lore,
            Atmosphere = layeredProfile.Semantics.Atmosphere,
            TriggerIntent = table.clone(layeredProfile.Semantics.TriggerIntent),
            CounterplayIntent = table.clone(layeredProfile.Semantics.CounterplayIntent),
            NumericProfile = table.clone(layeredProfile.Tuning),
            BehaviorIntents = table.clone(layeredProfile.Executable.BehaviorIntents),
            EffectIntents = table.clone(layeredProfile.Executable.EffectIntents),
        }
    end

    local validAuthorProfile, normalizedProfile = authorProfileModule.validate(scrapWisp)
    assert(
        validAuthorProfile == true,
        string.format('Expected valid author profile, got %s', tostring(normalizedProfile))
    )
    assert(
        normalizedProfile.SchemaMode == 'Layered',
        'Layered config should normalize into the layered schema mode'
    )

    local compileOk, runtimeProfile, compileReport = compiler(scrapWisp)
    assert(compileOk == true, string.format('Expected compiler success, got %s', runtimeProfile))

    local validRuntimeProfile, runtimeReason = runtimeProfileModule.validate(runtimeProfile)
    assert(
        validRuntimeProfile == true,
        string.format('Expected valid runtime profile, got %s', runtimeReason)
    )

    assert(runtimeProfile.Id == 'scrap-wisp', 'Compiled runtime should preserve the monster id')
    assert(runtimeProfile.Name == 'Scrap Wisp', 'Compiled runtime should preserve the monster name')
    assert(
        runtimeProfile.Presentation.ModelAssetId == 4446576906,
        'Compiled runtime should expose the configured model asset id'
    )
    assert(
        runtimeProfile.Presentation.RigType == presentationCatalog.RigType.R6,
        'Compiled runtime should preserve the configured rig type'
    )
    assert(
        runtimeProfile.Presentation.AnimationMode == presentationCatalog.AnimationMode.DefaultR6,
        'Compiled runtime should preserve the configured animation mode'
    )
    assert(
        runtimeProfile.Presentation.ChaseLoopSoundAssetId == 9118823108,
        'Compiled runtime should expose the configured chase loop sound asset id'
    )
    assert(runtimeProfile.Speed == 14, 'Compiled runtime should expose the configured speed')
    assert(
        runtimeProfile.SightRange == 36,
        'Compiled runtime should expose the configured sight range'
    )
    assert(
        runtimeProfile.PatrolSpeedMultiplier == 0.45,
        'Compiled runtime should expose the configured patrol speed multiplier'
    )
    assert(
        runtimeProfile.Behaviors[behaviorCatalog.Behavior.Patrol] == nil,
        'Disabled patrol intents should not reach the maze runtime profile'
    )
    assert(
        runtimeProfile.Behaviors[behaviorCatalog.Behavior.SenseNearestTarget] == true,
        'Nearest-target sensing should stay enabled in the maze runtime profile'
    )
    assert(
        runtimeProfile.Behaviors[behaviorCatalog.Behavior.Chase] == true,
        'Chase should stay enabled in the maze runtime profile'
    )
    assert(
        runtimeProfile.Behaviors[behaviorCatalog.Behavior.LoseTarget] == nil,
        'Known but not-yet-enabled behaviors should be excluded from the runtime profile'
    )
    assert(
        runtimeProfile.Lore == nil,
        'Authoring-only fields should not leak into the runtime profile'
    )
    assert(
        runtimeProfile.TriggerIntent == nil and runtimeProfile.Semantics == nil,
        'Semantic authoring fields should never leak into the runtime profile'
    )
    assert(
        #runtimeProfile.Effects == 0,
        'Known but not-yet-enabled effects should be excluded from the runtime profile'
    )
    assert(
        compileReport.SchemaMode == 'Layered',
        'Compile report should expose the layered schema mode'
    )
    assert(
        #compileReport.Warnings == 0,
        'Layered schema compiles should not emit deprecation warnings'
    )
    assert(
        #compileReport.SkippedBehaviorIds == 1
            and compileReport.SkippedBehaviorIds[1] == behaviorCatalog.Behavior.LoseTarget,
        'Compiler should report maze-skipped behavior intents'
    )
    assert(
        #compileReport.SkippedEffectIds == 1
            and compileReport.SkippedEffectIds[1] == effectCatalog.Effect.SprintSuppressed,
        'Compiler should report maze-skipped effect intents'
    )

    local legacyProfile = buildLegacyProfile(scrapWisp)
    local legacyCompileOk, legacyRuntimeProfile, legacyCompileReport = compiler(legacyProfile)
    assert(legacyCompileOk == true, 'Legacy flat profiles should still compile during migration')
    assert(
        legacyRuntimeProfile.Speed == runtimeProfile.Speed
            and legacyRuntimeProfile.SightRange == runtimeProfile.SightRange,
        'Legacy and layered schema compiles should produce equivalent runtime output'
    )
    assert(
        legacyCompileReport.SchemaMode == 'LegacyFlat',
        'Legacy compiles should report legacy schema mode'
    )
    assert(
        #legacyCompileReport.Warnings == 1
            and legacyCompileReport.Warnings[1] == 'DeprecatedLegacySchema',
        'Legacy compiles should emit the deprecation warning'
    )

    local missingNameProfile = table.clone(scrapWisp)
    missingNameProfile.Name = nil

    local missingNameOk, missingNameReason = authorProfileModule.validate(missingNameProfile)
    assert(missingNameOk == false, 'Missing names should fail author profile validation')
    assert(missingNameReason == 'MissingName', 'Missing names should expose the expected reason')

    local missingPresentationProfile = table.clone(scrapWisp)
    missingPresentationProfile.Presentation = nil

    local missingPresentationOk, missingPresentationReason =
        authorProfileModule.validate(missingPresentationProfile)
    assert(
        missingPresentationOk == false,
        'Missing presentation payloads should fail author profile validation'
    )
    assert(
        missingPresentationReason == 'MissingPresentation',
        'Missing presentation payloads should expose the expected reason'
    )

    local unknownBehaviorProfile = table.clone(scrapWisp)
    unknownBehaviorProfile.Executable = table.clone(scrapWisp.Executable)
    unknownBehaviorProfile.Executable.BehaviorIntents = {
        {
            Id = 'UnknownBehavior',
        },
    }

    local unknownBehaviorOk, unknownBehaviorReason =
        authorProfileModule.validate(unknownBehaviorProfile)
    assert(unknownBehaviorOk == false, 'Unknown behavior intents should fail validation')
    assert(
        unknownBehaviorReason == 'UnknownBehaviorIntent',
        'Unknown behavior intents should expose the expected reason'
    )

    local invalidEffectProfile = table.clone(scrapWisp)
    invalidEffectProfile.Executable = table.clone(scrapWisp.Executable)
    invalidEffectProfile.Executable.EffectIntents = {
        {
            Id = effectCatalog.Effect.SprintSuppressed,
        },
    }

    local invalidEffectOk, invalidEffectReason = authorProfileModule.validate(invalidEffectProfile)
    assert(invalidEffectOk == false, 'Invalid effect payloads should fail validation')
    assert(
        invalidEffectReason == 'InvalidEffectPayload',
        'Invalid effect payloads should expose the expected reason'
    )

    local compileFailureOk, compileFailureReason, compileFailureDiagnostic =
        compiler(invalidEffectProfile)
    assert(compileFailureOk == false, 'Compiler should reject invalid authoring profiles')
    assert(
        compileFailureReason == 'InvalidEffectPayload',
        'Compiler should surface the authoring validation failure reason'
    )
    assert(
        compileFailureDiagnostic.Category == errorCategory.Schema,
        'Invalid payloads should surface schema diagnostics'
    )

    local boundaryProfile = table.clone(scrapWisp)
    boundaryProfile.Executable = table.clone(scrapWisp.Executable)
    boundaryProfile.Executable.TriggerIntent = {
        Summary = 'Should never be executable',
    }

    local boundaryCompileOk, boundaryReason, boundaryDiagnostic = compiler(boundaryProfile)
    assert(
        boundaryCompileOk == false,
        'Executable sections that contain semantic fields should fail fast'
    )
    assert(
        boundaryReason == 'BoundaryExecutableContainsNonExecutableField',
        'Boundary violations should expose a dedicated boundary reason'
    )
    assert(
        boundaryDiagnostic.Category == errorCategory.Boundary,
        'Boundary violations should classify as boundary diagnostics'
    )
end
