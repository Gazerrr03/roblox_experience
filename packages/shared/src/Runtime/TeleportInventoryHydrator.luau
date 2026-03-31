local TeleportInventoryHydrator = {}

function TeleportInventoryHydrator.hydratePlayerInventory(
    inventoryService,
    player,
    teleportData,
    findPlayerInventory
)
    local inventorySummary = findPlayerInventory(teleportData, player.UserId)
    if inventorySummary == nil then
        return false
    end

    local loaded = inventoryService:loadSummary(player, inventorySummary)
    return loaded == true
end

return TeleportInventoryHydrator
