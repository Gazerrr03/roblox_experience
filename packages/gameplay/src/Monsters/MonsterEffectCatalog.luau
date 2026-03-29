local CATEGORY = table.freeze({
    Damage = 'Damage',
    PlayerStatus = 'PlayerStatus',
    MonsterStatus = 'MonsterStatus',
})

local EFFECT = table.freeze({
    DamageLight = 'DamageLight',
    DamageHeavy = 'DamageHeavy',
    SprintSuppressed = 'SprintSuppressed',
    MonsterStunned = 'MonsterStunned',
})

local knownEffectIds = {}
for _, effectId in pairs(EFFECT) do
    knownEffectIds[effectId] = true
end

local DURATION_EFFECTS = table.freeze({
    [EFFECT.SprintSuppressed] = true,
    [EFFECT.MonsterStunned] = true,
})

local MonsterEffectCatalog = {
    Category = CATEGORY,
    Effect = EFFECT,
    Known = table.freeze(knownEffectIds),
    MazeExecutable = table.freeze({
        [EFFECT.DamageLight] = true,
        [EFFECT.DamageHeavy] = true,
    }),
}

function MonsterEffectCatalog.validateIntent(effectIntent)
    if type(effectIntent) ~= 'table' then
        return false, 'MalformedEffectIntent'
    end

    if type(effectIntent.Id) ~= 'string' or effectIntent.Id == '' then
        return false, 'MissingEffectIntentId'
    end

    if not MonsterEffectCatalog.Known[effectIntent.Id] then
        return false, 'UnknownEffectIntent'
    end

    if DURATION_EFFECTS[effectIntent.Id] then
        local durationSeconds = effectIntent.DurationSeconds
        if type(durationSeconds) ~= 'number' or durationSeconds <= 0 then
            return false, 'InvalidEffectPayload'
        end
    end

    return true
end

return table.freeze(MonsterEffectCatalog)
