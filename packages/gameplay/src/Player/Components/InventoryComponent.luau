local InventoryComponent = {}
InventoryComponent.__index = InventoryComponent

local function getComponentConfig(blackboard, componentName)
    local context = if type(blackboard) == 'table' and type(blackboard.Context) == 'table'
        then blackboard.Context
        else {}
    local componentConfig = if type(context.ComponentConfig) == 'table'
        then context.ComponentConfig
        else {}
    local config = componentConfig[componentName]

    if type(config) == 'table' then
        return config
    end

    return {}
end

function InventoryComponent.new()
    return setmetatable({}, InventoryComponent)
end

-- Player-local inventory *attributes* only (slot count, pickup range).
-- Authoritative items and equip/held state live in `Gameplay.Inventory` via
-- `InventoryService`; this component must not mirror item instances.
function InventoryComponent:init(blackboard)
    local config = getComponentConfig(blackboard, 'Inventory')

    self.SlotCount = config.SlotCount or 8
    self.InteractionRange = config.InteractionRange or 5
end

function InventoryComponent:update(blackboard, _dt)
    blackboard.Transient.SlotCount = self.SlotCount
    blackboard.Transient.InteractionRange = self.InteractionRange
end

function InventoryComponent:destroy(_blackboard) end

return InventoryComponent
