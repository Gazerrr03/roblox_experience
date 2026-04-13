local MazeInteractionRegistry = {}
MazeInteractionRegistry.__index = MazeInteractionRegistry

function MazeInteractionRegistry.new()
    return setmetatable({
        Connections = {},
    }, MazeInteractionRegistry)
end

function MazeInteractionRegistry:_track(connection)
    if connection ~= nil then
        table.insert(self.Connections, connection)
    end
end

function MazeInteractionRegistry:bindScene(scene, handlers)
    self:_track(scene.ReturnHoldPad:bind(function(player)
        handlers.OnReturnHold(player)
    end))

    for extractionNodeId, extractionNode in pairs(scene.ExtractionNodes) do
        self:_track(extractionNode:bind(function(player)
            handlers.OnExtraction(player, extractionNodeId)
        end))
    end

    for roomId, lootNode in pairs(scene.LootNodes) do
        self:_track(lootNode:bind(function(player)
            handlers.OnLoot(player, roomId)
        end))
    end

    for doorwayId, doorway in pairs(scene.Doorways) do
        self:_track(doorway:bind(function(player)
            handlers.OnDoor(player, doorwayId)
        end))
    end
end

function MazeInteractionRegistry:disconnectAll()
    for _, connection in ipairs(self.Connections) do
        connection:Disconnect()
    end
    table.clear(self.Connections)
end

return MazeInteractionRegistry
