local MonsterPresentationCatalog = require(script.Parent.MonsterPresentationCatalog)

local MonsterRuntimeProfile = {}

local function isNonEmptyString(value)
    return type(value) == 'string' and value ~= ''
end

local function isPositiveNumber(value)
    return type(value) == 'number' and value > 0
end

local function isValidDamagePips(value)
    return value == 1 or value == 2
end

local function validateAnimationAssetIds(animationAssetIds, missingReasonPrefix, invalidReasonPrefix)
    if type(animationAssetIds) ~= 'table' then
        return false, missingReasonPrefix
    end

    for _, slotName in ipairs(MonsterPresentationCatalog.RequiredCustomAnimationSlots) do
        if animationAssetIds[slotName] == nil then
            return false, string.format('%s%s', missingReasonPrefix, slotName)
        end

        if type(animationAssetIds[slotName]) ~= 'number' or animationAssetIds[slotName] <= 0 then
            return false, string.format('%s%s', invalidReasonPrefix, slotName)
        end
    end

    return true
end

local function readComponentTable(profile, name)
    local components = profile.Components
    if components == nil then
        return nil, nil
    end
    if type(components) ~= 'table' then
        return nil, 'InvalidRuntimeComponents'
    end

    local component = components[name]
    if component == nil then
        return nil, nil
    end
    if type(component) ~= 'table' then
        return nil, string.format('InvalidRuntimeComponent%s', name)
    end

    return component, nil
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

    local presentation = profile.Presentation
    if type(presentation) ~= 'table' then
        return false, 'MissingRuntimePresentation'
    end

    if type(presentation.ModelAssetId) ~= 'number' or presentation.ModelAssetId <= 0 then
        return false, 'InvalidRuntimeModelAssetId'
    end

    if not MonsterPresentationCatalog.KnownRigType[presentation.RigType] then
        return false, 'InvalidRuntimeRigType'
    end

    if not MonsterPresentationCatalog.KnownAnimationMode[presentation.AnimationMode] then
        return false, 'InvalidRuntimeAnimationMode'
    end

    local usesCustomHumanoid = presentation.AnimationMode
            == MonsterPresentationCatalog.AnimationMode.CustomHumanoid
        or presentation.RigType == MonsterPresentationCatalog.RigType.CustomHumanoid
    if usesCustomHumanoid then
        if presentation.RigType ~= MonsterPresentationCatalog.RigType.CustomHumanoid then
            return false, 'RuntimeCustomHumanoidRequiresCustomRigType'
        end

        if presentation.AnimationMode ~= MonsterPresentationCatalog.AnimationMode.CustomHumanoid then
            return false, 'RuntimeCustomHumanoidRequiresCustomAnimationMode'
        end

        local animationAssetIdsOk, animationAssetIdsReason = validateAnimationAssetIds(
            presentation.AnimationAssetIds,
            'MissingRuntimeAnimationAssetId',
            'InvalidRuntimeAnimationAssetId'
        )
        if not animationAssetIdsOk then
            return false, animationAssetIdsReason
        end
    end

    if
        presentation.ChaseLoopSoundAssetId ~= nil
        and (
            type(presentation.ChaseLoopSoundAssetId) ~= 'number'
            or presentation.ChaseLoopSoundAssetId <= 0
        )
    then
        return false, 'InvalidRuntimeChaseLoopSoundAssetId'
    end

    local perceptionConfig, perceptionConfigErr = readComponentTable(profile, 'Perception')
    if perceptionConfigErr then
        return false, perceptionConfigErr
    end
    local movementConfig, movementConfigErr = readComponentTable(profile, 'Movement')
    if movementConfigErr then
        return false, movementConfigErr
    end
    local attackConfig, attackConfigErr = readComponentTable(profile, 'Attack')
    if attackConfigErr then
        return false, attackConfigErr
    end
    local healthConfig, healthConfigErr = readComponentTable(profile, 'Health')
    if healthConfigErr then
        return false, healthConfigErr
    end

    if
        perceptionConfig
        and perceptionConfig.SightRange ~= nil
        and not isPositiveNumber(perceptionConfig.SightRange)
    then
        return false, 'InvalidRuntimeComponentPerceptionSightRange'
    end

    if movementConfig then
        if movementConfig.Speed ~= nil and not isPositiveNumber(movementConfig.Speed) then
            return false, 'InvalidRuntimeComponentMovementSpeed'
        end
        if
            movementConfig.PatrolSpeedMultiplier ~= nil
            and not isPositiveNumber(movementConfig.PatrolSpeedMultiplier)
        then
            return false, 'InvalidRuntimeComponentMovementPatrolSpeedMultiplier'
        end
        if
            movementConfig.PatrolReachDistance ~= nil
            and not isPositiveNumber(movementConfig.PatrolReachDistance)
        then
            return false, 'InvalidRuntimeComponentMovementPatrolReachDistance'
        end
        if
            movementConfig.SpawnOffset ~= nil
            and typeof(movementConfig.SpawnOffset) ~= 'Vector3'
        then
            return false, 'InvalidRuntimeComponentMovementSpawnOffset'
        end
    end

    if attackConfig then
        if attackConfig.Range ~= nil and not isPositiveNumber(attackConfig.Range) then
            return false, 'InvalidRuntimeComponentAttackRange'
        end
        if
            attackConfig.CooldownSeconds ~= nil
            and not isPositiveNumber(attackConfig.CooldownSeconds)
        then
            return false, 'InvalidRuntimeComponentAttackCooldown'
        end
        if attackConfig.DamagePips ~= nil and not isValidDamagePips(attackConfig.DamagePips) then
            return false, 'InvalidRuntimeComponentAttackDamagePips'
        end
    end

    if
        healthConfig
        and healthConfig.MaxHp ~= nil
        and (
            type(healthConfig.MaxHp) ~= 'number'
            or healthConfig.MaxHp < 1
            or math.floor(healthConfig.MaxHp) ~= healthConfig.MaxHp
        )
    then
        return false, 'InvalidRuntimeComponentHealthMaxHp'
    end

    local runtimeSpeed = profile.Speed
    if runtimeSpeed == nil and movementConfig then
        runtimeSpeed = movementConfig.Speed
    end
    if not isPositiveNumber(runtimeSpeed) then
        return false, 'InvalidRuntimeSpeed'
    end

    local runtimeSightRange = profile.SightRange
    if runtimeSightRange == nil and perceptionConfig then
        runtimeSightRange = perceptionConfig.SightRange
    end
    if not isPositiveNumber(runtimeSightRange) then
        return false, 'InvalidRuntimeSightRange'
    end

    local runtimePatrolSpeedMultiplier = profile.PatrolSpeedMultiplier
    if runtimePatrolSpeedMultiplier == nil and movementConfig then
        runtimePatrolSpeedMultiplier = movementConfig.PatrolSpeedMultiplier
    end
    if not isPositiveNumber(runtimePatrolSpeedMultiplier) then
        return false, 'InvalidRuntimePatrolSpeedMultiplier'
    end

    local runtimeSpawnOffset = profile.SpawnOffset
    if runtimeSpawnOffset == nil and movementConfig then
        runtimeSpawnOffset = movementConfig.SpawnOffset
    end
    if typeof(runtimeSpawnOffset) ~= 'Vector3' then
        return false, 'InvalidRuntimeSpawnOffset'
    end

    local runtimeAttackRange = profile.AttackRange
    if runtimeAttackRange == nil and attackConfig then
        runtimeAttackRange = attackConfig.Range
    end
    if runtimeAttackRange == nil then
        runtimeAttackRange = 4
    end
    if not isPositiveNumber(runtimeAttackRange) then
        return false, 'InvalidRuntimeAttackRange'
    end

    local runtimeAttackCooldownSeconds = profile.AttackCooldownSeconds
    if runtimeAttackCooldownSeconds == nil and attackConfig then
        runtimeAttackCooldownSeconds = attackConfig.CooldownSeconds
    end
    if runtimeAttackCooldownSeconds == nil then
        runtimeAttackCooldownSeconds = 1
    end
    if not isPositiveNumber(runtimeAttackCooldownSeconds) then
        return false, 'InvalidRuntimeAttackCooldownSeconds'
    end

    local runtimeAttackDamagePips = profile.AttackDamagePips
    if runtimeAttackDamagePips == nil and attackConfig then
        runtimeAttackDamagePips = attackConfig.DamagePips
    end
    if runtimeAttackDamagePips == nil then
        runtimeAttackDamagePips = 1
    end
    if not isValidDamagePips(runtimeAttackDamagePips) then
        return false, 'InvalidRuntimeAttackDamagePips'
    end

    if type(profile.Behaviors) ~= 'table' then
        return false, 'MissingRuntimeBehaviors'
    end

    if type(profile.Effects) ~= 'table' then
        return false, 'MissingRuntimeEffects'
    end

    local combatHitPoints = profile.CombatHitPoints
    if
        type(combatHitPoints) ~= 'number'
        or combatHitPoints < 1
        or math.floor(combatHitPoints) ~= combatHitPoints
    then
        return false, 'InvalidRuntimeCombatHitPoints'
    end

    return true
end

return MonsterRuntimeProfile
