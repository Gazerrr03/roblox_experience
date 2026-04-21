return function()
    local ReplicatedStorage = game:GetService('ReplicatedStorage')
    local gameplay = require(ReplicatedStorage:WaitForChild('Packages'):WaitForChild('Gameplay'))
    local shared = require(ReplicatedStorage:WaitForChild('Packages'):WaitForChild('Shared'))
    local ItemFields = gameplay.Config.ItemFields
    local contract = shared.Session.CampMazeSessionContract

    local fixture = {
        InstanceId = 99,
        Id = 'tool-spec-all-fields',
        Name = 'Spec Tool',
        Weight = 2,
        Value = 5,
        Color = Color3.fromRGB(10, 20, 30),
        Light = {
            Brightness = 1.5,
            Range = 20,
            Color = Color3.fromRGB(40, 50, 60),
        },
        Description = 'Spec entry',
        IconAssetId = '123',
        ToolTemplateName = 'ToolSpec',
        ToolCategory = 'SpecCat',
        StateModel = 'Durability',
        InitialState = 10,
        CurrentState = 7,
        ConsumePerUse = 1,
        CooldownSeconds = 0.25,
        LastUsedAt = 1000,
        SwingRange = 5,
        SwingArcDegrees = 60,
        KnockbackStrength = 8,
        MeleeDamage = 2,
        HealHealthPips = 3,
        ItemCategory = 'Clue',
        MissionCount = 0,
        ReadableTitle = 'Threat Note',
        ReadableText = 'The first noise is bait.',
        ClueId = 'threat-note',
        ThreatHintId = 'echo-monster',
        SourceMarkerId = 'ClueMarker_ThreatNote',
    }

    local copy = ItemFields.copyItemEntry(fixture)
    assert(copy ~= nil, 'copyItemEntry should accept a full fixture')
    for _, fieldName in ipairs(ItemFields.ENTRY_FIELD_NAMES) do
        if fieldName == 'Light' then
            assert(
                copy.Light ~= nil and copy.Light.Brightness == fixture.Light.Brightness,
                'Light should be deep-copied for contract parity'
            )
        else
            assert(
                copy[fieldName] == fixture[fieldName],
                string.format('Field %s should round-trip through copyItemEntry', fieldName)
            )
        end
    end

    local campSession = contract.newCampSession({
        SessionId = 'item-fields-spec',
        CampAccessCode = 'item-fields-spec',
    })
    local entered = contract.markPlayerEntered(campSession, {
        UserId = 501,
        Name = 'SpecRunner',
    })
    entered.MazeAccessCode = 'maze-access-item-fields'

    local summary = {
        Capacity = 8,
        Weight = 0,
        Count = 1,
        BackpackCount = 0,
        HeldCount = 1,
        Value = 0,
        LootCount = 0,
        ClueCount = 1,
        ToolCount = 0,
        MissionCount = 0,
        BackpackItems = {},
        HeldItem = fixture,
    }

    local teleportPayload = contract.buildRunToMazeTeleportData({
        SessionConfig = {
            Seed = 1,
            Quota = 10,
            RunDurationSeconds = 60,
            InventoryCapacity = 8,
        },
        CampSession = entered,
        EnteringPlayer = {
            UserId = 501,
            Name = 'SpecRunner',
        },
        EntryReason = 'maze_gate',
        PlayerInventory = summary,
        PendingUgcMonsterPayload = nil,
    })

    local viaContract = contract.findPlayerInventory(teleportPayload, 501)
    assert(
        viaContract ~= nil and viaContract.HeldItem ~= nil,
        'Teleport shaping should carry inventory'
    )
    assert(
        ItemFields.copyItemEntry(fixture).MeleeDamage == viaContract.HeldItem.MeleeDamage,
        'Contract clone should match ItemFields for MeleeDamage'
    )
    assert(
        ItemFields.copyItemEntry(fixture).HealHealthPips == viaContract.HeldItem.HealHealthPips,
        'Contract clone should match ItemFields for HealHealthPips'
    )
    assert(
        viaContract.HeldItem.ReadableTitle == 'Threat Note'
            and viaContract.HeldItem.ThreatHintId == 'echo-monster',
        'Contract clone should preserve clue-readable metadata'
    )
end
