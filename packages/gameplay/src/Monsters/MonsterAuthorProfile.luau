local MonsterBehaviorCatalog = require(script.Parent.MonsterBehaviorCatalog)
local MonsterEffectCatalog = require(script.Parent.MonsterEffectCatalog)

local MonsterAuthorProfile = {}

local function isNonEmptyString(value)
    return type(value) == 'string' and value ~= ''
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

    if not isNonEmptyString(profile.Lore) then
        return false, 'MissingLore'
    end

    if not isNonEmptyString(profile.Atmosphere) then
        return false, 'MissingAtmosphere'
    end

    local triggerOk, triggerReason =
        validateSummaryTable(profile.TriggerIntent, 'MissingTriggerIntentSummary')
    if not triggerOk then
        return false, triggerReason
    end

    local counterplayOk, counterplayReason =
        validateSummaryTable(profile.CounterplayIntent, 'MissingCounterplayIntentSummary')
    if not counterplayOk then
        return false, counterplayReason
    end

    local numericProfile = profile.NumericProfile
    if type(numericProfile) ~= 'table' then
        return false, 'MissingNumericProfile'
    end

    if type(numericProfile.Speed) ~= 'number' or numericProfile.Speed <= 0 then
        return false, 'InvalidSpeed'
    end

    if type(numericProfile.SightRange) ~= 'number' or numericProfile.SightRange <= 0 then
        return false, 'InvalidSightRange'
    end

    if
        type(numericProfile.PatrolSpeedMultiplier) ~= 'number'
        or numericProfile.PatrolSpeedMultiplier <= 0
    then
        return false, 'InvalidPatrolSpeedMultiplier'
    end

    if numericProfile.SpawnOffset ~= nil and typeof(numericProfile.SpawnOffset) ~= 'Vector3' then
        return false, 'InvalidSpawnOffset'
    end

    if type(profile.BehaviorIntents) ~= 'table' or #profile.BehaviorIntents == 0 then
        return false, 'MissingBehaviorIntents'
    end

    for _, behaviorIntent in ipairs(profile.BehaviorIntents) do
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

    local effectIntents = profile.EffectIntents
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

    return true
end

return MonsterAuthorProfile
