local StaminaComponent = {}
StaminaComponent.__index = StaminaComponent

local DEFAULT_STAMINA_RECOVERY_DELAY_SECONDS = 1.5

function StaminaComponent.new()
    return setmetatable({}, StaminaComponent)
end

function StaminaComponent:init(blackboard)
    local config = blackboard.Context.ComponentConfig.Stamina or {}

    self.MaxStamina = config.MaxStamina or 100
    self.CurrentStamina = self.MaxStamina
    self.DrainPerSecond = config.DrainPerSecond or 35
    self.RecoveryPerSecond = config.RecoveryPerSecond or 20
    self.RecoveryDelaySeconds = config.RecoveryDelaySeconds or DEFAULT_STAMINA_RECOVERY_DELAY_SECONDS
    self.ResumeThreshold = config.ResumeThreshold or 20

    self.StaminaRecoveryStartTime = 0
    self.IsSprinting = false
    self.CanSprint = true
end

function StaminaComponent:drainStamina(blackboard, amount)
    if self.IsDead then
        return false, 'Dead'
    end

    local now = os.clock()
    self.StaminaRecoveryStartTime = now + self.RecoveryDelaySeconds
    self.CurrentStamina = math.max(0, self.CurrentStamina - amount)

    if self.CurrentStamina <= 0 then
        self.CanSprint = false
    end

    return true, self.CurrentStamina
end

function StaminaComponent:setSprinting(blackboard, isSprinting)
    if self.IsDead then
        self.IsSprinting = false
        return false, 'Dead'
    end

    if isSprinting and not self.CanSprint then
        self.IsSprinting = false
        return false, 'StaminaDepleted'
    end

    if isSprinting then
        local now = os.clock()
        self.StaminaRecoveryStartTime = now + self.RecoveryDelaySeconds
    end

    self.IsSprinting = isSprinting == true
    return true, self.CurrentStamina
end

function StaminaComponent:update(blackboard, dt)
    local deltaTime = math.max(0, dt or 0)
    local now = os.clock()

    if self.IsDead then
        blackboard.Transient.CurrentStamina = self.CurrentStamina
        blackboard.Transient.MaxStamina = self.MaxStamina
        blackboard.Transient.CanSprint = false
        blackboard.Transient.IsSprinting = false
        return
    end

    if self.IsSprinting and self.CanSprint then
        self.CurrentStamina = math.max(0, self.CurrentStamina - self.DrainPerSecond * deltaTime)

        if self.CurrentStamina <= 0 then
            self.CurrentStamina = 0
            self.CanSprint = false
            self.IsSprinting = false
        end
    elseif now >= self.StaminaRecoveryStartTime then
        self.CurrentStamina = math.min(
            self.MaxStamina,
            self.CurrentStamina + self.RecoveryPerSecond * deltaTime
        )

        if not self.CanSprint and self.CurrentStamina >= self.ResumeThreshold then
            self.CanSprint = true
        end
    end

    blackboard.Transient.CurrentStamina = self.CurrentStamina
    blackboard.Transient.MaxStamina = self.MaxStamina
    blackboard.Transient.CanSprint = self.CanSprint
    blackboard.Transient.IsSprinting = self.IsSprinting
end

function StaminaComponent:destroy(_blackboard) end

return StaminaComponent
