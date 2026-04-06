local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Packages = ReplicatedStorage:WaitForChild('Packages')
local Config = script.Parent

-- 引入探索道具武器库
local ToolItems = require(Config:WaitForChild('ToolItems'))

-- 这是原本的基础物资列表
local BaseItems = {
    {
        Id = 'scrap-bolt',
        Name = 'Scrap Bolt',
        Weight = 1,
        Value = 8,
        Color = Color3.fromRGB(148, 163, 184),
    },
    {
        Id = 'signal-core',
        Name = 'Signal Core',
        Weight = 2,
        Value = 18,
        Color = Color3.fromRGB(80, 227, 194),
    },
    {
        Id = 'reactor-shell',
        Name = 'Reactor Shell',
        Weight = 4,
        Value = 42,
        Color = Color3.fromRGB(248, 196, 113),
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
    },
}

-- === 自动合并逻辑：把 ToolItems 里的手电筒和撬棍也加进来 ===
local FinalItems = table.clone(BaseItems)

for _, toolData in pairs(ToolItems) do
    table.insert(FinalItems, toolData)
end

return FinalItems