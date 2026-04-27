local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Packages = ReplicatedStorage:WaitForChild('Packages')
local Gameplay = require(Packages:WaitForChild('Gameplay'))

local Player = Gameplay.Player.Player
local PlayerComponentConfig = Gameplay.Player.PlayerComponentConfig
local HealthComponent = Gameplay.Player.HealthComponent
local StaminaComponent = Gameplay.Player.StaminaComponent
local MovementComponent = Gameplay.Player.MovementComponent
local InventoryComponent = Gameplay.Player.InventoryComponent
local PlayersConfig = Gameplay.Config.Players

local PlayerService = {}
PlayerService.__index = PlayerService

function PlayerService.new(playerDefinition)
    local definition = playerDefinition or PlayersConfig.DefaultPlayer

    return setmetatable({
        ByUserId = {},
        Definition = definition,
        ComponentConfig = PlayerComponentConfig.fromDefinition(definition),
    }, PlayerService)
end

function PlayerService:addPlayer(player)
    local options = {
        Blackboard = nil,
        StateMachine = nil,
        Components = {
            Health = HealthComponent.new(),
            Stamina = StaminaComponent.new(),
            Movement = MovementComponent.new(),
            Inventory = InventoryComponent.new(),
        },
        ComponentConfig = self.ComponentConfig,
    }

    local p = Player.new(self.Definition, options)
    p:spawn()

    self.ByUserId[player.UserId] = p
    return p
end

function PlayerService:removePlayer(player)
    local p = self.ByUserId[player.UserId]
    if p then
        p:destroy()
    end
    self.ByUserId[player.UserId] = nil
end

function PlayerService:get(player)
    return self.ByUserId[player.UserId]
end

function PlayerService:applyDamage(player, damageKind)
    local p = self:get(player)
    if not p then
        return false, 'MissingPlayer'
    end

    local health = p.Components.Health
    return health:applyDamage(p.Blackboard, damageKind)
end

function PlayerService:healHealthPips(player, amount)
    local p = self:get(player)
    if not p then
        return false, 'MissingPlayer'
    end

    local health = p.Components.Health
    return health:healPips(p.Blackboard, amount)
end

function PlayerService:setSprinting(player, isSprinting)
    local p = self:get(player)
    if not p then
        return false, 'MissingPlayer'
    end

    local stamina = p.Components.Stamina
    return stamina:setSprinting(p.Blackboard, isSprinting)
end

function PlayerService:getSummary(player)
    local p = self:get(player)
    if not p then
        return nil
    end

    local health = p.Components.Health
    local stamina = p.Components.Stamina
    local activeEffects = {}
    if type(p.Blackboard) == 'table' and type(p.Blackboard.ActiveEffects) == 'table' then
        for effectId, effectState in pairs(p.Blackboard.ActiveEffects) do
            if effectState then
                activeEffects[effectId] = effectState
            end
        end
    end

    return {
        UserId = player.UserId,
        Health = {
            CurrentHealthPips = health.CurrentHealthPips,
            MaxHealthPips = health.MaxHealthPips,
            IsDead = health.IsDead,
            CorpseActive = health.CorpseActive,
        },
        Stamina = {
            CurrentStamina = stamina.CurrentStamina,
            MaxStamina = stamina.MaxStamina,
            CanSprint = stamina.CanSprint,
            IsSprinting = stamina.IsSprinting,
        },
        State = p.StateMachine:getState(),
        SlotCount = p.Components.Inventory.SlotCount,
        InteractionRange = p.Components.Inventory.InteractionRange,
        -- Backward compatibility: movement/control services still expect the flat player-state shape.
        CurrentHealthPips = health.CurrentHealthPips,
        MaxHealthPips = health.MaxHealthPips,
        CurrentStamina = stamina.CurrentStamina,
        MaxStamina = stamina.MaxStamina,
        IsDead = health.IsDead,
        CanSprint = stamina.CanSprint,
        CorpseActive = health.CorpseActive,
        ActiveEffects = activeEffects,
        -- Backward compatibility: mirrors PlayerStateService:getSummary format
        PlayerState = {
            HealthPips = health.CurrentHealthPips,
            MaxHealthPips = health.MaxHealthPips,
            CurrentStamina = stamina.CurrentStamina,
            MaxStamina = stamina.MaxStamina,
            IsDead = health.IsDead,
            CanSprint = stamina.CanSprint,
            CorpseActive = health.CorpseActive,
            ActiveEffects = activeEffects,
        },
    }
end

function PlayerService:update(player, dt, context)
    local p = self:get(player)
    if not p then
        return nil
    end

    return p:update(dt, context)
end

function PlayerService:reset()
    for userId, p in pairs(self.ByUserId) do
        p:destroy()
        self.ByUserId[userId] = nil
    end
end

return PlayerService
