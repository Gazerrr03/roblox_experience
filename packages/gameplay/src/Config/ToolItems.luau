-- ExplorationToolItems Config v0.1
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
        -- 状态属性
        StateModel = 'Durability',
        InitialState = 10,
        ConsumePerUse = 0,
        CooldownSeconds = 0.5,
        -- 战斗参数
        SwingRange = 6,
        SwingArcDegrees = 70,
        SwingKnockback = 15,
    },
}

return ToolItems
