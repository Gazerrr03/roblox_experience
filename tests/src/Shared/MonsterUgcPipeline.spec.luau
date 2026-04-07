return function()
    local ReplicatedStorage = game:GetService('ReplicatedStorage')
    local gameplay = require(ReplicatedStorage:WaitForChild('Packages'):WaitForChild('Gameplay'))

    local monsters = gameplay.Monsters
    local ugcPipeline = monsters.MonsterUgcPipeline
    local behaviorCatalog = monsters.MonsterBehaviorCatalog
    local effectCatalog = monsters.MonsterEffectCatalog

    local briefOk, waitingState = ugcPipeline.evaluateBrief({
        Goal = '',
        Experience = '压力追逐',
    })
    assert(briefOk == false, 'Incomplete briefs should request one follow-up question')
    assert(
        waitingState.Status == ugcPipeline.Status.WaitingForUser,
        'Incomplete briefs should surface waiting status'
    )
    assert(
        waitingState.MissingFields[1] == 'Goal',
        'Missing goal should be reported as the first blocking field'
    )

    local candidateBrief = {
        Prompt = '帮我做一个能追着玩家跑的金属幽灵',
        Goal = '持续追逐并制造路线压力',
        Experience = '玩家在拐角处持续感到紧张',
        Boundaries = {
            InScope = {
                '追逐与压迫感',
                '迷宫内巡逻点生成',
            },
            OutOfScope = {
                '群体协同 AI',
                '复杂技能树',
            },
        },
        SuccessCriteria = {
            '怪物在 5 秒内能识别最近目标并开始追逐',
        },
        Semantics = {
            Lore = '一团会吸收废铁噪音的幽灵，越靠近越令人不安。',
            Atmosphere = 'Dread',
            TriggerIntentSummary = '进入迷宫后会在活跃路线附近游走并追逐最近玩家。',
            CounterplayIntentSummary = '利用拐角切断视线并拉开距离重置仇恨。',
        },
        Preferences = {
            Name = 'Scrap Whisper',
            ModelAssetId = 4446576906,
            ChaseLoopSoundAssetId = 9118823108,
            Tuning = {
                Speed = 100,
                SightRange = 34,
                PatrolSpeedMultiplier = 0.5,
                SpawnOffset = Vector3.new(0, 9, 0),
            },
            BehaviorIntents = {
                {
                    Id = behaviorCatalog.Behavior.SenseNearestTarget,
                },
                {
                    Id = behaviorCatalog.Behavior.Chase,
                },
                {
                    Id = behaviorCatalog.Behavior.LoseTarget,
                },
            },
            EffectIntents = {
                {
                    Id = effectCatalog.Effect.SprintSuppressed,
                    DurationSeconds = 2.5,
                },
            },
        },
    }

    local policyChecks = {}
    local function assetValidator(assetId, assetKind)
        table.insert(policyChecks, string.format('%s:%d', assetKind, assetId))
        return true, 'PublicAssetAllowedInSandbox'
    end

    local generateOk, generationResult = ugcPipeline.generateForSandbox(candidateBrief, {
        Seed = 303,
        PlayerUserId = 42,
        AssetValidator = assetValidator,
        Now = function()
            return 1710000000
        end,
    })

    assert(generateOk == true, 'Valid briefs should generate sandbox-ready monster output')
    assert(
        generationResult.Status == ugcPipeline.Status.SandboxReady,
        'Successful generation should return sandbox-ready status'
    )
    assert(generationResult.Seed == 303, 'Explicit seed should be preserved for replayability')
    assert(
        type(generationResult.RecipeHash) == 'string' and generationResult.RecipeHash ~= '',
        'Generation should produce a non-empty recipe hash'
    )
    assert(
        generationResult.RuntimeProfile.Speed == ugcPipeline.TuningRange.Speed.Max,
        'Out-of-range speed should be clamped into allowed tuning range'
    )
    assert(
        generationResult.Diagnostics.SkippedBehaviorIds[1] == behaviorCatalog.Behavior.LoseTarget,
        'Known but non-maze behaviors should appear in compile skipped diagnostics'
    )
    assert(
        generationResult.Diagnostics.SkippedEffectIds[1] == effectCatalog.Effect.SprintSuppressed,
        'Known but non-maze effects should appear in compile skipped diagnostics'
    )
    assert(
        table.find(generationResult.Diagnostics.ClampedFields, 'Tuning.Speed') ~= nil,
        'Tuning diagnostics should report clamped numeric fields'
    )
    assert(
        table.find(generationResult.Diagnostics.ClampedFields, 'Tuning.SpawnOffset') ~= nil,
        'Unsafe spawn offsets should be clamped to a safe prefab value'
    )
    assert(
        generationResult.RuntimeProfile.Semantics == nil
            and generationResult.RuntimeProfile.TriggerIntent == nil,
        'Runtime profile should never leak authoring semantics'
    )
    assert(
        generationResult.Recipe.Meta.SourceByField['Semantics.TriggerIntent.Summary']
            == 'template_fill',
        'Recipe metadata should preserve field routing strategy'
    )
    assert(#policyChecks == 2, 'Both model and chase sound assets should run through policy checks')

    local generateAgainOk, generationAgainResult = ugcPipeline.generateForSandbox(candidateBrief, {
        Seed = 303,
        PlayerUserId = 42,
        AssetValidator = assetValidator,
        Now = function()
            return 1710000000
        end,
    })
    assert(generateAgainOk == true, 'Same inputs should keep the generator stable')
    assert(
        generationAgainResult.RecipeHash == generationResult.RecipeHash,
        'Same brief and same seed should produce the same recipe hash'
    )

    local rejectOk, rejectResult = ugcPipeline.generateForSandbox(candidateBrief, {
        Seed = 99,
        PlayerUserId = 42,
        AssetValidator = function(_, assetKind)
            if assetKind == 'ModelAssetId' then
                return false, 'BlockedByPolicy'
            end
            return true, 'Allowed'
        end,
    })

    assert(rejectOk == false, 'Rejected assets should fail generation')
    assert(
        rejectResult.Status == ugcPipeline.Status.Rejected,
        'Asset validation failures should return rejected status'
    )
    assert(
        rejectResult.RejectionCode == ugcPipeline.RejectionCode.AssetValidationFailed,
        'Asset validation failures should expose a dedicated rejection code'
    )

    local bundleOk, bundle = ugcPipeline.buildReviewBundle(generationResult, {
        EncounterCount = 3,
        AverageChaseSeconds = 8.4,
        PlayerReportCount = 0,
        AverageSurvivalSeconds = 42,
    }, {
        SubmittedByUserId = 42,
        Now = function()
            return 1710000420
        end,
    })

    assert(bundleOk == true, 'Sandbox-ready monsters should be bundleable for moderation')
    assert(bundle.Status == 'Pending', 'Review bundle should start in pending status')
    assert(
        bundle.Telemetry.EncounterCount == 3,
        'Review bundle should keep sanitized telemetry payload'
    )
end
