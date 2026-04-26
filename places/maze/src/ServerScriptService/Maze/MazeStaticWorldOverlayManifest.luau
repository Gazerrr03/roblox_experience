local function freezeRoomDefinition(definition)
    return table.freeze({
        RoomType = definition.RoomType,
        IsCamp = definition.IsCamp or false,
        DifficultyTier = definition.DifficultyTier or 1,
        MonsterBudget = definition.MonsterBudget or 0,
        LootBudget = definition.LootBudget or 0,
        RoomTemplateId = definition.RoomTemplateId or definition.RoomType,
        RoomCategory = definition.RoomCategory or definition.RoomType,
        EncounterRole = definition.EncounterRole,
        PayoffHintId = definition.PayoffHintId,
    })
end

local function freezeChainStep(definition)
    return table.freeze({
        StepId = definition.StepId,
        TargetId = definition.TargetId,
        PayoffHintId = definition.PayoffHintId,
    })
end

local MazeStaticWorldOverlayManifest = table.freeze({
    FirstPlayableChain = table.freeze({
        freezeChainStep({
            StepId = 'EntryBuffer',
            TargetId = 'Room_Camp',
        }),
        freezeChainStep({
            StepId = 'Warning',
            TargetId = 'Room_Loot',
        }),
        freezeChainStep({
            StepId = 'PagesTemptation',
            TargetId = 'Room_Loot',
        }),
        freezeChainStep({
            StepId = 'SoundPredatorPayoff',
            TargetId = 'Room_Loot',
            PayoffHintId = 'sound-predator',
        }),
        freezeChainStep({
            StepId = 'ReturnDecision',
            TargetId = 'ReturnHoldPad',
        }),
    }),
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
            EncounterRole = 'EntryBuffer',
        }),
        Room_Loot = freezeRoomDefinition({
            RoomType = 'DeadEnd',
            DifficultyTier = 2,
            MonsterBudget = 2,
            LootBudget = 1,
            RoomTemplateId = 'SearchCluster',
            RoomCategory = 'SearchCluster',
            EncounterRole = 'WarningPayoffResourceTemptation',
            PayoffHintId = 'sound-predator',
        }),
    }),
    RequiredInteractionNodes = table.freeze({
        'LootPrompt',
        'LootSocket_1',
        'Doorway_East',
    }),
})

return MazeStaticWorldOverlayManifest
