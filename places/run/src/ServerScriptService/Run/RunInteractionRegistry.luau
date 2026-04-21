local RunInteractionRegistry = {}
RunInteractionRegistry.__index = RunInteractionRegistry

function RunInteractionRegistry.new()
    return setmetatable({
        Connections = {},
    }, RunInteractionRegistry)
end

function RunInteractionRegistry:_track(connection)
    if connection ~= nil then
        table.insert(self.Connections, connection)
    end
end

function RunInteractionRegistry:bindScene(scene, handlers)
    self:_track(scene.Terminals.Shop:bind(function(player)
        handlers.OnShop(player)
    end))
    self:_track(scene.Terminals.Objective:bind(function(player)
        handlers.OnObjective(player)
    end))
    self:_track(scene.Terminals.Gate:bind(function(player)
        handlers.OnGate(player)
    end))
    if scene.Terminals.StartGame then
        self:_track(scene.Terminals.StartGame:bind(function(player)
            handlers.OnStartGame(player)
        end))
    end
    self:_track(scene.MazePortal:bind(function(player)
        handlers.OnMazePortal(player)
    end))

    for _, clueMarker in ipairs(scene.ClueMarkers or {}) do
        self:_track(clueMarker:bind(function(player, marker)
            handlers.OnClueMarker(player, marker)
        end))
    end

    for _, oceanTrigger in ipairs(scene.OceanTriggers or {}) do
        self:_track(oceanTrigger:bind(function(player, state)
            handlers.OnOceanEntered(player, state)
        end))
    end
end

function RunInteractionRegistry:disconnectAll()
    for _, connection in ipairs(self.Connections) do
        connection:Disconnect()
    end
    table.clear(self.Connections)
end

return RunInteractionRegistry
