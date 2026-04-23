local function freezeRoomDefinition(definition)
    return table.freeze({
        RoomType = definition.RoomType,
        IsCamp = definition.IsCamp or false,
        DifficultyTier = definition.DifficultyTier or 1,
        MonsterBudget = definition.MonsterBudget or 0,
        LootBudget = definition.LootBudget or 0,
        RoomTemplateId = definition.RoomTemplateId or definition.RoomType,
        RoomCategory = definition.RoomCategory or definition.RoomType,
    })
end

local MazeStaticWorldOverlayManifest = table.freeze({
    RootParts = table.freeze({
        'SpawnMarker',
        'ReturnHoldPad',
    }),
    Rooms = table.freeze({
        Room_Camp = freezeRoomDefinition({
            RoomType = 'OpenHub',
            IsCamp = true,
            DifficultyTier = 0,
            RoomTemplateId = 'CampHub',
            RoomCategory = 'CampHub',
        }),
        Room_Loot = freezeRoomDefinition({
            RoomType = 'DeadEnd',
            DifficultyTier = 2,
            MonsterBudget = 2,
            LootBudget = 1,
            RoomTemplateId = 'SearchCluster',
            RoomCategory = 'SearchCluster',
        }),
    }),
    RequiredInteractionNodes = table.freeze({
        'LootPrompt',
        'LootSocket_1',
        'Doorway_East',
    }),
})

return MazeStaticWorldOverlayManifest
