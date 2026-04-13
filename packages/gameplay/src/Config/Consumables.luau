-- Maze consumables (shared Items merge). Ids use lowercase hyphen style.
local Consumables = {
    ['consumable-healing-potion'] = {
        Id = 'consumable-healing-potion',
        Name = 'Healing Potion',
        Description = '治疗药水 — Restores 1 health pip. Maze only. Consumed on use.',
        Weight = 1,
        Value = 2,
        Color = Color3.fromRGB(168, 120, 200),
        IsEquipable = true,
        ItemKind = 'Consumable',
        ConsumableEffect = 'HealOnePip',
        MaxCarryPerId = 3,
    },
}

return Consumables
