local PerceptionComponent = {}
PerceptionComponent.__index = PerceptionComponent

function PerceptionComponent.new(options)
    local runtimeOptions = options or {}

    return setmetatable({
        GetPlayers = runtimeOptions.GetPlayers,
        CanTargetPlayer = runtimeOptions.CanTargetPlayer,
        GetCurrentPosition = runtimeOptions.GetCurrentPosition,
        PickNearestTarget = runtimeOptions.PickNearestTarget,
        SightRange = runtimeOptions.SightRange,
        EnableSenseNearestTarget = runtimeOptions.EnableSenseNearestTarget,
        EnableSightFallback = if runtimeOptions.EnableSightFallback == nil
            then true
            else runtimeOptions.EnableSightFallback == true,
        ConsumeSoundStimuli = runtimeOptions.ConsumeSoundStimuli,
        SoundMemorySeconds = runtimeOptions.SoundMemorySeconds or 4,
        SoundRangeMultiplier = runtimeOptions.SoundRangeMultiplier or 1,
        GetNow = runtimeOptions.GetNow or os.clock,
    }, PerceptionComponent)
end

function PerceptionComponent:_pickSoundTarget(playerPositions, now)
    if type(self.ConsumeSoundStimuli) ~= 'function' then
        return nil, nil
    end

    local bestPlayer = nil
    local bestPosition = nil
    local bestScore = -math.huge

    for _, stimulus in ipairs(self.ConsumeSoundStimuli(now) or {}) do
        local player = stimulus.Player
        local position = stimulus.Position or playerPositions[player]
        local loudness = if type(stimulus.Loudness) == 'number' then stimulus.Loudness else 1
        local heardAt = if type(stimulus.HeardAt) == 'number' then stimulus.HeardAt else now
        local maxAge = if type(stimulus.MemorySeconds) == 'number'
            then stimulus.MemorySeconds
            else self.SoundMemorySeconds

        if
            player ~= nil
            and position ~= nil
            and playerPositions[player] ~= nil
            and loudness > 0
            and (now - heardAt) <= maxAge
        then
            local currentPosition = self.GetCurrentPosition()
            local distance = if currentPosition ~= nil
                then (position - currentPosition).Magnitude
                else 0
            local maxDistance = loudness * self.SoundRangeMultiplier
            if distance <= maxDistance then
                local score = loudness - distance / math.max(self.SoundRangeMultiplier, 1)
                if score > bestScore then
                    bestScore = score
                    bestPlayer = player
                    bestPosition = position
                end
            end
        end
    end

    return bestPlayer, bestPosition
end

function PerceptionComponent:update(blackboard)
    local playerPositions = {}

    for _, player in ipairs(self.GetPlayers()) do
        if self.CanTargetPlayer(player) then
            local character = player.Character
            local rootPart = character and character:FindFirstChild('HumanoidRootPart')
            if rootPart then
                playerPositions[player] = rootPart.Position
            end
        end
    end

    blackboard.TargetPositions = playerPositions

    local now = self.GetNow()
    local targetPlayer, targetPosition = self:_pickSoundTarget(playerPositions, now)
    if targetPlayer == nil and self.EnableSightFallback and self.EnableSenseNearestTarget then
        targetPlayer =
            self.PickNearestTarget(self.GetCurrentPosition(), playerPositions, self.SightRange)
        targetPosition = playerPositions[targetPlayer]
    end
    if targetPlayer ~= nil and targetPosition ~= nil then
        playerPositions[targetPlayer] = targetPosition
    elseif targetPlayer == nil and not self.EnableSightFallback then
        blackboard.LastSeenPosition = nil
        blackboard.LastSeenAt = nil
    end

    local previousTarget = blackboard.CurrentTarget
    blackboard:setTarget(targetPlayer, targetPosition, now)

    return targetPlayer ~= previousTarget
end

return PerceptionComponent
