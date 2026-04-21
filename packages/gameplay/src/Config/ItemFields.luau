--!strict
-- Single source for inventory item entry fields copied into summaries and teleport contracts.
-- See issues #232 / #229: Inventory.cloneItemEntry and CampMazeSessionContract.cloneInventoryItem must stay aligned.

local ItemFields = {}

local function cloneLightConfig(lightConfig: any): any
    if type(lightConfig) ~= 'table' then
        return nil
    end

    return {
        Brightness = lightConfig.Brightness,
        Range = lightConfig.Range,
        Color = lightConfig.Color,
    }
end

local function normalizeItemCategory(itemEntry: any): string
    if type(itemEntry.ItemCategory) == 'string' and itemEntry.ItemCategory ~= '' then
        return itemEntry.ItemCategory
    end

    if type(itemEntry.ToolCategory) == 'string' and itemEntry.ToolCategory ~= '' then
        return 'Tool'
    end

    return 'Loot'
end

local function normalizeMissionCount(itemEntry: any, itemCategory: string): number
    if type(itemEntry.MissionCount) == 'number' then
        return itemEntry.MissionCount
    end

    if itemCategory == 'Loot' then
        return 1
    end

    return 0
end

function ItemFields.copyItemEntry(itemEntry: any): any
    if type(itemEntry) ~= 'table' then
        return nil
    end

    local itemCategory = normalizeItemCategory(itemEntry)

    return {
        InstanceId = itemEntry.InstanceId,
        Id = itemEntry.Id,
        Name = itemEntry.Name,
        Weight = itemEntry.Weight,
        Value = itemEntry.Value,
        Color = itemEntry.Color,
        Light = cloneLightConfig(itemEntry.Light),
        Description = itemEntry.Description,
        IconAssetId = itemEntry.IconAssetId,
        ToolTemplateName = itemEntry.ToolTemplateName,
        ToolCategory = itemEntry.ToolCategory,
        StateModel = itemEntry.StateModel,
        InitialState = itemEntry.InitialState,
        CurrentState = itemEntry.CurrentState,
        ConsumePerUse = itemEntry.ConsumePerUse,
        CooldownSeconds = itemEntry.CooldownSeconds,
        LastUsedAt = itemEntry.LastUsedAt,
        SwingRange = itemEntry.SwingRange,
        SwingArcDegrees = itemEntry.SwingArcDegrees,
        KnockbackStrength = itemEntry.KnockbackStrength,
        MeleeDamage = itemEntry.MeleeDamage,
        HealHealthPips = itemEntry.HealHealthPips,
        ItemCategory = itemCategory,
        MissionCount = normalizeMissionCount(itemEntry, itemCategory),
        ReadableTitle = itemEntry.ReadableTitle,
        ReadableText = itemEntry.ReadableText,
        ClueId = itemEntry.ClueId,
        ThreatHintId = itemEntry.ThreatHintId,
        SourceMarkerId = itemEntry.SourceMarkerId,
    }
end

function ItemFields.normalizeItemEntryForLoad(rawItemEntry: any): any
    if type(rawItemEntry) ~= 'table' or type(rawItemEntry.InstanceId) ~= 'number' then
        return nil
    end

    local itemCategory = normalizeItemCategory(rawItemEntry)

    return {
        InstanceId = rawItemEntry.InstanceId,
        Id = rawItemEntry.Id,
        Name = rawItemEntry.Name,
        Weight = rawItemEntry.Weight or 0,
        Value = rawItemEntry.Value or 0,
        Color = rawItemEntry.Color,
        Light = cloneLightConfig(rawItemEntry.Light),
        Description = rawItemEntry.Description,
        IconAssetId = rawItemEntry.IconAssetId,
        ToolTemplateName = rawItemEntry.ToolTemplateName,
        ToolCategory = rawItemEntry.ToolCategory,
        StateModel = rawItemEntry.StateModel,
        InitialState = rawItemEntry.InitialState,
        CurrentState = rawItemEntry.CurrentState,
        ConsumePerUse = rawItemEntry.ConsumePerUse,
        CooldownSeconds = rawItemEntry.CooldownSeconds,
        LastUsedAt = rawItemEntry.LastUsedAt,
        SwingRange = rawItemEntry.SwingRange,
        SwingArcDegrees = rawItemEntry.SwingArcDegrees,
        KnockbackStrength = rawItemEntry.KnockbackStrength,
        MeleeDamage = rawItemEntry.MeleeDamage,
        HealHealthPips = rawItemEntry.HealHealthPips,
        ItemCategory = itemCategory,
        MissionCount = normalizeMissionCount(rawItemEntry, itemCategory),
        ReadableTitle = rawItemEntry.ReadableTitle,
        ReadableText = rawItemEntry.ReadableText,
        ClueId = rawItemEntry.ClueId,
        ThreatHintId = rawItemEntry.ThreatHintId,
        SourceMarkerId = rawItemEntry.SourceMarkerId,
    }
end

ItemFields.ENTRY_FIELD_NAMES = table.freeze({
    'InstanceId',
    'Id',
    'Name',
    'Weight',
    'Value',
    'Color',
    'Light',
    'Description',
    'IconAssetId',
    'ToolTemplateName',
    'ToolCategory',
    'StateModel',
    'InitialState',
    'CurrentState',
    'ConsumePerUse',
    'CooldownSeconds',
    'LastUsedAt',
    'SwingRange',
    'SwingArcDegrees',
    'KnockbackStrength',
    'MeleeDamage',
    'HealHealthPips',
    'ItemCategory',
    'MissionCount',
    'ReadableTitle',
    'ReadableText',
    'ClueId',
    'ThreatHintId',
    'SourceMarkerId',
})

return ItemFields
