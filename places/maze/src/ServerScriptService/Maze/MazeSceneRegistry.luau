local MazeSceneRegistry = {}
MazeSceneRegistry.__index = MazeSceneRegistry

function MazeSceneRegistry.new(entries)
    return setmetatable({
        RoomsById = entries.RoomsById or {},
        LootNodes = entries.LootNodes or {},
        ExtractionNodes = entries.ExtractionNodes or {},
        Doorways = entries.Doorways or {},
    }, MazeSceneRegistry)
end

function MazeSceneRegistry:getRoom(roomId)
    return self.RoomsById[roomId]
end

function MazeSceneRegistry:getLootNode(roomId)
    return self.LootNodes[roomId]
end

function MazeSceneRegistry:getExtractionNode(extractionNodeId)
    return self.ExtractionNodes[extractionNodeId]
end

function MazeSceneRegistry:getDoor(doorwayId)
    return self.Doorways[doorwayId]
end

return MazeSceneRegistry
