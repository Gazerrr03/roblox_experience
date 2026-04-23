local MonsterAuthorProfile = require(script.Parent.MonsterAuthorProfile)
local MonsterBehaviorCatalog = require(script.Parent.MonsterBehaviorCatalog)
local MonsterComponentConfig = require(script.Parent.MonsterComponentConfig)
local MonsterEffectCatalog = require(script.Parent.MonsterEffectCatalog)
local MonsterRuntimeProfile = require(script.Parent.MonsterRuntimeProfile)

local DEFAULT_SPAWN_OFFSET = Vector3.new(0, 4, 0)
local DEFAULT_ATTACK_COOLDOWN_SECONDS = 1
local DEFAULT_ATTACK_DAMAGE_PIPS = 1
local DEFAULT_ATTACK_RANGE = 4
local DEFAULT_COMBAT_HIT_POINTS = 1

local MonsterCompiler = {}

local function buildErrorDiagnostic(category, code)
    return table.freeze({
        Category = category,
        Code = code,
    })
end

local function cloneRuntimeEffect(effectIntent)
    local runtimeEffect = {
        Id = effectIntent.Id,
    }

    if type(effectIntent.DurationSeconds) == 'number' then
        runtimeEffect.DurationSeconds = effectIntent.DurationSeconds
    end

    return table.freeze(runtimeEffect)
end

local function cloneRuntimePresentation(presentation)
    local runtimePresentation = {
        ModelAssetId = presentation.ModelAssetId,
        RigType = presentation.RigType,
        AnimationMode = presentation.AnimationMode,
        ChaseLoopSoundAssetId = presentation.ChaseLoopSoundAssetId,
    }

    if type(presentation.AnimationAssetIds) == 'table' then
        runtimePresentation.AnimationAssetIds = table.freeze(table.clone(presentation.AnimationAssetIds))
    end

    return table.freeze(runtimePresentation)
end

function MonsterCompiler.compileMonsterForMaze(authorProfile)
    local validAuthorProfile, normalizedOrReason = MonsterAuthorProfile.validate(authorProfile)
    if not validAuthorProfile then
        local category = MonsterAuthorProfile.classifyReason(normalizedOrReason)
        return false, normalizedOrReason, buildErrorDiagnostic(category, normalizedOrReason)
    end
    local normalizedProfile = normalizedOrReason

    local behaviors = {}
    local skippedBehaviorIds = {}
    for _, behaviorIntent in ipairs(normalizedProfile.Executable.BehaviorIntents) do
        if behaviorIntent.Enabled ~= false then
            if MonsterBehaviorCatalog.MazeExecutable[behaviorIntent.Id] then
                behaviors[behaviorIntent.Id] = true
            else
                table.insert(skippedBehaviorIds, behaviorIntent.Id)
            end
        end
    end

    local runtimeEffects = {}
    local skippedEffectIds = {}
    for _, effectIntent in ipairs(normalizedProfile.Executable.EffectIntents or {}) do
        if effectIntent.Enabled ~= false then
            if MonsterEffectCatalog.MazeExecutable[effectIntent.Id] then
                table.insert(runtimeEffects, cloneRuntimeEffect(effectIntent))
            else
                table.insert(skippedEffectIds, effectIntent.Id)
            end
        end
    end

    local combatHitPoints = normalizedProfile.Tuning.CombatHitPoints
    if
        type(combatHitPoints) ~= 'number'
        or combatHitPoints < 1
        or math.floor(combatHitPoints) ~= combatHitPoints
    then
        combatHitPoints = DEFAULT_COMBAT_HIT_POINTS
    end

    local runtimeProfile = {
        Id = normalizedProfile.Id,
        Name = normalizedProfile.Name,
        Presentation = cloneRuntimePresentation(normalizedProfile.Executable.Presentation),
        AttackCooldownSeconds = normalizedProfile.Tuning.AttackCooldownSeconds
            or DEFAULT_ATTACK_COOLDOWN_SECONDS,
        AttackDamagePips = normalizedProfile.Tuning.AttackDamagePips or DEFAULT_ATTACK_DAMAGE_PIPS,
        AttackRange = normalizedProfile.Tuning.AttackRange or DEFAULT_ATTACK_RANGE,
        Speed = normalizedProfile.Tuning.Speed,
        SightRange = normalizedProfile.Tuning.SightRange,
        PatrolSpeedMultiplier = normalizedProfile.Tuning.PatrolSpeedMultiplier,
        SpawnOffset = normalizedProfile.Tuning.SpawnOffset or DEFAULT_SPAWN_OFFSET,
        CombatHitPoints = combatHitPoints,
        Health = normalizedProfile.Health,
        Behaviors = table.freeze(behaviors),
        Effects = table.freeze(runtimeEffects),
    }
    runtimeProfile.Components = MonsterComponentConfig.fromRuntimeProfile(runtimeProfile)
    runtimeProfile = table.freeze(runtimeProfile)

    local validRuntimeProfile, runtimeReason = MonsterRuntimeProfile.validate(runtimeProfile)
    if not validRuntimeProfile then
        return false,
            runtimeReason,
            buildErrorDiagnostic(MonsterAuthorProfile.ErrorCategory.Schema, runtimeReason)
    end

    local compileReport = table.freeze({
        SchemaMode = normalizedProfile.SchemaMode,
        SkippedBehaviorIds = table.freeze(skippedBehaviorIds),
        SkippedEffectIds = table.freeze(skippedEffectIds),
        Warnings = table.freeze({}),
    })

    return true, runtimeProfile, compileReport
end

return MonsterCompiler
