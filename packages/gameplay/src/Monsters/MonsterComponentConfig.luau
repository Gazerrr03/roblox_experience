local DEFAULT_ATTACK_COOLDOWN_SECONDS = 1
local DEFAULT_ATTACK_DAMAGE_PIPS = 1
local DEFAULT_ATTACK_HIT_MARKER_NAME = 'Hit'
local DEFAULT_ATTACK_RANGE = 4
local DEFAULT_ATTACK_ARC_DEGREES = 100
local DEFAULT_PATROL_REACH_DISTANCE = 2
local DEFAULT_SPAWN_OFFSET = Vector3.new(0, 4, 0)

local MonsterComponentConfig = {}

local function getPositiveNumber(value, fallback, defaultValue)
    if type(value) == 'number' and value > 0 then
        return value
    end
    if type(fallback) == 'number' and fallback > 0 then
        return fallback
    end
    return defaultValue
end

local function getSpawnOffset(primary, fallback)
    if typeof(primary) == 'Vector3' then
        return primary
    end
    if typeof(fallback) == 'Vector3' then
        return fallback
    end
    return DEFAULT_SPAWN_OFFSET
end

local function getAttackDamagePips(value, fallback)
    if value == 1 or value == 2 then
        return value
    end
    if fallback == 1 or fallback == 2 then
        return fallback
    end
    return DEFAULT_ATTACK_DAMAGE_PIPS
end

function MonsterComponentConfig.fromRuntimeProfile(runtimeProfile)
    local profile = runtimeProfile or {}
    local components = if type(profile.Components) == 'table' then profile.Components else {}

    local perception = if type(components.Perception) == 'table' then components.Perception else {}
    local movement = if type(components.Movement) == 'table' then components.Movement else {}
    local attack = if type(components.Attack) == 'table' then components.Attack else {}

    local componentConfig = {
        Perception = table.freeze({
            SightRange = getPositiveNumber(perception.SightRange, profile.SightRange, 30),
        }),
        Movement = table.freeze({
            PatrolReachDistance = getPositiveNumber(
                movement.PatrolReachDistance,
                nil,
                DEFAULT_PATROL_REACH_DISTANCE
            ),
            PatrolSpeedMultiplier = getPositiveNumber(
                movement.PatrolSpeedMultiplier,
                profile.PatrolSpeedMultiplier,
                0.45
            ),
            SpawnOffset = getSpawnOffset(movement.SpawnOffset, profile.SpawnOffset),
            Speed = getPositiveNumber(movement.Speed, profile.Speed, 14),
        }),
        Attack = table.freeze({
            ArcDegrees = getPositiveNumber(attack.ArcDegrees, nil, DEFAULT_ATTACK_ARC_DEGREES),
            CooldownSeconds = getPositiveNumber(
                attack.CooldownSeconds,
                profile.AttackCooldownSeconds,
                DEFAULT_ATTACK_COOLDOWN_SECONDS
            ),
            DamagePips = getAttackDamagePips(attack.DamagePips, profile.AttackDamagePips),
            HitMarkerName = if type(attack.HitMarkerName) == 'string'
                    and attack.HitMarkerName ~= ''
                then attack.HitMarkerName
                else DEFAULT_ATTACK_HIT_MARKER_NAME,
            Range = getPositiveNumber(attack.Range, profile.AttackRange, DEFAULT_ATTACK_RANGE),
        }),
        Health = table.freeze({
            MaxHp = getPositiveNumber(
                components.Health and components.Health.MaxHp,
                getPositiveNumber(
                    profile.Health and profile.Health.MaxHp,
                    profile.CombatHitPoints,
                    1
                ),
                1
            ),
        }),
    }

    return table.freeze(componentConfig)
end

return MonsterComponentConfig
