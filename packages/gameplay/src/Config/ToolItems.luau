-- ExplorationToolItems Config v0.1
-- IconAssetId: Roblox image asset id only, or full rbxassetid:// URI; empty = UI uses Color fallback.
-- ToolTemplateName: optional Model/Tool name under ReplicatedStorage.Assets.ToolTemplates (see place default.project.json).
local ToolItems = {
    -- 手电筒：照明消耗电量
    ['tool-flashlight'] = {
        Id = 'tool-flashlight',
        Name = 'Flashlight',
        Description = '在黑暗中照亮路径。本配置下使用不消耗电量。',
        ToolCategory = 'Flashlight',
        Weight = 1,
        Value = 0,
        Color = Color3.fromRGB(148, 163, 184),
        IsEquipable = true,
        IconAssetId = '',
        ToolTemplateName = 'ToolFlashlight',
        -- 状态属性
        StateModel = 'Battery',
        InitialState = 100,
        ConsumePerUse = 0,
        CooldownSeconds = 0,
    },

    -- 撬棍：近战挥舞击退怪物
    ['tool-crowbar'] = {
        Id = 'tool-crowbar',
        Name = 'Crowbar',
        Description = '近战挥舞可对前方怪物造成伤害。本配置下使用不消耗耐久。',
        ToolCategory = 'Crowbar',
        Weight = 3,
        Value = 0,
        Color = Color3.fromRGB(200, 200, 200),
        IsEquipable = true,
        IconAssetId = '',
        ToolTemplateName = 'ToolCrowbar',
        -- 状态属性
        StateModel = 'Durability',
        InitialState = 10,
        ConsumePerUse = 0,
        CooldownSeconds = 0.5,
        -- 战斗参数
        SwingRange = 6,
        SwingArcDegrees = 70,
        SwingKnockback = 15,
        MeleeDamage = 1,
    },

    -- 药水：迷宫内饮用，消耗次数并回复生命 pip（占位数值）
    ['tool-potion'] = {
        Id = 'tool-potion',
        Name = 'Potion',
        Description = '饮用消耗一次剂量并回复少量生命；仅在迷宫远征中作为工具使用。',
        ToolCategory = 'Potion',
        Weight = 1,
        Value = 0,
        Color = Color3.fromRGB(236, 72, 153),
        IsEquipable = true,
        IconAssetId = '',
        ToolTemplateName = 'ToolPotion',
        StateModel = 'Charges',
        InitialState = 3,
        ConsumePerUse = 1,
        CooldownSeconds = 1,
        -- 每次成功饮用回复的生命 pip（迷宫 RequestUseTool）
        HealHealthPips = 1,
    },
}

return ToolItems
