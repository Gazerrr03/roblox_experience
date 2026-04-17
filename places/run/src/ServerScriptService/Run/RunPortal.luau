local RunPortal = {}
RunPortal.__index = RunPortal

RunPortal.Kind = table.freeze({
    MazeGate = 'MazeGate',
})

function RunPortal.new(kind, part)
    local prompt = part:FindFirstChildOfClass('ProximityPrompt')
    if prompt == nil then
        error(string.format('Run portal %s is missing a ProximityPrompt.', tostring(kind)), 0)
    end

    return setmetatable({
        Kind = kind,
        Part = part,
        Prompt = prompt,
    }, RunPortal)
end

function RunPortal:bind(callback)
    return self.Prompt.Triggered:Connect(callback)
end

function RunPortal:isPlayerNear(player, distanceBuffer)
    local character = player.Character
    local rootPart = character and character:FindFirstChild('HumanoidRootPart')
    if not rootPart or not rootPart:IsA('BasePart') then
        return false
    end

    local maxDistance = self.Prompt.MaxActivationDistance + (distanceBuffer or 0)
    return (rootPart.Position - self.Part.Position).Magnitude <= maxDistance
end

return RunPortal
