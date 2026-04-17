local RunTerminal = {}
RunTerminal.__index = RunTerminal

function RunTerminal.new(kind, part)
    local prompt = part:FindFirstChildOfClass('ProximityPrompt')
    if prompt == nil then
        error(string.format('Run terminal %s is missing a ProximityPrompt.', tostring(kind)), 0)
    end

    return setmetatable({
        Kind = kind,
        Part = part,
        Prompt = prompt,
    }, RunTerminal)
end

function RunTerminal:bind(callback)
    return self.Prompt.Triggered:Connect(callback)
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
