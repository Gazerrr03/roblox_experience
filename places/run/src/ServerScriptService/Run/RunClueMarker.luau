local RunClueMarker = {}
RunClueMarker.__index = RunClueMarker

function RunClueMarker.new(part)
    local prompt = part:FindFirstChildOfClass('ProximityPrompt')
    if prompt == nil then
        error(string.format('Run clue marker %s is missing a ProximityPrompt.', part.Name), 0)
    end

    local clueId = part:GetAttribute('ClueId') or part.Name
    local sourceMarkerId = part:GetAttribute('SourceMarkerId') or part.Name
    local readableTitle = part:GetAttribute('ReadableTitle')
        or part:GetAttribute('Title')
        or part.Name
    local readableText = part:GetAttribute('ReadableText')
        or part:GetAttribute('Body')
        or 'A weathered note hints that the maze threat is never where it first wants you to look.'
    local threatHintId = part:GetAttribute('ThreatHintId')
    local itemName = part:GetAttribute('ItemName') or readableTitle

    return setmetatable({
        Part = part,
        Prompt = prompt,
        ClueId = tostring(clueId),
        SourceMarkerId = tostring(sourceMarkerId),
        ReadableTitle = tostring(readableTitle),
        ReadableText = tostring(readableText),
        ThreatHintId = threatHintId and tostring(threatHintId) or nil,
        ItemName = tostring(itemName),
    }, RunClueMarker)
end

function RunClueMarker:bind(callback)
    return self.Prompt.Triggered:Connect(function(player)
        callback(player, self)
    end)
end

return RunClueMarker
