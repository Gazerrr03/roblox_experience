local DEFAULT_MAX_HEALTH_PIPS = 2
local DEFAULT_MAX_STAMINA = 100
local DEFAULT_STAMINA_DRAIN_PER_SECOND = 35
local DEFAULT_STAMINA_RECOVERY_PER_SECOND = 20
local DEFAULT_SPRINT_RESUME_THRESHOLD = 20

local DAMAGE_PIP_COST = table.freeze({
    Light = 1,
    Heavy = 2,
})

local PlayerState = {}
PlayerState.__index = PlayerState

PlayerState.DamageKind = table.freeze({
    Light = 'Light',
    Heavy = 'Heavy',
})

PlayerState.Defaults = table.freeze({
    MaxHealthPips = DEFAULT_MAX_HEALTH_PIPS,
    MaxStamina = DEFAULT_MAX_STAMINA,
    StaminaDrainPerSecond = DEFAULT_STAMINA_DRAIN_PER_SECOND,
    StaminaRecoveryPerSecond = DEFAULT_STAMINA_RECOVERY_PER_SECOND,
    SprintResumeThreshold = DEFAULT_SPRINT_RESUME_THRESHOLD,
})

local function clamp(value, minValue, maxValue)
    return math.max(minValue, math.min(maxValue, value))
end

function PlayerState.new(config)
    local resolvedConfig = config or {}
    local maxHealthPips = resolvedConfig.MaxHealthPips or DEFAULT_MAX_HEALTH_PIPS
    local maxStamina = resolvedConfig.MaxStamina or DEFAULT_MAX_STAMINA

    return setmetatable({
        HealthPips = maxHealthPips,
        MaxHealthPips = maxHealthPips,
        CurrentStamina = maxStamina,
        MaxStamina = maxStamina,
        StaminaDrainPerSecond = resolvedConfig.StaminaDrainPerSecond
            or DEFAULT_STAMINA_DRAIN_PER_SECOND,
        StaminaRecoveryPerSecond = resolvedConfig.StaminaRecoveryPerSecond
            or DEFAULT_STAMINA_RECOVERY_PER_SECOND,
        SprintResumeThreshold = resolvedConfig.SprintResumeThreshold
            or DEFAULT_SPRINT_RESUME_THRESHOLD,
        IsDead = false,
        CanSprint = true,
        CorpseActive = false,
        IsSprinting = false,
    }, PlayerState)
end

function PlayerState:getSummary()
    return {
        HealthPips = self.HealthPips,
        MaxHealthPips = self.MaxHealthPips,
        CurrentStamina = self.CurrentStamina,
        MaxStamina = self.MaxStamina,
        IsDead = self.IsDead,
        CanSprint = self.CanSprint,
        CorpseActive = self.CorpseActive,
    }
end

function PlayerState:setSprinting(isSprinting)
    if self.IsDead then
        self.IsSprinting = false
        return false, 'Dead'
    end

    if isSprinting == true and not self.CanSprint then
        self.IsSprinting = false
        return false, 'StaminaDepleted'
    end

    self.IsSprinting = isSprinting == true
    return true, self:getSummary()
end

function PlayerState:applyDamage(damageKind)
    local pipCost = DAMAGE_PIP_COST[damageKind]
    if pipCost == nil then
        return false, 'UnknownDamageKind'
    end

    self.HealthPips = clamp(self.HealthPips - pipCost, 0, self.MaxHealthPips)
    if self.HealthPips == 0 then
        self.IsDead = true
        self.IsSprinting = false
        self.CanSprint = false
        self.CorpseActive = true
    end

    return true, self:getSummary()
end

function PlayerState:step(dt)
    if self.IsDead then
        return self:getSummary()
    end

    local deltaTime = math.max(0, dt or 0)
    if self.IsSprinting and self.CanSprint then
        self.CurrentStamina =
            clamp(self.CurrentStamina - self.StaminaDrainPerSecond * deltaTime, 0, self.MaxStamina)

        if self.CurrentStamina <= 0 then
            self.CurrentStamina = 0
            self.CanSprint = false
            self.IsSprinting = false
        end
    else
        self.CurrentStamina = clamp(
            self.CurrentStamina + self.StaminaRecoveryPerSecond * deltaTime,
            0,
            self.MaxStamina
        )

        if not self.CanSprint and self.CurrentStamina >= self.SprintResumeThreshold then
            self.CanSprint = true
        end
    end

    return self:getSummary()
end

return PlayerState
