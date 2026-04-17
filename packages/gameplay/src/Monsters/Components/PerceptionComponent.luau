local MonsterBehaviorCatalog = require(script.Parent.Parent.MonsterBehaviorCatalog)
local MonsterLogic = require(script.Parent.Parent.MonsterLogic)

local PerceptionComponent = {}
PerceptionComponent.__index = PerceptionComponent

function PerceptionComponent.new()
    return setmetatable({}, PerceptionComponent)
end

function PerceptionComponent:init(_blackboard) end

function PerceptionComponent:update(blackboard, _dt)
    local componentConfig = blackboard.Context.ComponentConfig
    local perceptionConfig = if type(componentConfig) == 'table'
            and type(componentConfig.Perception) == 'table'
        then componentConfig.Perception
        else {}

    local behaviors = blackboard.Context.Behaviors or {}
    if not behaviors[MonsterBehaviorCatalog.Behavior.SenseNearestTarget] then
        blackboard.Transient.HasTarget = false
        blackboard.Transient.TargetPlayer = nil
        blackboard.Transient.TargetPosition = nil
        return
    end

    local currentPosition = blackboard.Context.CurrentPosition
    if typeof(currentPosition) ~= 'Vector3' then
        blackboard.Transient.HasTarget = false
        blackboard.Transient.TargetPlayer = nil
        blackboard.Transient.TargetPosition = nil
        return
    end

    local playerPositions = blackboard.Context.PlayerPositions or {}
    local sightRange = perceptionConfig.SightRange or blackboard.Context.SightRange
    local targetPlayer =
        MonsterLogic.pickNearestTarget(currentPosition, playerPositions, sightRange)

    blackboard.Transient.HasTarget = targetPlayer ~= nil
    blackboard.Transient.TargetPlayer = targetPlayer
    blackboard.Transient.TargetPosition = if targetPlayer
        then playerPositions[targetPlayer]
        else nil
end

function PerceptionComponent:destroy(_blackboard) end

return PerceptionComponent
