local MazeExtractionNode = {}
MazeExtractionNode.__index = MazeExtractionNode

function MazeExtractionNode.new(rawNode)
    return setmetatable(rawNode, MazeExtractionNode)
end

function MazeExtractionNode:bind(callback)
    return self.Prompt.Triggered:Connect(callback)
end

return MazeExtractionNode
