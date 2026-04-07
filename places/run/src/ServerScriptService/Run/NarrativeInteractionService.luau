--!strict
--#region Services

local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')

--#endregion

--#region Requires

local Packages = ReplicatedStorage:WaitForChild('Packages')
local Shared = require(Packages:WaitForChild('Shared'))
local Remotes = Shared.Network.Remotes.waitForScope(Shared.Network.Remotes.Scope.Run)

--#endregion

--#region Module

local NarrativeInteractionService = {}

-- 叙事内容定义
local NarrativeContent = {
    InscriptionStele = {
        layer1 = '一块倒塌的石碑，表面刻满了模糊的符文。\n符文似乎在微微发光，但你无法理解它们的含义。\n触摸石碑，感受到一种奇怪的温度...',
        layer2 = "符文排列成一个循环，没有起点也没有终点。\n你隐约感到这些符文在描述什么...\n但它们是什么时候被刻下的？谁刻下的？\n似乎从'醒来'之前，它们就已经存在。",
        layer3 = "你突然意识到：\n这些符文不是'被人'刻下的，\n它们更像是这个世界'本身'的纹理。\n就像书中的一页纸，纹理本身就是被制造出来的。",
        rewards = {
            coins = 30,
        },
    },
    ShatteredMirror = {
        layer1 = '一面破碎的镜子，散落在森林的地面上。\n镜面反射着灰色的天空，但你发现...\n倒影中似乎有个人影，但不是你。',
        layer2 = "你凑近镜子，试图看清那个'人'。\n当你靠近时，那个人影也在靠近你。\n但当你后退时...\n那个人影没有后退，它继续向你靠近。\n镜子里的世界，似乎有它自己的时间。",
        layer3 = "镜子突然裂开，碎片飞溅。\n你在碎片中看到了无数个自己。\n每一个'你'都在做着不同的事情。\n但哪一个'你'是真实的？\n还是说，所有的'你'都只是被描述出来的镜像？",
        rewards = {
            coins = 50,
        },
    },
    WatcherStatue = {
        layer1 = '一尊半埋在沙中的雕像，造型古老而庄严。\n它单手指向远方，仿佛在指引着什么。\n你靠近时，似乎听到了低语...',
        layer2 = "低语声越来越清晰，但听不清在说什么。\n你试图理解那些声音，发现它们不是'语言'。\n更像是一种...频率。\n就像风声，但风声不应该如此有序。",
        layer3 = "你突然听清楚了：\n'继续走'，声音说。\n'不要停下'，声音继续。\n'你们是被描述出来的，但描述还没有结束。'\n雕像的眼睛突然亮起，直视着你。\n'如果故事停止，你们也会消失。'",
        rewards = {
            coins = 100,
            fragments = 5,
        },
    },
}

-- 玩家交互记录
local playerInteractions = {}

-- 清理离开的玩家数据
Players.PlayerRemoving:Connect(function(player)
    playerInteractions[player.UserId] = nil
end)

-- 初始化服务
function NarrativeInteractionService.initialize(stelePrompt, mirrorPrompt, statuePrompt)
    -- 连接所有交互点的触发事件
    NarrativeInteractionService.connectPrompt(stelePrompt, 'InscriptionStele')
    NarrativeInteractionService.connectPrompt(mirrorPrompt, 'ShatteredMirror')
    NarrativeInteractionService.connectPrompt(statuePrompt, 'WatcherStatue')
end

-- 连接Prompt触发事件
function NarrativeInteractionService.connectPrompt(prompt, narrativeId)
    prompt.Triggered:Connect(function(player)
        NarrativeInteractionService.handleInteraction(player, narrativeId)
    end)
end

-- 处理玩家交互
function NarrativeInteractionService.handleInteraction(player, narrativeId)
    -- 检查是否已经交互过
    local playerData = playerInteractions[player.UserId] or {}
    if playerData[narrativeId] then
        -- 如果已经交互过，只显示第一层
        NarrativeInteractionService.showNarrativeToClient(player, narrativeId, 1)
        return
    end

    -- 第一次交互，显示所有三层
    -- 记录交互
    playerInteractions[player.UserId] = playerInteractions[player.UserId] or {}
    playerInteractions[player.UserId][narrativeId] = true

    -- 显示叙事内容
    NarrativeInteractionService.showNarrativeToClient(player, narrativeId, nil)

    -- 给予奖励
    NarrativeInteractionService.giveRewards(player, narrativeId)
end

-- 显示叙事内容到客户端
function NarrativeInteractionService.showNarrativeToClient(player, narrativeId, layer)
    local content = NarrativeContent[narrativeId]
    if not content then
        warn('Narrative content not found for ID:', narrativeId)
        return
    end

    -- 使用统一的 Remotes 模块
    if layer then
        Remotes.ShowNarrative:FireClient(player, content['layer' .. tostring(layer)])
    else
        -- 显示所有三层
        Remotes.ShowNarrative:FireClient(player, content.layer1, content.layer2, content.layer3)
    end
end

-- 给予奖励
function NarrativeInteractionService.giveRewards(player, narrativeId)
    local content = NarrativeContent[narrativeId]
    if not content or not content.rewards then
        return
    end

    -- 给予金币奖励（如果有金币系统）
    if content.rewards.coins then
        -- TODO: 实现金币系统后，这里给予金币
        print(player.Name .. ' received ' .. content.rewards.coins .. ' coins from ' .. narrativeId)
    end

    -- 给予书页碎片（如果有）
    if content.rewards.fragments then
        -- TODO: 实现书页碎片系统后，这里给予碎片
        print(
            player.Name
                .. ' received '
                .. content.rewards.fragments
                .. ' fragments from '
                .. narrativeId
        )
    end
end

-- 获取玩家交互记录
function NarrativeInteractionService.getPlayerInteractions(player)
    return playerInteractions[player.UserId] or {}
end

-- 重置玩家交互记录(用于测试)
function NarrativeInteractionService.resetPlayerInteractions(player)
    playerInteractions[player.UserId] = nil
end

return NarrativeInteractionService
