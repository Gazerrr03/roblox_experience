-- TODService.luau
-- Server-side Time-of-Day service.
-- Manages the round timer and drives Lighting.ClockTime + Atmosphere + ColorCorrection
-- via TODProfile. Broadcasts RoundTimeRemaining + GameHour to clients each heartbeat.

local RunService = game:GetService('RunService')
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local SessionConfig = require(script.Parent.Parent.Config.SessionConfig)
local TODProfile = require(script.Parent.Parent.Runtime.TODProfile)

local REMOTE_NAME = 'TODState'

local TODService = {}
TODService.__index = TODService

function TODService.new()
    return setmetatable({
        elapsedSeconds = 0,
        isRunning = false,
        _heartbeat = nil,
        _remote = nil,
    }, TODService)
end

function TODService:_getOrCreateRemote()
    if self._remote then
        return self._remote
    end
    local container = ReplicatedStorage:FindFirstChild('Remotes')
        or ReplicatedStorage:WaitForChild('Remotes', 5)
    if not container then
        warn('[TODService] Remotes container not found')
        return nil
    end
    self._remote = container:FindFirstChild(REMOTE_NAME)
    if not self._remote then
        self._remote = Instance.new('RemoteEvent')
        self._remote.Name = REMOTE_NAME
        self._remote.Parent = container
    end
    return self._remote
end

function TODService:start()
    if self.isRunning then
        return
    end
    self.elapsedSeconds = 0
    self.isRunning = true

    self:_getOrCreateRemote()

    -- Apply immediately at start
    self:_applyTOD()

    self._heartbeat = RunService.Heartbeat:Connect(function(dt)
        if not self.isRunning then
            return
        end
        self.elapsedSeconds += dt
        self:_applyTOD()
        self:_broadcast()
    end)
end

function TODService:stop()
    self.isRunning = false
    if self._heartbeat then
        self._heartbeat:Disconnect()
        self._heartbeat = nil
    end
end

function TODService:reset()
    self:stop()
    self.elapsedSeconds = 0
end

function TODService:getElapsedSeconds()
    return self.elapsedSeconds
end

function TODService:getGameHour()
    local elapsedMinutes = self.elapsedSeconds / 60
    return TODProfile.gameHourFromElapsedMinutes(elapsedMinutes)
end

function TODService:getRemainingSeconds()
    return TODProfile.remainingSeconds(self.elapsedSeconds)
end

function TODService:_applyTOD()
    local hour = self:getGameHour()
    local profile = TODProfile.interpolateForHour(hour)
    TODProfile.apply(game:GetService('Lighting'), profile)
end

function TODService:_broadcast()
    local remote = self:_getOrCreateRemote()
    if not remote then
        return
    end
    local totalSeconds = SessionConfig.TOD.RoundMinutes * 60
    local remaining = math.max(0, totalSeconds - self.elapsedSeconds)
    local gameHour = self:getGameHour()
    remote:FireAllClients({
        GameHour = gameHour,
        RoundTimeRemaining = remaining,
        ElapsedSeconds = self.elapsedSeconds,
    })
end

return TODService
