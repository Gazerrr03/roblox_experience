local MonsterBehaviorCatalog = require(script.Parent.Parent.MonsterBehaviorCatalog)

local AttackComponent = {}
AttackComponent.__index = AttackComponent

local DEFAULT_ATTACK_ARC_DEGREES = 100
local DEFAULT_ATTACK_COOLDOWN_SECONDS = 1
local DEFAULT_ATTACK_DAMAGE_PIPS = 1
local DEFAULT_ATTACK_MARKER_NAME = 'Hit'
local DEFAULT_ATTACK_RANGE = 4

local function readAttackConfig(context)
    local componentConfig = context.ComponentConfig
    if type(componentConfig) == 'table' and type(componentConfig.Attack) == 'table' then
        return componentConfig.Attack
    end

    return {}
end

function AttackComponent.new()
    return setmetatable({
        CooldownRemaining = 0,
    }, AttackComponent)
end

function AttackComponent:init(_blackboard)
    self.CooldownRemaining = 0
end

function AttackComponent:update(blackboard, dt)
    local deltaTime = math.max(0, dt or 0)
    self.CooldownRemaining = math.max(0, self.CooldownRemaining - deltaTime)

    blackboard.Transient.AttackIntent = nil
    local behaviors = blackboard.Context.Behaviors or {}
    if not behaviors[MonsterBehaviorCatalog.Behavior.Attack] then
        return
    end

    local hasTarget = blackboard.Transient.HasTarget == true
    if not hasTarget then
        return
    end

    local currentPosition = blackboard.Context.CurrentPosition
    local targetPlayer = blackboard.Transient.TargetPlayer
    local targetPosition = blackboard.Transient.TargetPosition
    if
        typeof(currentPosition) ~= 'Vector3'
        or targetPlayer == nil
        or typeof(targetPosition) ~= 'Vector3'
    then
        return
    end

    local attackConfig = readAttackConfig(blackboard.Context)
    local attackRange = attackConfig.Range or DEFAULT_ATTACK_RANGE
    if (targetPosition - currentPosition).Magnitude > attackRange then
        return
    end

    if self.CooldownRemaining > 0 then
        return
    end

    self.CooldownRemaining = attackConfig.CooldownSeconds or DEFAULT_ATTACK_COOLDOWN_SECONDS
    blackboard.Transient.AttackIntent = {
        ArcDegrees = attackConfig.ArcDegrees or DEFAULT_ATTACK_ARC_DEGREES,
        DamagePips = attackConfig.DamagePips or DEFAULT_ATTACK_DAMAGE_PIPS,
        MarkerName = attackConfig.HitMarkerName or DEFAULT_ATTACK_MARKER_NAME,
        Range = attackRange,
        TargetPlayer = targetPlayer,
    }
end

function AttackComponent:destroy(_blackboard) end

return AttackComponent
