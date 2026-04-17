--!strict
-- Binds the active RunSessionService for Run-local modules (e.g. ItemFunctionality) that need InventoryService.

export type BoundService = {
    IsLaunched: boolean,
    InventoryService: any,
    _broadcastSnapshot: (self: BoundService) -> (),
}

local bound: BoundService? = nil

local RunInventoryBridge = {}

function RunInventoryBridge.bind(service: BoundService)
    bound = service
end

function RunInventoryBridge.get(): BoundService?
    return bound
end

return RunInventoryBridge
