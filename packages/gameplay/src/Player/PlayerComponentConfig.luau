local PlayerComponentConfig = {}

local DEFAULT_MAX_HEALTH_PIPS = 2
local DEFAULT_MAX_STAMINA = 100
local DEFAULT_STAMINA_DRAIN_PER_SECOND = 35
local DEFAULT_STAMINA_RECOVERY_PER_SECOND = 20
local DEFAULT_STAMINA_RECOVERY_DELAY_SECONDS = 1.5
local DEFAULT_SPRINT_RESUME_THRESHOLD = 20
local DEFAULT_WALK_SPEED = 16
local DEFAULT_SPRINT_SPEED = 24
local DEFAULT_JUMP_VELOCITY = 50
local DEFAULT_INTERACTION_RANGE = 5
local DEFAULT_SLOT_COUNT = 8

local function getPositiveNumber(value, fallback, defaultValue)
    if type(value) == 'number' and value > 0 then
        return value
    end
    if type(fallback) == 'number' and fallback > 0 then
        return fallback
    end
    return defaultValue
end

function PlayerComponentConfig.fromDefinition(definition)
    local def = definition or {}
    local components = if type(def.Components) == 'table' then def.Components else {}
    local health = if type(components.Health) == 'table' then components.Health else {}
    local stamina = if type(components.Stamina) == 'table' then components.Stamina else {}
    local movement = if type(components.Movement) == 'table' then components.Movement else {}
    local inventory = if type(components.Inventory) == 'table' then components.Inventory else {}

    local componentConfig = {
        Health = table.freeze({
            MaxHealthPips = getPositiveNumber(health.MaxHealthPips, nil, DEFAULT_MAX_HEALTH_PIPS),
        }),
        Stamina = table.freeze({
            MaxStamina = getPositiveNumber(stamina.MaxStamina, nil, DEFAULT_MAX_STAMINA),
            DrainPerSecond = getPositiveNumber(
                stamina.DrainPerSecond,
                nil,
                DEFAULT_STAMINA_DRAIN_PER_SECOND
            ),
            RecoveryPerSecond = getPositiveNumber(
                stamina.RecoveryPerSecond,
                nil,
                DEFAULT_STAMINA_RECOVERY_PER_SECOND
            ),
            RecoveryDelaySeconds = getPositiveNumber(
                stamina.RecoveryDelaySeconds,
                nil,
                DEFAULT_STAMINA_RECOVERY_DELAY_SECONDS
            ),
            ResumeThreshold = getPositiveNumber(
                stamina.ResumeThreshold,
                nil,
                DEFAULT_SPRINT_RESUME_THRESHOLD
            ),
        }),
        Movement = table.freeze({
            MaxWalkSpeed = getPositiveNumber(movement.MaxWalkSpeed, nil, DEFAULT_WALK_SPEED),
            MaxSprintSpeed = getPositiveNumber(movement.MaxSprintSpeed, nil, DEFAULT_SPRINT_SPEED),
            JumpVelocity = getPositiveNumber(movement.JumpVelocity, nil, DEFAULT_JUMP_VELOCITY),
        }),
        Inventory = table.freeze({
            SlotCount = getPositiveNumber(inventory.SlotCount, nil, DEFAULT_SLOT_COUNT),
            InteractionRange = getPositiveNumber(
                inventory.InteractionRange,
                nil,
                DEFAULT_INTERACTION_RANGE
            ),
        }),
    }

    return table.freeze(componentConfig)
end

function PlayerComponentConfig.getDefaults()
    return table.freeze({
        Health = table.freeze({
            MaxHealthPips = DEFAULT_MAX_HEALTH_PIPS,
        }),
        Stamina = table.freeze({
            MaxStamina = DEFAULT_MAX_STAMINA,
            DrainPerSecond = DEFAULT_STAMINA_DRAIN_PER_SECOND,
            RecoveryPerSecond = DEFAULT_STAMINA_RECOVERY_PER_SECOND,
            RecoveryDelaySeconds = DEFAULT_STAMINA_RECOVERY_DELAY_SECONDS,
            ResumeThreshold = DEFAULT_SPRINT_RESUME_THRESHOLD,
        }),
        Movement = table.freeze({
            MaxWalkSpeed = DEFAULT_WALK_SPEED,
            MaxSprintSpeed = DEFAULT_SPRINT_SPEED,
            JumpVelocity = DEFAULT_JUMP_VELOCITY,
        }),
        Inventory = table.freeze({
            SlotCount = DEFAULT_SLOT_COUNT,
            InteractionRange = DEFAULT_INTERACTION_RANGE,
        }),
    })
end

return PlayerComponentConfig
