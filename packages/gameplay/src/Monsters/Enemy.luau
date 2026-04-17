local BaseEnemy = require(script.Parent.BaseEnemy)
local EnemyBlackboard = require(script.Parent.EnemyBlackboard)
local EnemyStateMachine = require(script.Parent.EnemyStateMachine)

local AttackComponent = require(script.Parent.Components.AttackComponent)
local MovementComponent = require(script.Parent.Components.MovementComponent)
local PerceptionComponent = require(script.Parent.Components.PerceptionComponent)

local Enemy = {}
Enemy.__index = Enemy
setmetatable(Enemy, { __index = BaseEnemy })

local UPDATE_ORDER = table.freeze({
    'Perception',
    'FSM',
    'Movement',
    'Attack',
})

local function defaultComponents()
    return {
        Perception = PerceptionComponent.new(),
        Movement = MovementComponent.new(),
        Attack = AttackComponent.new(),
    }
end

local function cloneContext(context)
    return table.clone(context or {})
end

function Enemy.new(definition, options)
    local enemyOptions = options or {}
    local blackboard = enemyOptions.Blackboard or EnemyBlackboard.new(definition)
    local stateMachine = enemyOptions.StateMachine or EnemyStateMachine.new()
    local components = enemyOptions.Components or defaultComponents()

    local self = setmetatable({
        Blackboard = blackboard,
        ComponentConfig = enemyOptions.ComponentConfig or {},
        StateMachine = stateMachine,
        Components = components,
        StageObserver = enemyOptions.StageObserver,
    }, Enemy)

    self:setupHealth(self.ComponentConfig)
    return self
end

function Enemy:_emitStage(stageName)
    if self.StageObserver then
        self.StageObserver(stageName, self.Blackboard)
    end
end

function Enemy:spawn()
    self.Blackboard:setState(self.StateMachine:getState())
    for _, component in pairs(self.Components) do
        if component.init then
            component:init(self.Blackboard)
        end
    end
end

function Enemy:update(dt, context)
    local blackboardContext = cloneContext(context)
    blackboardContext.ComponentConfig = self.ComponentConfig
    self.Blackboard:beginTick(blackboardContext)

    self:_emitStage('Perception')
    self.Components.Perception:update(self.Blackboard, dt)

    self:_emitStage('FSM')
    self.StateMachine:update(self.Blackboard)

    self:_emitStage('Movement')
    self.Components.Movement:update(self.Blackboard, dt)

    self:_emitStage('Attack')
    self.Components.Attack:update(self.Blackboard, dt)

    if self.Components.Health then
        self.Components.Health:update(self.Blackboard, dt)
    end

    return {
        AttackIntent = self.Blackboard.Transient.AttackIntent,
        State = self.Blackboard:getState(),
        TargetPlayer = self.Blackboard.Transient.TargetPlayer,
        NextPosition = self.Blackboard.Transient.NextPosition,
        ShouldAdvancePatrol = self.Blackboard.Transient.ShouldAdvancePatrol == true,
        DesiredAnimation = self.Blackboard.Transient.DesiredAnimation or 'Idle',
        DesiredAnimationSpeed = self.Blackboard.Transient.DesiredAnimationSpeed or 1,
        ShouldPlayChaseLoop = self.Blackboard.Transient.ShouldPlayChaseLoop == true,
        TravelOffset = self.Blackboard.Transient.TravelOffset or Vector3.zero,
        IsDead = self.Components.Health and self.Components.Health:isDead() or false,
        DeathEvent = self.Blackboard.Transient.DeathEvent,
    }
end

function Enemy:destroy()
    for _, component in pairs(self.Components) do
        if component.destroy then
            component:destroy(self.Blackboard)
        end
    end
end

Enemy.UpdateOrder = UPDATE_ORDER

return Enemy
