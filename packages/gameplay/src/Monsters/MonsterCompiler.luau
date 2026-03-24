local MonsterAuthorProfile = require(script.Parent.MonsterAuthorProfile)
local MonsterBehaviorCatalog = require(script.Parent.MonsterBehaviorCatalog)
local MonsterEffectCatalog = require(script.Parent.MonsterEffectCatalog)
local MonsterRuntimeProfile = require(script.Parent.MonsterRuntimeProfile)

local DEFAULT_SPAWN_OFFSET = Vector3.new(0, 4, 0)

local MonsterCompiler = {}

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
    return table.freeze({
        ModelAssetId = presentation.ModelAssetId,
        RigType = presentation.RigType,
        AnimationMode = presentation.AnimationMode,
    })
end

function MonsterCompiler.compileMonsterForMaze(authorProfile)
    local validAuthorProfile, authorReason = MonsterAuthorProfile.validate(authorProfile)
    if not validAuthorProfile then
        return false, authorReason
    end

    local behaviors = {}
    local skippedBehaviorIds = {}
    for _, behaviorIntent in ipairs(authorProfile.BehaviorIntents) do
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
    for _, effectIntent in ipairs(authorProfile.EffectIntents or {}) do
        if effectIntent.Enabled ~= false then
            if MonsterEffectCatalog.MazeExecutable[effectIntent.Id] then
                table.insert(runtimeEffects, cloneRuntimeEffect(effectIntent))
            else
                table.insert(skippedEffectIds, effectIntent.Id)
            end
        end
    end

    local runtimeProfile = table.freeze({
        Id = authorProfile.Id,
        Name = authorProfile.Name,
        Presentation = cloneRuntimePresentation(authorProfile.Presentation),
        Speed = authorProfile.NumericProfile.Speed,
        SightRange = authorProfile.NumericProfile.SightRange,
        PatrolSpeedMultiplier = authorProfile.NumericProfile.PatrolSpeedMultiplier,
        SpawnOffset = authorProfile.NumericProfile.SpawnOffset or DEFAULT_SPAWN_OFFSET,
        Behaviors = table.freeze(behaviors),
        Effects = table.freeze(runtimeEffects),
    })

    local validRuntimeProfile, runtimeReason = MonsterRuntimeProfile.validate(runtimeProfile)
    if not validRuntimeProfile then
        return false, runtimeReason
    end

    local compileReport = table.freeze({
        SkippedBehaviorIds = table.freeze(skippedBehaviorIds),
        SkippedEffectIds = table.freeze(skippedEffectIds),
    })

    return true, runtimeProfile, compileReport
end

return MonsterCompiler
