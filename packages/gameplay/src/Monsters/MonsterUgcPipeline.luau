local MonsterBehaviorCatalog = require(script.Parent.MonsterBehaviorCatalog)
local MonsterCompiler = require(script.Parent.MonsterCompiler)
local MonsterEffectCatalog = require(script.Parent.MonsterEffectCatalog)
local MonsterAssetIds = require(script.Parent.MonsterAssetIds)
local MonsterPresentationCatalog = require(script.Parent.MonsterPresentationCatalog)

local MonsterUgcPipeline = {}

MonsterUgcPipeline.Status = table.freeze({
    WaitingForUser = 'waiting_for_user',
    ReadyToGenerate = 'ready_to_generate',
    SandboxReady = 'sandbox_ready',
    Rejected = 'rejected',
})

MonsterUgcPipeline.RejectionCode = table.freeze({
    MalformedBrief = 'MalformedBrief',
    MissingBriefFields = 'MissingBriefFields',
    UnknownBehaviorIntent = 'UnknownBehaviorIntent',
    InvalidEffectIntent = 'InvalidEffectIntent',
    AssetValidationFailed = 'AssetValidationFailed',
    CompileFailed = 'CompileFailed',
    InvalidGenerationResult = 'InvalidGenerationResult',
})

MonsterUgcPipeline.TuningRange = table.freeze({
    Speed = table.freeze({ Min = 8, Max = 20 }),
    SightRange = table.freeze({ Min = 20, Max = 60 }),
    PatrolSpeedMultiplier = table.freeze({ Min = 0.2, Max = 0.9 }),
})

local DEFAULT_ASSET_IDS = table.freeze({
    ModelAssetId = MonsterAssetIds.DefaultModelAssetId,
    ChaseLoopSoundAssetId = MonsterAssetIds.DefaultChaseLoopSoundAssetId,
})

local DEFAULT_PREFAB_ID = 'stalker-hunt'

local TUNING_PREFABS = table.freeze({
    ['stalker-hunt'] = table.freeze({
        Speed = 14,
        SightRange = 36,
        PatrolSpeedMultiplier = 0.45,
        SpawnOffset = Vector3.new(0, 4, 0),
    }),
    ['ambusher-rush'] = table.freeze({
        Speed = 16,
        SightRange = 30,
        PatrolSpeedMultiplier = 0.35,
        SpawnOffset = Vector3.new(0, 4, 0),
    }),
    ['bruiser-pressure'] = table.freeze({
        Speed = 11,
        SightRange = 32,
        PatrolSpeedMultiplier = 0.5,
        SpawnOffset = Vector3.new(0, 4, 0),
    }),
})

local BEHAVIOR_PREFABS = table.freeze({
    ['stalker-hunt'] = table.freeze({
        {
            Id = MonsterBehaviorCatalog.Behavior.Patrol,
            Enabled = false,
        },
        {
            Id = MonsterBehaviorCatalog.Behavior.SenseNearestTarget,
        },
        {
            Id = MonsterBehaviorCatalog.Behavior.Chase,
        },
        {
            Id = MonsterBehaviorCatalog.Behavior.LoseTarget,
        },
    }),
    ['ambusher-rush'] = table.freeze({
        {
            Id = MonsterBehaviorCatalog.Behavior.Patrol,
        },
        {
            Id = MonsterBehaviorCatalog.Behavior.SenseNearestTarget,
        },
        {
            Id = MonsterBehaviorCatalog.Behavior.Chase,
        },
    }),
    ['bruiser-pressure'] = table.freeze({
        {
            Id = MonsterBehaviorCatalog.Behavior.SenseNearestTarget,
        },
        {
            Id = MonsterBehaviorCatalog.Behavior.Chase,
        },
        {
            Id = MonsterBehaviorCatalog.Behavior.Attack,
        },
    }),
})

local EFFECT_PREFABS = table.freeze({
    ['stalker-hunt'] = table.freeze({
        {
            Id = MonsterEffectCatalog.Effect.DamageLight,
        },
    }),
    ['ambusher-rush'] = table.freeze({
        {
            Id = MonsterEffectCatalog.Effect.DamageLight,
        },
    }),
    ['bruiser-pressure'] = table.freeze({
        {
            Id = MonsterEffectCatalog.Effect.DamageHeavy,
        },
    }),
})

local ATMOSPHERE_PREFAB_MAP = table.freeze({
    Dread = 'stalker-hunt',
    Horror = 'stalker-hunt',
    Tense = 'stalker-hunt',
    Rush = 'ambusher-rush',
    Pressure = 'bruiser-pressure',
    Brutal = 'bruiser-pressure',
})

local SAFE_SPAWN_OFFSETS = table.freeze({
    Vector3.new(0, 4, 0),
    Vector3.new(0, 3, 0),
    Vector3.new(0, 5, 0),
})

local CLARIFYING_QUESTION_BY_FIELD = table.freeze({
    Goal = '这个怪物的核心目标是什么？例如压迫追逐、区域封锁或团队分割。',
    Experience = '你希望玩家遇到它时，最强烈的体验感受是什么？',
    ['Semantics.Lore'] = '给这个怪物补一段背景描述（1-2句即可）。',
    ['Semantics.Atmosphere'] = '这个怪物更偏向哪种氛围？例如 Dread、Rush 或 Brutal。',
    ['Semantics.TriggerIntentSummary'] = '它会在什么条件下主动进入追击？',
    ['Semantics.CounterplayIntentSummary'] = '玩家可以通过什么方式与它周旋或反制？',
    SuccessCriteria = '成功标准是什么？至少给出一条可观察的验收条件。',
})

local function trimText(value)
    if type(value) ~= 'string' then
        return ''
    end

    return string.match(value, '^%s*(.-)%s*$') or ''
end

local function normalizeStringList(values)
    if type(values) ~= 'table' then
        return {}
    end

    local normalized = {}
    for _, value in ipairs(values) do
        local text = trimText(value)
        if text ~= '' then
            table.insert(normalized, text)
        end
    end

    return normalized
end

local function cloneShallowTable(values)
    return table.clone(values)
end

local function deepFreeze(value, seen)
    if type(value) ~= 'table' then
        return value
    end

    if table.isfrozen(value) then
        return value
    end

    local visited = seen or {}
    if visited[value] then
        return value
    end
    visited[value] = true

    for _, nested in pairs(value) do
        deepFreeze(nested, visited)
    end

    table.freeze(value)
    return value
end

local function sanitizeName(value)
    local text = trimText(value)
    if text == '' then
        return ''
    end

    text = string.gsub(text, '[%c\n\r\t]', ' ')
    text = string.gsub(text, '%s+', ' ')
    text = trimText(text)

    if #text > 48 then
        text = string.sub(text, 1, 48)
    end

    return text
end

local function nextClarifyingQuestion(missingField)
    return CLARIFYING_QUESTION_BY_FIELD[missingField]
        or '为了继续生成怪物，请先补充缺失字段：' .. tostring(missingField)
end

local function normalizeBrief(rawBrief)
    if type(rawBrief) ~= 'table' then
        return nil, { 'Brief' }
    end

    local semantics = rawBrief.Semantics
    local boundaries = rawBrief.Boundaries
    local preferences = rawBrief.Preferences

    local brief = {
        Prompt = trimText(rawBrief.Prompt),
        Goal = trimText(rawBrief.Goal),
        Experience = trimText(rawBrief.Experience),
        Boundaries = {
            InScope = normalizeStringList(boundaries and boundaries.InScope),
            OutOfScope = normalizeStringList(boundaries and boundaries.OutOfScope),
        },
        SuccessCriteria = normalizeStringList(rawBrief.SuccessCriteria),
        Semantics = {
            Lore = trimText(semantics and semantics.Lore),
            Atmosphere = trimText(semantics and semantics.Atmosphere),
            TriggerIntentSummary = trimText(semantics and semantics.TriggerIntentSummary),
            CounterplayIntentSummary = trimText(semantics and semantics.CounterplayIntentSummary),
        },
        Preferences = {
            Name = sanitizeName(preferences and preferences.Name),
            ModelAssetId = if preferences then preferences.ModelAssetId else nil,
            ChaseLoopSoundAssetId = if preferences then preferences.ChaseLoopSoundAssetId else nil,
            BehaviorIntents = if preferences then preferences.BehaviorIntents else nil,
            EffectIntents = if preferences then preferences.EffectIntents else nil,
            Tuning = if preferences then preferences.Tuning else nil,
        },
    }

    if brief.Prompt == '' then
        brief.Prompt = brief.Goal
    end

    local missingFields = {}
    if brief.Goal == '' then
        table.insert(missingFields, 'Goal')
    end
    if brief.Experience == '' then
        table.insert(missingFields, 'Experience')
    end
    if brief.Semantics.Lore == '' then
        table.insert(missingFields, 'Semantics.Lore')
    end
    if brief.Semantics.Atmosphere == '' then
        table.insert(missingFields, 'Semantics.Atmosphere')
    end
    if brief.Semantics.TriggerIntentSummary == '' then
        table.insert(missingFields, 'Semantics.TriggerIntentSummary')
    end
    if brief.Semantics.CounterplayIntentSummary == '' then
        table.insert(missingFields, 'Semantics.CounterplayIntentSummary')
    end
    if #brief.SuccessCriteria == 0 then
        table.insert(missingFields, 'SuccessCriteria')
    end

    if #missingFields > 0 then
        return nil, missingFields
    end

    return deepFreeze(brief)
end

local function defaultAssetValidator(_assetId, _assetKind)
    return true, 'UncheckedAsset'
end

local function isSafeSpawnOffset(offset)
    if typeof(offset) ~= 'Vector3' then
        return false
    end

    for _, safeOffset in ipairs(SAFE_SPAWN_OFFSETS) do
        if safeOffset == offset then
            return true
        end
    end

    return false
end

local function normalizeIntentList(rawIntents)
    if type(rawIntents) ~= 'table' then
        return nil
    end

    local intents = {}
    for _, rawIntent in ipairs(rawIntents) do
        if type(rawIntent) == 'string' then
            table.insert(intents, { Id = rawIntent })
        elseif type(rawIntent) == 'table' then
            table.insert(intents, cloneShallowTable(rawIntent))
        else
            return nil
        end
    end

    return intents
end

local function clampNumber(value, minValue, maxValue)
    local clamped = math.clamp(value, minValue, maxValue)
    return clamped
end

local function applyRequestedTuning(baseTuning, requestedTuning, diagnostics, sourceByField)
    local tuning = cloneShallowTable(baseTuning)
    local tuningSource = if type(requestedTuning) == 'table' then 'prefab+micro_tune' else 'prefab'

    local function assignNumber(fieldName, minValue, maxValue)
        local requested = if type(requestedTuning) == 'table'
            then requestedTuning[fieldName]
            else nil
        local finalValue = tuning[fieldName]
        if type(requested) == 'number' then
            finalValue = clampNumber(requested, minValue, maxValue)
            if finalValue ~= requested then
                table.insert(diagnostics.ClampedFields, 'Tuning.' .. fieldName)
            end
        end

        tuning[fieldName] = finalValue
        sourceByField['Tuning.' .. fieldName] = tuningSource
    end

    assignNumber(
        'Speed',
        MonsterUgcPipeline.TuningRange.Speed.Min,
        MonsterUgcPipeline.TuningRange.Speed.Max
    )
    assignNumber(
        'SightRange',
        MonsterUgcPipeline.TuningRange.SightRange.Min,
        MonsterUgcPipeline.TuningRange.SightRange.Max
    )
    assignNumber(
        'PatrolSpeedMultiplier',
        MonsterUgcPipeline.TuningRange.PatrolSpeedMultiplier.Min,
        MonsterUgcPipeline.TuningRange.PatrolSpeedMultiplier.Max
    )

    local requestedSpawnOffset = if type(requestedTuning) == 'table'
        then requestedTuning.SpawnOffset
        else nil
    if requestedSpawnOffset ~= nil then
        if isSafeSpawnOffset(requestedSpawnOffset) then
            tuning.SpawnOffset = requestedSpawnOffset
            sourceByField['Tuning.SpawnOffset'] = 'prefab+micro_tune'
        else
            table.insert(diagnostics.ClampedFields, 'Tuning.SpawnOffset')
            sourceByField['Tuning.SpawnOffset'] = 'prefab_safe_offset'
        end
    else
        sourceByField['Tuning.SpawnOffset'] = 'prefab'
    end

    return tuning
end

local function normalizeBehaviorIntents(rawBehaviorIntents)
    local behaviorIntents = normalizeIntentList(rawBehaviorIntents)
    if behaviorIntents == nil then
        return false, 'MalformedBehaviorIntent'
    end

    for _, intent in ipairs(behaviorIntents) do
        if type(intent.Id) ~= 'string' or intent.Id == '' then
            return false, 'MissingBehaviorIntentId'
        end
        if not MonsterBehaviorCatalog.Known[intent.Id] then
            return false, 'UnknownBehaviorIntent'
        end
    end

    return true, behaviorIntents
end

local function normalizeEffectIntents(rawEffectIntents)
    local effectIntents = normalizeIntentList(rawEffectIntents)
    if effectIntents == nil then
        return false, 'MalformedEffectIntent'
    end

    for _, effectIntent in ipairs(effectIntents) do
        local validEffectIntent, reason = MonsterEffectCatalog.validateIntent(effectIntent)
        if not validEffectIntent then
            return false, reason
        end
    end

    return true, effectIntents
end

local function validateAsset(assetId, assetKind, assetValidator, diagnostics)
    if assetId == nil then
        diagnostics.AssetChecks[assetKind] = {
            Status = 'Skipped',
            Reason = 'NoAssetRequested',
        }
        return true
    end

    if type(assetId) ~= 'number' or assetId <= 0 then
        diagnostics.AssetChecks[assetKind] = {
            Status = 'Rejected',
            Reason = 'InvalidAssetId',
        }
        return false, 'InvalidAssetId'
    end

    local ok, allowed, reason = pcall(assetValidator, assetId, assetKind)
    if not ok then
        diagnostics.AssetChecks[assetKind] = {
            AssetId = assetId,
            Status = 'Rejected',
            Reason = 'AssetValidatorError',
        }
        return false, 'AssetValidatorError'
    end

    if allowed ~= true then
        diagnostics.AssetChecks[assetKind] = {
            AssetId = assetId,
            Status = 'Rejected',
            Reason = reason or 'AssetPolicyRejected',
        }
        return false, reason or 'AssetPolicyRejected'
    end

    diagnostics.AssetChecks[assetKind] = {
        AssetId = assetId,
        Status = 'Pass',
        Reason = reason or 'AssetPolicyPass',
    }
    return true
end

local function normalizeSeed(seed)
    if type(seed) ~= 'number' then
        seed = Random.new():NextInteger(1, 2147483646)
    end

    local normalizedSeed = math.floor(math.abs(seed))
    if normalizedSeed <= 0 then
        normalizedSeed = 1
    end

    return normalizedSeed
end

local function buildMonsterName(brief, rng)
    local preferredName = brief.Preferences.Name
    if preferredName ~= '' then
        return preferredName, 'template_fill'
    end

    local goalSnippet = sanitizeName(brief.Goal)
    if goalSnippet ~= '' then
        local titlePool = {
            'Wisp',
            'Hunter',
            'Stalker',
            'Shade',
        }
        local title = titlePool[rng:NextInteger(1, #titlePool)]
        local fallbackName = string.format('%s %s', goalSnippet, title)
        return sanitizeName(fallbackName), 'template_fill'
    end

    return 'UGC Wisp', 'template_fill'
end

local function buildMonsterId(playerUserId, seed)
    local owner = if type(playerUserId) == 'number' and playerUserId > 0 then playerUserId else 0
    return string.format('ugc-%d-%d', owner, seed)
end

local function buildBehaviorIntents(prefabId, brief, sourceByField)
    local requestedBehaviorIntents = brief.Preferences.BehaviorIntents
    if requestedBehaviorIntents ~= nil then
        local behaviorOk, normalizedBehaviorIntents =
            normalizeBehaviorIntents(requestedBehaviorIntents)
        if not behaviorOk then
            return false, normalizedBehaviorIntents
        end

        sourceByField['Executable.BehaviorIntents'] = 'prefab_template_fill'
        return true, normalizedBehaviorIntents
    end

    sourceByField['Executable.BehaviorIntents'] = 'prefab'
    return true, normalizeIntentList(BEHAVIOR_PREFABS[prefabId])
end

local function buildEffectIntents(prefabId, brief, sourceByField)
    local requestedEffectIntents = brief.Preferences.EffectIntents
    if requestedEffectIntents ~= nil then
        local effectOk, normalizedEffectIntents = normalizeEffectIntents(requestedEffectIntents)
        if not effectOk then
            return false, normalizedEffectIntents
        end

        sourceByField['Executable.EffectIntents'] = 'prefab_template_fill'
        return true, normalizedEffectIntents
    end

    sourceByField['Executable.EffectIntents'] = 'prefab'
    return true, normalizeIntentList(EFFECT_PREFABS[prefabId])
end

local function buildRecipeHash(recipe)
    local hashInputParts = {
        recipe.Id,
        recipe.Name,
        recipe.Semantics.Atmosphere,
        recipe.Semantics.Lore,
        string.format('%.4f', recipe.Tuning.Speed),
        string.format('%.4f', recipe.Tuning.SightRange),
        string.format('%.4f', recipe.Tuning.PatrolSpeedMultiplier),
        string.format(
            '%.4f,%.4f,%.4f',
            recipe.Tuning.SpawnOffset.X,
            recipe.Tuning.SpawnOffset.Y,
            recipe.Tuning.SpawnOffset.Z
        ),
        tostring(recipe.Executable.Presentation.ModelAssetId),
        tostring(recipe.Executable.Presentation.ChaseLoopSoundAssetId),
        tostring(recipe.Meta.Seed),
    }

    local behaviorIds = {}
    for _, intent in ipairs(recipe.Executable.BehaviorIntents) do
        local suffix = if intent.Enabled == false then ':off' else ':on'
        table.insert(behaviorIds, intent.Id .. suffix)
    end
    table.sort(behaviorIds)
    for _, behaviorId in ipairs(behaviorIds) do
        table.insert(hashInputParts, behaviorId)
    end

    local effectIds = {}
    for _, effectIntent in ipairs(recipe.Executable.EffectIntents) do
        local durationText = if type(effectIntent.DurationSeconds) == 'number'
            then string.format(':%.4f', effectIntent.DurationSeconds)
            else ''
        table.insert(effectIds, effectIntent.Id .. durationText)
    end
    table.sort(effectIds)
    for _, effectId in ipairs(effectIds) do
        table.insert(hashInputParts, effectId)
    end

    local hashInput = table.concat(hashInputParts, '|')

    local hash = 2166136261
    for i = 1, #hashInput do
        hash = bit32.bxor(hash, string.byte(hashInput, i))
        hash = (hash * 16777619) % 4294967296
    end

    return string.format('recipe-%08x', hash)
end

function MonsterUgcPipeline.evaluateBrief(rawBrief)
    local normalizedBrief, missingFields = normalizeBrief(rawBrief)
    if not normalizedBrief then
        return false,
            table.freeze({
                Status = MonsterUgcPipeline.Status.WaitingForUser,
                RejectionCode = MonsterUgcPipeline.RejectionCode.MissingBriefFields,
                MissingFields = table.freeze(missingFields),
                Question = nextClarifyingQuestion(missingFields[1]),
            })
    end

    return true,
        table.freeze({
            Status = MonsterUgcPipeline.Status.ReadyToGenerate,
            Brief = normalizedBrief,
        })
end

function MonsterUgcPipeline.generateForSandbox(rawBrief, options)
    local generationOptions = options or {}

    local briefOk, briefState = MonsterUgcPipeline.evaluateBrief(rawBrief)
    if not briefOk then
        return false, briefState
    end
    local brief = briefState.Brief

    local now = generationOptions.Now or os.time
    local seed = normalizeSeed(generationOptions.Seed)
    local rng = Random.new(seed)
    local mappedPrefabId = ATMOSPHERE_PREFAB_MAP[brief.Semantics.Atmosphere]
    local prefabId = mappedPrefabId or DEFAULT_PREFAB_ID
    local sourceByField = {
        ['Semantics.Lore'] = 'template_fill',
        ['Semantics.Atmosphere'] = 'brief_tag_map',
        ['Semantics.TriggerIntent.Summary'] = 'template_fill',
        ['Semantics.CounterplayIntent.Summary'] = 'template_fill',
    }

    local diagnostics = {
        ClampedFields = {},
        AssetChecks = {},
        Notes = {},
        SkippedBehaviorIds = {},
        SkippedEffectIds = {},
    }

    if mappedPrefabId == nil then
        table.insert(diagnostics.Notes, 'AtmosphereFallbackPrefab')
    end

    local monsterName, nameSource = buildMonsterName(brief, rng)
    sourceByField.Name = nameSource
    sourceByField.Id = 'server_generated'

    local tuning = applyRequestedTuning(
        TUNING_PREFABS[prefabId],
        brief.Preferences.Tuning,
        diagnostics,
        sourceByField
    )

    local modelAssetId = brief.Preferences.ModelAssetId or DEFAULT_ASSET_IDS.ModelAssetId
    local chaseLoopSoundAssetId = brief.Preferences.ChaseLoopSoundAssetId
        or DEFAULT_ASSET_IDS.ChaseLoopSoundAssetId
    sourceByField['Executable.Presentation.ModelAssetId'] = if brief.Preferences.ModelAssetId
            ~= nil
        then 'brief_template_fill'
        else 'prefab_default'
    sourceByField['Executable.Presentation.ChaseLoopSoundAssetId'] = if brief.Preferences.ChaseLoopSoundAssetId
            ~= nil
        then 'brief_template_fill'
        else 'prefab_default'
    sourceByField['Executable.Presentation.RigType'] = 'system_fixed'
    sourceByField['Executable.Presentation.AnimationMode'] = 'system_fixed'

    local assetValidator = generationOptions.AssetValidator or defaultAssetValidator
    local modelAssetOk, modelAssetReason =
        validateAsset(modelAssetId, 'ModelAssetId', assetValidator, diagnostics)
    if not modelAssetOk then
        return false,
            table.freeze({
                Status = MonsterUgcPipeline.Status.Rejected,
                RejectionCode = MonsterUgcPipeline.RejectionCode.AssetValidationFailed,
                Reason = modelAssetReason,
                Diagnostics = deepFreeze(diagnostics),
            })
    end

    local soundAssetOk, soundAssetReason =
        validateAsset(chaseLoopSoundAssetId, 'ChaseLoopSoundAssetId', assetValidator, diagnostics)
    if not soundAssetOk then
        return false,
            table.freeze({
                Status = MonsterUgcPipeline.Status.Rejected,
                RejectionCode = MonsterUgcPipeline.RejectionCode.AssetValidationFailed,
                Reason = soundAssetReason,
                Diagnostics = deepFreeze(diagnostics),
            })
    end

    local behaviorIntentsOk, behaviorIntentsOrReason =
        buildBehaviorIntents(prefabId, brief, sourceByField)
    if not behaviorIntentsOk then
        return false,
            table.freeze({
                Status = MonsterUgcPipeline.Status.Rejected,
                RejectionCode = MonsterUgcPipeline.RejectionCode.UnknownBehaviorIntent,
                Reason = behaviorIntentsOrReason,
                Diagnostics = deepFreeze(diagnostics),
            })
    end
    local behaviorIntents = behaviorIntentsOrReason

    local effectIntentsOk, effectIntentsOrReason =
        buildEffectIntents(prefabId, brief, sourceByField)
    if not effectIntentsOk then
        return false,
            table.freeze({
                Status = MonsterUgcPipeline.Status.Rejected,
                RejectionCode = MonsterUgcPipeline.RejectionCode.InvalidEffectIntent,
                Reason = effectIntentsOrReason,
                Diagnostics = deepFreeze(diagnostics),
            })
    end
    local effectIntents = effectIntentsOrReason

    local layeredConfig = {
        Id = buildMonsterId(generationOptions.PlayerUserId, seed),
        Name = monsterName,
        Semantics = {
            Lore = brief.Semantics.Lore,
            Atmosphere = brief.Semantics.Atmosphere,
            TriggerIntent = {
                Summary = brief.Semantics.TriggerIntentSummary,
                Space = 'UGC sandbox maze rooms',
            },
            CounterplayIntent = {
                Summary = brief.Semantics.CounterplayIntentSummary,
                Tool = 'Player movement and route planning',
            },
        },
        Tuning = {
            Speed = tuning.Speed,
            SightRange = tuning.SightRange,
            PatrolSpeedMultiplier = tuning.PatrolSpeedMultiplier,
            SpawnOffset = tuning.SpawnOffset,
        },
        Executable = {
            Presentation = {
                ModelAssetId = modelAssetId,
                RigType = MonsterPresentationCatalog.RigType.R6,
                AnimationMode = MonsterPresentationCatalog.AnimationMode.DefaultR6,
                ChaseLoopSoundAssetId = chaseLoopSoundAssetId,
            },
            BehaviorIntents = behaviorIntents,
            EffectIntents = effectIntents,
        },
    }

    local compileOk, runtimeProfileOrReason, compileReportOrDiagnostic =
        MonsterCompiler.compileMonsterForMaze(layeredConfig)
    if not compileOk then
        return false,
            table.freeze({
                Status = MonsterUgcPipeline.Status.Rejected,
                RejectionCode = MonsterUgcPipeline.RejectionCode.CompileFailed,
                Reason = runtimeProfileOrReason,
                CompileDiagnostic = compileReportOrDiagnostic,
                Diagnostics = deepFreeze(diagnostics),
            })
    end

    local runtimeProfile = runtimeProfileOrReason
    local compileReport = compileReportOrDiagnostic
    diagnostics.SkippedBehaviorIds = table.clone(compileReport.SkippedBehaviorIds)
    diagnostics.SkippedEffectIds = table.clone(compileReport.SkippedEffectIds)

    local recipe = {
        Id = layeredConfig.Id,
        Name = layeredConfig.Name,
        Semantics = table.clone(layeredConfig.Semantics),
        Tuning = table.clone(layeredConfig.Tuning),
        Executable = table.clone(layeredConfig.Executable),
        Meta = {
            Seed = seed,
            PrefabId = prefabId,
            GeneratedAtEpochSeconds = now(),
            RequestedByUserId = generationOptions.PlayerUserId,
            SourceByField = sourceByField,
        },
    }

    local recipeHash = buildRecipeHash(recipe)

    local generationResult = {
        Status = MonsterUgcPipeline.Status.SandboxReady,
        Seed = seed,
        RecipeHash = recipeHash,
        Brief = brief,
        Recipe = recipe,
        LayeredConfig = layeredConfig,
        RuntimeProfile = runtimeProfile,
        CompileReport = compileReport,
        Diagnostics = diagnostics,
        SandboxPolicy = {
            Mode = 'SandboxOnly',
            AllowSubmitForReview = true,
            PlayerRateLimitKey = 'ugc_monster_generation',
        },
    }

    return true, deepFreeze(generationResult)
end

local function normalizeTelemetry(rawTelemetry)
    local telemetry = rawTelemetry or {}

    local function normalizeNonNegativeNumber(value)
        if type(value) ~= 'number' then
            return 0
        end
        if value < 0 then
            return 0
        end
        return value
    end

    return {
        EncounterCount = normalizeNonNegativeNumber(telemetry.EncounterCount),
        AverageChaseSeconds = normalizeNonNegativeNumber(telemetry.AverageChaseSeconds),
        PlayerReportCount = normalizeNonNegativeNumber(telemetry.PlayerReportCount),
        AverageSurvivalSeconds = normalizeNonNegativeNumber(telemetry.AverageSurvivalSeconds),
    }
end

function MonsterUgcPipeline.buildReviewBundle(generationResult, rawTelemetry, options)
    local bundleOptions = options or {}
    if
        type(generationResult) ~= 'table'
        or generationResult.Status ~= MonsterUgcPipeline.Status.SandboxReady
    then
        return false, MonsterUgcPipeline.RejectionCode.InvalidGenerationResult
    end

    local now = bundleOptions.Now or os.time
    local telemetry = normalizeTelemetry(rawTelemetry)

    local bundle = {
        BundleId = string.format('bundle-%s', generationResult.RecipeHash),
        Status = 'Pending',
        Moderation = {
            Status = 'Pending',
            RejectionCode = nil,
            Reviewer = nil,
        },
        SubmittedAtEpochSeconds = now(),
        SubmittedByUserId = bundleOptions.SubmittedByUserId,
        Brief = generationResult.Brief,
        Recipe = generationResult.Recipe,
        LayeredConfig = generationResult.LayeredConfig,
        RuntimeProfile = generationResult.RuntimeProfile,
        CompileReport = generationResult.CompileReport,
        Diagnostics = generationResult.Diagnostics,
        Seed = generationResult.Seed,
        RecipeHash = generationResult.RecipeHash,
        Telemetry = telemetry,
    }

    return true, deepFreeze(bundle)
end

function MonsterUgcPipeline.isSafeSpawnOffset(offset)
    return isSafeSpawnOffset(offset)
end

function MonsterUgcPipeline.isKnownBehaviorIntent(intentId)
    return MonsterBehaviorCatalog.Known[intentId] == true
end

function MonsterUgcPipeline.isKnownEffectIntent(intentId)
    return MonsterEffectCatalog.Known[intentId] == true
end

function MonsterUgcPipeline.canRunInMazeBehavior(intentId)
    return MonsterBehaviorCatalog.MazeExecutable[intentId] == true
end

function MonsterUgcPipeline.canRunInMazeEffect(intentId)
    return MonsterEffectCatalog.MazeExecutable[intentId] == true
end

return MonsterUgcPipeline
