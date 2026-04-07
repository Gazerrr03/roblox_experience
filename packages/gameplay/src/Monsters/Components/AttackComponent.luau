local AttackComponent = {}
AttackComponent.__index = AttackComponent

function AttackComponent.new()
    return setmetatable({}, AttackComponent)
end

function AttackComponent:init(_blackboard) end

function AttackComponent:update(blackboard, _dt)
    -- #177 only wires the execution slot. Real damage/marker logic lands in #179.
    blackboard.Transient.AttackIntent = nil
end

function AttackComponent:destroy(_blackboard) end

return AttackComponent
