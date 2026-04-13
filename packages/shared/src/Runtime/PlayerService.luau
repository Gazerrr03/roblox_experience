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

function PlayerService:applyHealPips(player, deltaPips)
    local p = self:get(player)
    if not p then
        return false, 'MissingPlayer'
    end

    local health = p.Components.Health
    return health:applyHealPips(p.Blackboard, deltaPips)
end

function PlayerService:setSprinting(player, isSprinting)
    local p = self:get(player)
    if not p then
        return false, 'MissingPlayer'
    end

    local stamina = p.Components.Stamina
    return stamina:setSprinting(p.Blackboard, isSprinting)
end

function PlayerService:addItem(player, itemDef)
    local p = self:get(player)
    if not p then
        return false, 'MissingPlayer'
    end

    local inventory = p.Components.Inventory
    return inventory:addItem(p.Blackboard, itemDef)
end

function PlayerService:equipSlot(player, slotIndex)
    local p = self:get(player)
    if not p then
        return false, 'MissingPlayer'
    end

    local inventory = p.Components.Inventory
    return inventory:equipSlot(p.Blackboard, slotIndex)
end

function PlayerService:unequip(player)
    local p = self:get(player)
    if not p then
        return false, 'MissingPlayer'
    end

    local inventory = p.Components.Inventory
    return inventory:unequip(p.Blackboard)
end

function PlayerService:useItem(player)
    local p = self:get(player)
    if not p then
        return false, 'MissingPlayer'
    end

    local inventory = p.Components.Inventory
    return inventory:useItem(p.Blackboard)
end

function PlayerService:getSummary(player)
    local p = self:get(player)
    if not p then
        return nil
    end

    return {
        UserId = player.UserId,
        Health = {
            CurrentHealthPips = p.Components.Health.CurrentHealthPips,
            MaxHealthPips = p.Components.Health.MaxHealthPips,
            IsDead = p.Components.Health.IsDead,
            CorpseActive = p.Components.Health.CorpseActive,
        },
        Stamina = {
            CurrentStamina = p.Components.Stamina.CurrentStamina,
            MaxStamina = p.Components.Stamina.MaxStamina,
            CanSprint = p.Components.Stamina.CanSprint,
            IsSprinting = p.Components.Stamina.IsSprinting,
        },
        State = p.StateMachine:getState(),
        Slots = p.Components.Inventory.Slots,
        EquippedSlot = p.Components.Inventory.EquippedSlot,
        -- Backward compatibility: mirrors PlayerStateService:getSummary format
        PlayerState = {
            HealthPips = p.Components.Health.CurrentHealthPips,
            MaxHealthPips = p.Components.Health.MaxHealthPips,
            CurrentStamina = p.Components.Stamina.CurrentStamina,
            MaxStamina = p.Components.Stamina.MaxStamina,
            IsDead = p.Components.Health.IsDead,
            CanSprint = p.Components.Stamina.CanSprint,
            CorpseActive = p.Components.Health.CorpseActive,
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
