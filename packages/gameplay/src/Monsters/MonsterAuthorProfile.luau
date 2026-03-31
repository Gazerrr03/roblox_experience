local MonsterBehaviorCatalog = require(script.Parent.MonsterBehaviorCatalog)
local MonsterEffectCatalog = require(script.Parent.MonsterEffectCatalog)
local MonsterPresentationCatalog = require(script.Parent.MonsterPresentationCatalog)

local MonsterAuthorProfile = {}
local ERROR_CATEGORY = table.freeze({
    Schema = 'SchemaError',
    Boundary = 'BoundaryError',
})
local SCHEMA_MODE = table.freeze({
    Layered = 'Layered',
})
local SEMANTIC_FIELDS = table.freeze({
    Lore = true,
    Atmosphere = true,
    TriggerIntent = true,
    CounterplayIntent = true,
})
local TUNING_FIELDS = table.freeze({
    Speed = true,
    SightRange = true,
    PatrolSpeedMultiplier = true,
    SpawnOffset = true,
})
local EXECUTABLE_FIELDS = table.freeze({
    Presentation = true,
    BehaviorIntents = true,
    EffectIntents = true,
})
local BOUNDARY_REASONS = table.freeze({
    BoundaryLegacySemanticFieldAtRoot = true,
    BoundaryLegacyTuningFieldAtRoot = true,
    BoundaryLegacyExecutableFieldAtRoot = true,
    BoundarySemanticsContainsNonSemanticField = true,
    BoundaryTuningContainsNonTuningField = true,
    BoundaryExecutableContainsNonExecutableField = true,
})

MonsterAuthorProfile.ErrorCategory = ERROR_CATEGORY
MonsterAuthorProfile.SchemaMode = SCHEMA_MODE

local function isNonEmptyString(value)
    return type(value) == 'string' and value ~= ''
end

local function hasAnyField(payload, fields)
    for fieldName in pairs(fields) do
        if payload[fieldName] ~= nil then
            return true
        end
    end

    return false
end

local function validateSummaryTable(summaryTable, missingReason)
    if type(summaryTable) ~= 'table' then
        return false, missingReason
    end

    if not isNonEmptyString(summaryTable.Summary) then
        return false, missingReason
    end

    return true
end

local function validatePresentation(presentation)
    if type(presentation) ~= 'table' then
        return false, 'MissingPresentation'
    end

    if type(presentation.ModelAssetId) ~= 'number' or presentation.ModelAssetId <= 0 then
        return false, 'InvalidModelAssetId'
    end

    if not MonsterPresentationCatalog.KnownRigType[presentation.RigType] then
        return false, 'InvalidRigType'
    end

    if not MonsterPresentationCatalog.KnownAnimationMode[presentation.AnimationMode] then
        return false, 'InvalidAnimationMode'
    end

    if
        presentation.ChaseLoopSoundAssetId ~= nil
        and (
            type(presentation.ChaseLoopSoundAssetId) ~= 'number'
            or presentation.ChaseLoopSoundAssetId <= 0
        )
    then
        return false, 'InvalidChaseLoopSoundAssetId'
    end

    return true
end

local function normalizeSections(profile)
    local hasLayeredSections = profile.Semantics ~= nil
        or profile.Tuning ~= nil
        or profile.Executable ~= nil
    if not hasLayeredSections then
        return nil, 'LegacySchemaUnsupported'
    end

    local semantics = profile.Semantics
    if type(semantics) ~= 'table' then
        return nil, 'MissingSemantics'
    end

    local tuning = profile.Tuning
    if type(tuning) ~= 'table' then
        return nil, 'MissingTuning'
    end

    local executable = profile.Executable
    if type(executable) ~= 'table' then
        return nil, 'MissingExecutable'
    end

    if hasAnyField(profile, SEMANTIC_FIELDS) then
        return nil, 'BoundaryLegacySemanticFieldAtRoot'
    end

    if profile.NumericProfile ~= nil or hasAnyField(profile, TUNING_FIELDS) then
        return nil, 'BoundaryLegacyTuningFieldAtRoot'
    end

    if hasAnyField(profile, EXECUTABLE_FIELDS) then
        return nil, 'BoundaryLegacyExecutableFieldAtRoot'
    end

    if
        semantics.NumericProfile ~= nil
        or hasAnyField(semantics, TUNING_FIELDS)
        or hasAnyField(semantics, EXECUTABLE_FIELDS)
    then
        return nil, 'BoundarySemanticsContainsNonSemanticField'
    end

    if
        tuning.NumericProfile ~= nil
        or hasAnyField(tuning, SEMANTIC_FIELDS)
        or hasAnyField(tuning, EXECUTABLE_FIELDS)
    then
        return nil, 'BoundaryTuningContainsNonTuningField'
    end

    if
        executable.NumericProfile ~= nil
        or hasAnyField(executable, SEMANTIC_FIELDS)
        or hasAnyField(executable, TUNING_FIELDS)
    then
        return nil, 'BoundaryExecutableContainsNonExecutableField'
    end

    return {
        SchemaMode = SCHEMA_MODE.Layered,
        Semantics = semantics,
        Tuning = tuning,
        Executable = executable,
    }
end

function MonsterAuthorProfile.classifyReason(reason)
    if BOUNDARY_REASONS[reason] then
        return ERROR_CATEGORY.Boundary
    end

    return ERROR_CATEGORY.Schema
end

function MonsterAuthorProfile.validate(profile)
    if type(profile) ~= 'table' then
        return false, 'MalformedMonsterAuthorProfile'
    end

    if not isNonEmptyString(profile.Id) then
        return false, 'MissingId'
    end

    if not isNonEmptyString(profile.Name) then
        return false, 'MissingName'
    end

    local normalizedSections, sectionReason = normalizeSections(profile)
    if not normalizedSections then
        return false, sectionReason
    end

    local semantics = normalizedSections.Semantics
    if not isNonEmptyString(semantics.Lore) then
        return false, 'MissingLore'
    end

    if not isNonEmptyString(semantics.Atmosphere) then
        return false, 'MissingAtmosphere'
    end

    local triggerOk, triggerReason =
        validateSummaryTable(semantics.TriggerIntent, 'MissingTriggerIntentSummary')
    if not triggerOk then
        return false, triggerReason
    end

    local counterplayOk, counterplayReason =
        validateSummaryTable(semantics.CounterplayIntent, 'MissingCounterplayIntentSummary')
    if not counterplayOk then
        return false, counterplayReason
    end

    local executable = normalizedSections.Executable
    local presentationOk, presentationReason = validatePresentation(executable.Presentation)
    if not presentationOk then
        return false, presentationReason
    end

    local tuning = normalizedSections.Tuning
    if type(tuning.Speed) ~= 'number' or tuning.Speed <= 0 then
        return false, 'InvalidSpeed'
    end

    if type(tuning.SightRange) ~= 'number' or tuning.SightRange <= 0 then
        return false, 'InvalidSightRange'
    end

    if type(tuning.PatrolSpeedMultiplier) ~= 'number' or tuning.PatrolSpeedMultiplier <= 0 then
        return false, 'InvalidPatrolSpeedMultiplier'
    end

    if tuning.SpawnOffset ~= nil and typeof(tuning.SpawnOffset) ~= 'Vector3' then
        return false, 'InvalidSpawnOffset'
    end

    if type(executable.BehaviorIntents) ~= 'table' or #executable.BehaviorIntents == 0 then
        return false, 'MissingBehaviorIntents'
    end

    for _, behaviorIntent in ipairs(executable.BehaviorIntents) do
        if type(behaviorIntent) ~= 'table' then
            return false, 'MalformedBehaviorIntent'
        end

        if type(behaviorIntent.Id) ~= 'string' or behaviorIntent.Id == '' then
            return false, 'MissingBehaviorIntentId'
        end

        if not MonsterBehaviorCatalog.Known[behaviorIntent.Id] then
            return false, 'UnknownBehaviorIntent'
        end
    end

    local effectIntents = executable.EffectIntents
    if effectIntents ~= nil then
        if type(effectIntents) ~= 'table' then
            return false, 'MalformedEffectIntents'
        end

        for _, effectIntent in ipairs(effectIntents) do
            local validEffect, effectReason = MonsterEffectCatalog.validateIntent(effectIntent)
            if not validEffect then
                return false, effectReason
            end
        end
    end

    return true,
        {
            Id = profile.Id,
            Name = profile.Name,
            SchemaMode = normalizedSections.SchemaMode,
            Semantics = semantics,
            Tuning = tuning,
            Executable = executable,
        }
end

return MonsterAuthorProfile
