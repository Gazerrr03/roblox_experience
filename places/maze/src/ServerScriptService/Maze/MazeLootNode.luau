local MazeLootNode = {}
MazeLootNode.__index = MazeLootNode

function MazeLootNode.new(roomId, rawNode)
    rawNode.RoomId = roomId
    return setmetatable(rawNode, MazeLootNode)
end

function MazeLootNode:bind(callback)
    if self.Prompt == nil then
        return nil
    end

    return self.Prompt.Triggered:Connect(callback)
end

function MazeLootNode:markCollected()
    self.Collected = true

    local promptPart = self.Prompt and self.Prompt.Parent
    if promptPart then
        promptPart:Destroy()
    end

    self.Prompt = nil
end

return MazeLootNode
