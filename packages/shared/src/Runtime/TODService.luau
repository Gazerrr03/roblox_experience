local Lighting = game:GetService('Lighting')

local TODProfile = require(script.Parent.TODProfile)

local TODService = {}
TODService.__index = TODService

TODService.ManagedNames = table.freeze({
    Atmosphere = 'RunTODAtmosphere',
    ColorGrading = 'RunTODColorGrading',
})

TODService.UpdateIntervalSeconds = 0.5

local function copyProperties(instance, propertyNames)
    local snapshot = {}

    if instance == nil then
        return snapshot
    end

    for _, propertyName in ipairs(propertyNames) do
        local ok, value = pcall(function()
            return instance[propertyName]
        end)
        if ok then
            snapshot[propertyName] = value
        end
    end

    return snapshot
end

local function applyProperties(instance, properties)
    for propertyName, value in pairs(properties) do
        pcall(function()
            instance[propertyName] = value
        end)
    end
end

local function destroyIfAlive(instance)
    if instance and instance.Parent ~= nil then
        instance:Destroy()
    end
end

local function isColorGradingTarget(instance)
    return instance:IsA('ColorGradingEffect') or instance:IsA('ColorCorrectionEffect')
end

local function createManagedColorGrading(name)
    local created, instance = pcall(Instance.new, 'ColorGradingEffect')
    if created and instance then
        instance.Name = name
        return instance
    end

    instance = Instance.new('ColorCorrectionEffect')
    instance.Name = name
    return instance
end

local function resolveAtmosphereTarget(lightingRoot, managedName)
    local managed = lightingRoot:FindFirstChild(managedName)

    for _, child in ipairs(lightingRoot:GetChildren()) do
        if child:IsA('Atmosphere') and child.Name ~= managedName then
            return child, false
        end
    end

    if managed and managed:IsA('Atmosphere') then
        return managed, false
    end

    local created = Instance.new('Atmosphere')
    created.Name = managedName
    created.Parent = lightingRoot
    return created, true
end

local function resolveColorGradingTarget(lightingRoot, managedName)
    local namedColorGrading = lightingRoot:FindFirstChild('ColorGrading')
    if namedColorGrading and isColorGradingTarget(namedColorGrading) then
        return namedColorGrading, false
    end

    for _, child in ipairs(lightingRoot:GetChildren()) do
        if child.Name ~= managedName and isColorGradingTarget(child) then
            return child, false
        end
    end

    local managed = lightingRoot:FindFirstChild(managedName)
    if managed and isColorGradingTarget(managed) then
        return managed, false
    end

    local created = createManagedColorGrading(managedName)
    created.Parent = lightingRoot
    return created, true
end

function TODService.new(options)
    local runtimeOptions = options or {}
    local self = setmetatable({}, TODService)

    self.Config = runtimeOptions.Config or {}
    self.Lighting = runtimeOptions.Lighting or Lighting
    self.Remote = runtimeOptions.Remote
    self.Clock = runtimeOptions.Clock or os.clock
    self.Profile = runtimeOptions.Profile or TODProfile
    self.UpdateIntervalSeconds = runtimeOptions.UpdateIntervalSeconds
        or TODService.UpdateIntervalSeconds
    self.ManagedNames = runtimeOptions.ManagedNames or TODService.ManagedNames
    self.Initialized = false
    self.Baseline = nil
    self.Targets = nil
    self.CurrentState = nil
    self.IsRunning = false
    self.StartedAtClock = nil
    self.LoopThread = nil
    self.LoopToken = 0

    return self
end

function TODService:_ensureTargets()
    if self.Targets ~= nil then
        return self.Targets
    end

    local atmosphere, createdAtmosphere =
        resolveAtmosphereTarget(self.Lighting, self.ManagedNames.Atmosphere)
    local colorGrading, createdColorGrading =
        resolveColorGradingTarget(self.Lighting, self.ManagedNames.ColorGrading)

    self.Targets = {
        Atmosphere = atmosphere,
        ColorGrading = colorGrading,
        CreatedAtmosphere = createdAtmosphere,
        CreatedColorGrading = createdColorGrading,
    }

    return self.Targets
end

function TODService:_captureBaseline()
    if self.Baseline ~= nil then
        return self.Baseline
    end

    local targets = self:_ensureTargets()
    self.Baseline = {
        Lighting = copyProperties(self.Lighting, self.Profile.LightingPropertyNames),
        Atmosphere = copyProperties(targets.Atmosphere, self.Profile.AtmospherePropertyNames),
        ColorGrading = copyProperties(targets.ColorGrading, self.Profile.ColorGradingPropertyNames),
    }

    return self.Baseline
end

function TODService:_restoreTargets()
    if self.Targets == nil or self.Baseline == nil then
        return
    end

    local targets = self.Targets

    if targets.CreatedAtmosphere then
        destroyIfAlive(targets.Atmosphere)
    else
        applyProperties(targets.Atmosphere, self.Baseline.Atmosphere)
    end

    if targets.CreatedColorGrading then
        destroyIfAlive(targets.ColorGrading)
    else
        applyProperties(targets.ColorGrading, self.Baseline.ColorGrading)
    end
end

function TODService:_buildPayload(snapshot, isRunning)
    return {
        ClockTime = snapshot.ClockTime,
        RoundTimeRemainingSeconds = snapshot.RoundTimeRemainingSeconds,
        ElapsedRoundSeconds = snapshot.ElapsedRoundSeconds,
        IsRunning = isRunning,
    }
end

function TODService:_applySnapshot(snapshot)
    local targets = self:_ensureTargets()
    applyProperties(self.Lighting, snapshot.Lighting)
    applyProperties(targets.Atmosphere, snapshot.Atmosphere)
    applyProperties(targets.ColorGrading, snapshot.ColorGrading)
end

function TODService:_emit(payload)
    self.CurrentState = payload

    if self.Remote and type(self.Remote.FireAllClients) == 'function' then
        self.Remote:FireAllClients(payload)
    end
end

function TODService:sendToPlayer(player)
    if self.CurrentState == nil then
        return
    end

    if self.Remote and type(self.Remote.FireClient) == 'function' then
        self.Remote:FireClient(player, self.CurrentState)
    end
end

function TODService:prime()
    self:_captureBaseline()

    local snapshot = self.Profile.evaluate(self.Config, 0)
    self:_applySnapshot(snapshot)

    local payload = self:_buildPayload(snapshot, false)
    self:_emit(payload)
    self.Initialized = true

    return payload
end

function TODService:start()
    if self.IsRunning then
        return self.CurrentState
    end

    if not self.Initialized then
        self:prime()
    end

    self.IsRunning = true
    self.StartedAtClock = self.Clock()
    self.LoopToken += 1

    local activeLoopToken = self.LoopToken
    self:step(self.StartedAtClock)

    self.LoopThread = task.spawn(function()
        while self.IsRunning and self.LoopToken == activeLoopToken do
            task.wait(self.UpdateIntervalSeconds)
            self:step(self.Clock())
        end
    end)

    return self.CurrentState
end

function TODService:step(nowSeconds)
    if not self.Initialized then
        self:prime()
    end

    local effectiveNow = nowSeconds or self.Clock()
    local elapsedSeconds = 0
    if self.StartedAtClock ~= nil then
        elapsedSeconds = math.max(0, effectiveNow - self.StartedAtClock)
    end

    local snapshot = self.Profile.evaluate(self.Config, elapsedSeconds)
    self:_applySnapshot(snapshot)

    local durationSeconds = self.Profile.getDurationSeconds(self.Config)
    local isStillRunning = self.IsRunning and elapsedSeconds < durationSeconds
    local payload = self:_buildPayload(snapshot, isStillRunning)
    self:_emit(payload)

    if self.IsRunning and not isStillRunning then
        self.IsRunning = false
        self.LoopToken += 1
    end

    return payload
end

function TODService:stop()
    self.IsRunning = false
    self.LoopToken += 1
    return self.CurrentState
end

function TODService:restore()
    self:stop()

    if self.Baseline == nil then
        return
    end

    applyProperties(self.Lighting, self.Baseline.Lighting)
    self:_restoreTargets()
    self.Targets = nil
    self.CurrentState = nil
    self.Initialized = false
    self.StartedAtClock = nil
    self.Baseline = nil
end

function TODService:destroy()
    self:restore()
end

return TODService
