local RunInteractionRegistry = {}
RunInteractionRegistry.__index = RunInteractionRegistry

function RunInteractionRegistry.new()
    return setmetatable({
        Connections = {},
    }, RunInteractionRegistry)
end

function RunInteractionRegistry:_track(connection)
    table.insert(self.Connections, connection)
end

function RunInteractionRegistry:bindScene(scene, handlers)
    self:_track(scene.Terminals.Shop:bind(function(player)
        handlers.OnShop(player)
    end))
    self:_track(scene.Terminals.Sell:bind(function(player)
        handlers.OnSell(player)
    end))
    self:_track(scene.Terminals.Objective:bind(function(player)
        handlers.OnObjective(player)
    end))
    self:_track(scene.Terminals.Loadout:bind(function(player)
        handlers.OnLoadout(player)
    end))
    self:_track(scene.Terminals.UgcLab:bind(function(player)
        handlers.OnUgcLab(player)
    end))
    self:_track(scene.Terminals.Gate:bind(function(player)
        handlers.OnGate(player)
    end))
    self:_track(scene.MazePortal:bind(function(player)
        handlers.OnMazePortal(player)
    end))

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
