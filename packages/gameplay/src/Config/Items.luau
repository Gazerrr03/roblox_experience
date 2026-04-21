local Config = script.Parent

local ToolItems = require(Config:WaitForChild('ToolItems'))

local BaseItems = {
    {
        Id = 'ugc-gen-token',
        Name = 'UGC Signal Token',
        Weight = 1,
        Value = 4,
        Color = Color3.fromRGB(121, 195, 255),
        ItemCategory = 'Loot',
        MissionCount = 1,
    },
    {
        Id = 'scrap-bolt',
        Name = 'Scrap Bolt',
        Weight = 1,
        Value = 8,
        Color = Color3.fromRGB(148, 163, 184),
        ItemCategory = 'Loot',
        MissionCount = 1,
    },
    {
        Id = 'signal-core',
        Name = 'Signal Core',
        Weight = 2,
        Value = 18,
        Color = Color3.fromRGB(80, 227, 194),
        ItemCategory = 'Loot',
        MissionCount = 1,
    },
    {
        Id = 'reactor-shell',
        Name = 'Reactor Shell',
        Weight = 4,
        Value = 42,
        Color = Color3.fromRGB(248, 196, 113),
        ItemCategory = 'Loot',
        MissionCount = 1,
    },
    {
        Id = 'glow-orb',
        Name = 'Glow Orb',
        Weight = 1,
        Value = 24,
        Color = Color3.fromRGB(142, 236, 255),
        Light = {
            Brightness = 2.5,
            Range = 18,
            Color = Color3.fromRGB(170, 240, 255),
        },
        ItemCategory = 'Loot',
        MissionCount = 1,
    },
}

local FinalItems = table.clone(BaseItems)

for _, toolData in pairs(ToolItems) do
    table.insert(FinalItems, toolData)
end

return FinalItems
