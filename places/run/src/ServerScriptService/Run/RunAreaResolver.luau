local RunAreaResolver = {}
RunAreaResolver.__index = RunAreaResolver

function RunAreaResolver.new(scene)
    return setmetatable({
        Scene = scene,
    }, RunAreaResolver)
end

function RunAreaResolver:getAreaForPosition(position)
    if position.Z >= self.Scene.OutdoorThresholdZ then
        return 'Wilderness'
    end

    return 'Temple Hall'
end

return RunAreaResolver
