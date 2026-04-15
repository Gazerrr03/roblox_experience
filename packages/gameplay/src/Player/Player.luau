local PlayerBlackboard = require(script.Parent.PlayerBlackboard)
local PlayerStateMachine = require(script.Parent.PlayerStateMachine)

local Player = {}
Player.__index = Player

local UPDATE_ORDER = table.freeze({
    'Health',
    'Stamina',
    'Movement',
    'Inventory',
})

local function cloneContext(context)
    return table.clone(context or {})
end

function Player.new(definition, options)
    local playerOptions = options or {}
    local blackboard = playerOptions.Blackboard or PlayerBlackboard.new(definition)
    local stateMachine = playerOptions.StateMachine or PlayerStateMachine.new()
    local components = playerOptions.Components or {}

    return setmetatable({
        Blackboard = blackboard,
        ComponentConfig = playerOptions.ComponentConfig or {},
        StateMachine = stateMachine,
        Components = components,
        StageObserver = playerOptions.StageObserver,
    }, Player)
end

function Player:_emitStage(stageName)
    if self.StageObserver then
        self.StageObserver(stageName, self.Blackboard)
    end
end

function Player:spawn()
    self.Blackboard:setState(self.StateMachine:getState())
    self.Blackboard:beginTick({
        ComponentConfig = self.ComponentConfig,
    })
    for _, component in pairs(self.Components) do
        if component.init then
            component:init(self.Blackboard)
        end
    end
end

function Player:update(dt, context)
    local blackboardContext = cloneContext(context)
    blackboardContext.ComponentConfig = self.ComponentConfig
    self.Blackboard:beginTick(blackboardContext)

    self:_emitStage('Health')
    if self.Components.Health then
        self.Components.Health:update(self.Blackboard, dt)
    end

    self:_emitStage('Stamina')
    if self.Components.Stamina then
        self.Components.Stamina:update(self.Blackboard, dt)
    end

    self:_emitStage('FSM')
    self.StateMachine:update(self.Blackboard)

    self:_emitStage('Movement')
    if self.Components.Movement then
        self.Components.Movement:update(self.Blackboard, dt)
    end

    self:_emitStage('Inventory')
    if self.Components.Inventory then
        self.Components.Inventory:update(self.Blackboard, dt)
    end

    return {
        State = self.Blackboard:getState(),
        Health = {
            CurrentHealthPips = self.Blackboard.Transient.CurrentHealthPips,
            MaxHealthPips = self.Blackboard.Transient.MaxHealthPips,
            IsDead = self.Blackboard.Transient.IsDead == true,
        },
        Stamina = {
            CurrentStamina = self.Blackboard.Transient.CurrentStamina,
            MaxStamina = self.Blackboard.Transient.MaxStamina,
            CanSprint = self.Blackboard.Transient.CanSprint ~= false,
        },
        Movement = {
            NextPosition = self.Blackboard.Transient.NextPosition,
            DesiredAnimation = self.Blackboard.Transient.DesiredAnimation or 'Idle',
        },
        Inventory = {
            Slots = self.Blackboard.Transient.Slots,
            EquippedSlot = self.Blackboard.Transient.EquippedSlot,
        },
    }
end

function Player:destroy()
    for _, component in pairs(self.Components) do
        if component.destroy then
            component:destroy(self.Blackboard)
        end
    end
end

Player.UpdateOrder = UPDATE_ORDER

return Player
