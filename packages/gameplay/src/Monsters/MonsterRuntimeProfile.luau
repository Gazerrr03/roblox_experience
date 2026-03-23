local MonsterRuntimeProfile = {}

local function isNonEmptyString(value)
    return type(value) == 'string' and value ~= ''
end

function MonsterRuntimeProfile.validate(profile)
    if type(profile) ~= 'table' then
        return false, 'MalformedMonsterRuntimeProfile'
    end

    if not isNonEmptyString(profile.Id) then
        return false, 'MissingRuntimeId'
    end

    if not isNonEmptyString(profile.Name) then
        return false, 'MissingRuntimeName'
    end

    if type(profile.Speed) ~= 'number' or profile.Speed <= 0 then
        return false, 'InvalidRuntimeSpeed'
    end

    if type(profile.SightRange) ~= 'number' or profile.SightRange <= 0 then
        return false, 'InvalidRuntimeSightRange'
    end

    if type(profile.PatrolSpeedMultiplier) ~= 'number' or profile.PatrolSpeedMultiplier <= 0 then
        return false, 'InvalidRuntimePatrolSpeedMultiplier'
    end

    if typeof(profile.SpawnOffset) ~= 'Vector3' then
        return false, 'InvalidRuntimeSpawnOffset'
    end

    if type(profile.Behaviors) ~= 'table' then
        return false, 'MissingRuntimeBehaviors'
    end

    if type(profile.Effects) ~= 'table' then
        return false, 'MissingRuntimeEffects'
    end

    return true
end

return MonsterRuntimeProfile
