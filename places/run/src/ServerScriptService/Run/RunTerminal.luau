local RunTerminal = {}
RunTerminal.__index = RunTerminal

function RunTerminal.new(kind, part)
    -- 先找直接的 ProximityPrompt 子对象
    local prompt = part:FindFirstChildOfClass('ProximityPrompt')
    if prompt == nil then
        -- 尝试找名为 'Prompt' 或 'prompt' 的子对象
        for _, name in ipairs({'Prompt', 'prompt', 'PROMPT'}) do
            local namedPrompt = part:FindFirstChild(name, true)
            if namedPrompt then
                if namedPrompt:IsA('ProximityPrompt') then
                    prompt = namedPrompt
                    break
                elseif namedPrompt:IsA('Model') or namedPrompt:IsA('Folder') then
                    -- 可能在子目录里
                    prompt = namedPrompt:FindFirstChildOfClass('ProximityPrompt')
                    if prompt then
                        break
                    end
                end
            end
        end
    end
    if prompt == nil then
        warn(string.format('[RunTerminal] WARNING: %s has no ProximityPrompt, terminal disabled', tostring(kind)))
        return setmetatable({
            Kind = kind,
            Part = part,
            Prompt = nil,
            Disabled = true,
        }, RunTerminal)
    end

    warn(string.format('[RunTerminal] %s: found ProximityPrompt "%s"', kind, prompt.Name))

    return setmetatable({
        Kind = kind,
        Part = part,
        Prompt = prompt,
    }, RunTerminal)
end

function RunTerminal:bind(callback)
    if self.Disabled then
        warn(string.format('[RunTerminal] %s is disabled, cannot bind', self.Kind))
        return function() end
    end
    warn(string.format('[RunTerminal] Binding %s prompt...', self.Kind))
    return self.Prompt.Triggered:Connect(function(player)
        warn(string.format('[RunTerminal] %s triggered by %s', self.Kind, player.DisplayName))
        callback(player)
    end)
end

function RunTerminal:isPlayerNear(player, distanceBuffer)
    local character = player.Character
    local rootPart = character and character:FindFirstChild('HumanoidRootPart')
    if not rootPart or not rootPart:IsA('BasePart') then
        return false
    end

    local maxDistance = self.Prompt.MaxActivationDistance + (distanceBuffer or 0)
    return (rootPart.Position - self.Part.Position).Magnitude <= maxDistance
end

return RunTerminal
