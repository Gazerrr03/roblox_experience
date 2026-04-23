return function()
    local ReplicatedStorage = game:GetService('ReplicatedStorage')
    local gameplay = require(ReplicatedStorage:WaitForChild('Packages'):WaitForChild('Gameplay'))
    local sharedPackage = ReplicatedStorage:WaitForChild('Packages'):WaitForChild('Shared')
    local shared = require(sharedPackage)
    local contract = shared.Session.CampMazeSessionContract
    local InventoryService =
        require(sharedPackage:WaitForChild('Runtime'):WaitForChild('InventoryService'))

    local inventory = gameplay.Inventory.new(2)
    local lootItem = {
        Id = 'signal-core',
        Name = 'Signal Core',
        Weight = 99,
        Value = 18,
        ItemCategory = 'Loot',
        MissionCount = 1,
    }
    local clueItem = {
        Id = 'clue-threat-1',
        Name = 'Warning Note',
        ItemCategory = 'Clue',
        MissionCount = 0,
        ReadableTitle = 'Warning Note',
        ReadableText = 'Do not trust the first footsteps you hear.',
        ClueId = 'threat-1',
        ThreatHintId = 'monster-echo',
        SourceMarkerId = 'ClueMarker_Warning',
    }
    local toolItem = {
        Id = 'tool-crowbar',
        Name = 'Crowbar',
        ItemCategory = 'Tool',
        MissionCount = 0,
        ToolCategory = 'Crowbar',
        StateModel = 'Durability',
        InitialState = 10,
        ConsumePerUse = 0,
        CooldownSeconds = 0.5,
        KnockbackStrength = 15,
        ToolTemplateName = 'ToolCrowbar',
    }

    local firstOk, firstEntry = inventory:add(lootItem)
    assert(firstOk == true, 'Inventory should accept the first item')
    assert(firstEntry.InstanceId == 1, 'Inventory should issue a stable instance id')

    local secondOk, secondEntry = inventory:add(clueItem)
    assert(secondOk == true, 'Inventory should accept a second item while capacity remains')
    assert(secondEntry.InstanceId == 2, 'Second pickup should increment the instance id')

    local fullOk, fullReason = inventory:add(toolItem)
    assert(fullOk == false, 'Inventory capacity should now be slot-based, not weight-based')
    assert(fullReason == 'InventoryFull', 'Full slot inventory should expose InventoryFull')

    local summary = inventory:getSummary()
    assert(summary.LootCount == 1, 'Summary should count loot items')
    assert(summary.ClueCount == 1, 'Summary should count clue items')
    assert(summary.MissionCount == 1, 'Only loot should count toward mission progress')
    assert(summary.Value == 0, 'Inventory summary value should stay compatibility-only')
    assert(summary.Weight == 0, 'Inventory summary weight should stay compatibility-only')

    local extractedEntries, extractedMissionCount = inventory:extractMissionCargo()
    assert(extractedMissionCount == 1, 'extractMissionCargo should count only loot mission entries')
    assert(
        #extractedEntries == 1 and extractedEntries[1].Id == 'signal-core',
        'extractMissionCargo should remove the loot item from inventory'
    )
    assert(
        inventory:getSummary().ClueCount == 1,
        'Clue items should remain after banking loot cargo'
    )

    local dropInventory = gameplay.Inventory.new(3)
    dropInventory:add(lootItem)
    dropInventory:add(clueItem)
    local _, dropTool = dropInventory:add(toolItem)
    assert(dropInventory:equip(dropTool.InstanceId) == true, 'Inventory should equip tool items')
    local droppedEntries = dropInventory:dropAllItems()
    assert(#droppedEntries == 3, 'dropAllItems should return every carried item')
    assert(dropInventory:getSummary().Count == 0, 'dropAllItems should empty the inventory')

    local inventoryService = InventoryService.new(4)
    local fakePlayer = { UserId = 101 }
    inventoryService:addPlayer(fakePlayer)

    local serviceLootOk = inventoryService:pickup(fakePlayer, lootItem)
    local serviceClueOk = inventoryService:pickup(fakePlayer, clueItem)
    local serviceToolOk, serviceTool = inventoryService:pickup(fakePlayer, toolItem)
    assert(
        serviceLootOk == true and serviceClueOk == true and serviceToolOk == true,
        'Runtime inventory should accept loot, clue, and tool items'
    )
    assert(
        inventoryService:equip(fakePlayer, serviceTool.InstanceId) == true,
        'Runtime inventory should equip a held tool'
    )

    local consumeOk, consumedTool = inventoryService:consumeHeldItemState(fakePlayer, 100)
    assert(consumeOk == true, 'Runtime inventory should use held tools')
    assert(consumedTool.CurrentState == 10, 'Zero-consume tools should preserve durability state')

    local cooldownOk, cooldownReason = inventoryService:consumeHeldItemState(fakePlayer, 100.2)
    assert(
        cooldownOk == false and cooldownReason == 'Cooldown',
        'Cooldown tools should reject early reuse'
    )

    local bankedMissionCount = inventoryService:deposit(fakePlayer)
    assert(bankedMissionCount == 1, 'deposit should bank only mission-count loot items')
    local postDepositSummary = inventoryService:getSummary(fakePlayer)
    assert(postDepositSummary.ClueCount == 1, 'deposit should preserve clue items')
    assert(postDepositSummary.ToolCount == 1, 'deposit should preserve non-loot tools')

    local droppedAfterDeposit = inventoryService:dropAllItems(fakePlayer)
    assert(
        #droppedAfterDeposit == 2,
        'dropAllItems should return the remaining clue and tool after loot banking'
    )

    local restorablePlayer = { UserId = 202 }
    inventoryService:addPlayer(restorablePlayer)
    local loadOk = inventoryService:loadSummary(restorablePlayer, {
        Capacity = 4,
        Weight = 0,
        Count = 2,
        BackpackCount = 1,
        HeldCount = 1,
        Value = 0,
        LootCount = 1,
        ClueCount = 1,
        ToolCount = 0,
        MissionCount = 1,
        BackpackItems = { clueItem },
        HeldItem = {
            InstanceId = 9,
            Id = 'glow-orb',
            Name = 'Glow Orb',
            ItemCategory = 'Loot',
            MissionCount = 1,
            Weight = 1,
            Value = 24,
            Light = {
                Brightness = 2.5,
                Range = 18,
                Color = Color3.fromRGB(170, 240, 255),
            },
        },
    })
    assert(loadOk == true, 'Runtime inventory should hydrate modern summaries')
    assert(
        inventoryService:getSummary(restorablePlayer).HeldItem.Light ~= nil,
        'Hydrated inventories should preserve light metadata'
    )

    local campSession = contract.newCampSession({
        SessionId = 'inv-contract-rt',
        CampAccessCode = 'inv-contract-rt',
    })
    local entered = contract.markPlayerEntered(campSession, {
        UserId = restorablePlayer.UserId,
        Name = 'RoundTrip',
    })
    entered.MazeAccessCode = 'inv-contract-rt-maze'

    local roundTripTeleport = contract.buildRunToMazeTeleportData({
        SessionConfig = {
            Seed = 42,
            Quota = 10,
            RunDurationSeconds = 120,
            InventoryCapacity = 4,
        },
        CampSession = entered,
        EnteringPlayer = {
            UserId = restorablePlayer.UserId,
            Name = 'RoundTrip',
        },
        EntryReason = 'maze_gate',
        PlayerInventory = inventoryService:getSummary(restorablePlayer),
    })
    local clonedSummary = contract.findPlayerInventory(roundTripTeleport, restorablePlayer.UserId)
    assert(
        clonedSummary ~= nil and clonedSummary.HeldItem ~= nil,
        'Contract teleport shaping should preserve player inventories'
    )
    assert(
        clonedSummary.BackpackItems[1].ReadableTitle == 'Warning Note',
        'Contract teleport shaping should preserve clue metadata'
    )
    assert(
        clonedSummary.MissionCount == 1,
        'Contract teleport shaping should preserve mission counts'
    )
end
