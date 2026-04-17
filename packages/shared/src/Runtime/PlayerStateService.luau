local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Packages = ReplicatedStorage:WaitForChild('Packages')
local Gameplay = require(Packages:WaitForChild('Gameplay'))

local PlayerState = Gameplay.PlayerState

local PlayerStateService = {}
PlayerStateService.__index = PlayerStateService

local function buildDefaultSummary()
    return PlayerState.new():getSummary()
end

function PlayerStateService.new(config)
    return setmetatable({
        ByUserId = {},
        Config = config,
        DefaultSummary = buildDefaultSummary(),
    }, PlayerStateService)
end

function PlayerStateService:addPlayer(player)
    local state = PlayerState.new(self.Config)
    self.ByUserId[player.UserId] = state
    return state
end

function PlayerStateService:removePlayer(player)
    self.ByUserId[player.UserId] = nil
end

function PlayerStateService:get(player)
    return self.ByUserId[player.UserId]
end

function PlayerStateService:getSummary(player)
    local state = self:get(player)
    if not state then
        return table.clone(self.DefaultSummary)
    end

    return state:getSummary()
end

function PlayerStateService:applyDamage(player, damageKind)
    local state = self:get(player)
    if not state then
        return false, 'MissingPlayerState'
    end

    return state:applyDamage(damageKind)
end

function PlayerStateService:applyEffect(player, effectId, durationSeconds)
    local state = self:get(player)
    if not state then
        return
    end

    state:applyEffect(effectId, durationSeconds)
end

function PlayerStateService:hasEffect(player, effectId)
    local state = self:get(player)
    if not state then
        return false
    end

    return state:hasEffect(effectId)
end

function PlayerStateService:setSprinting(player, isSprinting)
    local state = self:get(player)
    if not state then
        return false, 'MissingPlayerState'
    end

    return state:setSprinting(isSprinting)
end

function PlayerStateService:step(dt)
    for _, state in pairs(self.ByUserId) do
        state:step(dt)
    end
end

function PlayerStateService:reset()
    table.clear(self.ByUserId)
end

return PlayerStateService
