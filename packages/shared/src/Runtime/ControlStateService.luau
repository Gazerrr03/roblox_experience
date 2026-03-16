local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Packages = ReplicatedStorage:WaitForChild('Packages')
local Gameplay = require(Packages:WaitForChild('Gameplay'))

local ControlState = Gameplay.ControlState

local ControlStateService = {}
ControlStateService.__index = ControlStateService

local function buildDefaultSummary()
    return ControlState.new():getSummary()
end

function ControlStateService.new()
    return setmetatable({
        ByUserId = {},
        DefaultSummary = buildDefaultSummary(),
    }, ControlStateService)
end

function ControlStateService:addPlayer(player)
    local state = ControlState.new()
    self.ByUserId[player.UserId] = state
    return state
end

function ControlStateService:removePlayer(player)
    self.ByUserId[player.UserId] = nil
end

function ControlStateService:get(player)
    return self.ByUserId[player.UserId]
end

function ControlStateService:getSummary(player)
    local state = self:get(player)
    if not state then
        return table.clone(self.DefaultSummary)
    end

    return state:getSummary()
end

function ControlStateService:requestSprintStart(player, playerStateSummary)
    local state = self:get(player)
    if not state then
        return false, 'MissingControlState'
    end

    return state:requestSprintStart(playerStateSummary)
end

function ControlStateService:requestSprintStop(player)
    local state = self:get(player)
    if not state then
        return false, 'MissingControlState'
    end

    return state:requestSprintStop()
end

function ControlStateService:syncPlayerState(player, playerStateSummary)
    local state = self:get(player)
    if not state then
        return false, 'MissingControlState'
    end

    return true, state:syncPlayerState(playerStateSummary)
end

function ControlStateService:reset()
    table.clear(self.ByUserId)
end

return ControlStateService
