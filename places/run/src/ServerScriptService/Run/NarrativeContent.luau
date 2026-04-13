--!strict
-- ════════════════════════════════════════════════════════════
-- NarrativeContent.luau — 纯文案配置文件
-- 所有叙事文字、Prompt文案、提示语、渐进显现文案集中在此
-- 修改文案只需改此文件，不动逻辑代码
--
-- 版本: 1.0
-- 最后更新: 2026-04-14
-- ════════════════════════════════════════════════════════════

local NarrativeContent = {}

-- ════════════════════════════════════════════════════════════
-- 一、13个碎片数据定义（叙事文字 + 情报内容 + 元信息）
-- ════════════════════════════════════════════════════════════

NarrativeContent.FRAGMENTS = {

    -- ==================== 废弃神庙区 (AT) ====================

    {
        id = 'AT_01',
        region = 'AbandonedTemple',
        title = '熄灭的守望者',
        narrativeText = [[它们曾经指向某个方向。
现在，方向消失了，
只剩下这些焦黑的骨架。

但你点燃它们的时候——
有一瞬间，
你感觉它们仍在看着什么。]],
        intelType = 'environment',
        intelContent = [[📋 【环境线索】

图书馆入口区域的房间排列并非随机——
两侧对称的结构中，
通常有一条路径通向 书页房间。
注意观察对称性。

⚠️ 此情报将在进入图书馆后验证]],
        triggerItem = 'KindlingStone',
    },

    {
        id = 'AT_02',
        region = 'AbandonedTemple',
        title = '墙上的最后一行',
        narrativeText = [[墙上的刻痕几乎被风磨平了。
你只能看清最后一行：

'……被写下之前，
  我们就已经在这里等待。'

等待什么？]],
        intelType = 'resource',
        intelContent = [[📦 【资源提示】

简单难度和普通难度的 稀有书页
通常出现在地图边缘的独立小房间，
而非主路径上。
如果你只走直线，会错过它们。]],
        triggerItem = nil,
    },

    {
        id = 'AT_03',
        region = 'AbandonedTemple',
        title = '碎裂的回声',
        narrativeText = [[每一次敲击都让空气震颤。
不是声音——
是某种更深的东西在回应。

像是整片废墟
记得自己曾经的形状。]],
        intelType = 'environment',
        intelContent = [[🔍 【环境线索】

困难及以上的图书馆地图中，
部分 墙壁是可以破坏 的。
如果你在房间里找不到出口，
检查那些看起来"不太一样"的墙面。]],
        triggerItem = 'ResonanceHammer',
    },

    -- ==================== 古代遗迹区 (AR) ====================

    {
        id = 'AR_01',
        region = 'AncientRuins',
        title = '石碑的无字面',
        narrativeText = [[透过它，
你看到了石碑上本不存在的文字。

它们不是被刻上去的——
它们是从内部渗出来的，
像水从石头缝里渗出。

写的是同一段话，反复重叠：

'谁在看？'
'谁在看？'
'谁在看？']],
        intelType = 'mechanic',
        intelContent = [[⚙️ 【机制提示】

图书馆内的 谜题 通常与"观察"有关。
如果你卡关了，
试试切换视角、贴近墙面、
或使用光照类道具——
答案往往藏在细节里。]],
        triggerItem = 'ObservationLens',
    },

    {
        id = 'AR_02',
        region = 'AncientRuins',
        title = '失衡的天平',
        narrativeText = [[你的手刚碰到天平，它就停住了。
像是在等你等了很久。

你听到了叹息——很轻，像翻书的声音。
这个天平衡量的不是重量。

它在衡量
'被记录'
和
'被遗忘'
的分量。

——而它们
 永远不可能相等。]],
        intelType = 'hazard',
        intelContent = [[⚠️ 【危险预警】

图书馆撤离点的 时间窗口 类型关卡中，
倒计时结束时出口会消失——
但有时 假的出口
会在倒计时最后10秒出现。
不要急着冲向第一个看到的出口。]],
        triggerItem = nil,
    },

    {
        id = 'AR_03',
        region = 'AncientRuins',
        title = '共鸣石的频率',
        narrativeText = [[三块石头唱出了
同一个音符的不同泛音。

你不知道是怎么知道顺序的——
你的手指在自己意识到之前
就已经按了下去。

好像有什么东西
在你的手到达之前，
已经在那里等了。]],
        intelType = 'mechanic',
        intelContent = [[⚙️ 【机制提示】

机关解锁型 撤离点
通常需要按正确顺序操作多个机关。
如果附近有环境线索（壁画/铭文），
仔细看——
顺序往往藏在其中。]],
        triggerItem = nil,
    },

    -- ==================== 荒野森林区 (WF) ====================

    {
        id = 'WF_01',
        region = 'WildernessForest',
        title = '树洞里的眼睛',
        narrativeText = [[光照进树洞的一瞬间，
你看到里面的纹路在退缩。

像是某种东西被光惊醒了，
又迅速躲回了更深的黑暗里。

那些纹路——
你不愿把它们叫做文字，
但它们确实在说着什么。]],
        intelType = 'hazard',
        intelContent = [[⚠️ 【危险预警】

噩梦难度图书馆中存在 伪装型环境威胁——
看起来安全的区域
（比如静止的书堆、装饰性雕像）
可能在玩家经过一定时间后活化。
保持移动，
不要在同一位置停留过久。]],
        triggerItem = 'LightSeed',
    },

    {
        id = 'WF_02',
        region = 'WildernessForest',
        title = '足迹的终点',
        narrativeText = [[足迹不属于任何你见过的动物。
步距太小，爪痕太规律——
像是在模仿某种脚步，
但又模仿得不到位。

足迹在这里停了很久。
久到地面都记住了它的形状。]],
        intelType = 'resource',
        intelContent = [[📦 【资源提示】

Boss房间 在生成时会偏向
地图中距离入口 最远的区域。
如果你想快速找到Boss挑战获取额外书页，
优先向远离入口的方向探索。]],
        triggerItem = 'TrackingDust',
    },

    {
        id = 'WF_03',
        region = 'WildernessForest',
        title = '不存在的果实',
        narrativeText = [[那颗果实碰到你手掌的时候没有重量。

它像是一个念头——
一个关于'果实'的念头——
在你碰到的瞬间
才决定让自己被看见。

然后它就消失了，
留给你一个问题：

是你摘到了它，
还是它允许了自己被摘到？]],
        intelType = 'environment',
        intelContent = [[🔍 【环境线索】

普通及以上难度的图书馆地图中，
镜像室 环境类型的房间入口
通常被刻意隐藏
（如在书架后面、地板下方）。
如果在地图上发现一片区域
周围都有房间但中间空了一块，
那里很可能有隐藏入口。]],
        triggerItem = nil,
    },

    -- ==================== 洞穴遗迹区 (CR) ====================

    {
        id = 'CR_01',
        region = 'CaveRuins',
        title = '矿物的脉搏',
        narrativeText = [[晶片接触到矿物的每一瞬你都听到了声音。
不是耳朵听到的——
是骨头在震动。

四个声音叠在一起组成了一句话，
但你来不及抓住就消散了。
只剩下那个轮廓。

一扇门。
一扇不该存在于洞穴深处的门。]],
        intelType = 'environment',
        intelContent = [[📋 【环境线索】+ 📦 【资源提示】

图书馆地图的 书页房间
往往位于需要经过至少两个其他房间
才能到达的位置（即深度≥3）。

如果一条路径连续经过2-3个房间
还没遇到书页房间，
下一个很可能就是。]],
        triggerItem = 'ResonanceShard',
    },

    {
        id = 'CR_02',
        region = 'CaveRuins',
        title = '机关的沉默',
        narrativeText = [[机关启动的声音不像金属摩擦——
像呼吸。
沉重的、缓慢的、古老的呼吸。

齿轮咬合的那一刻
你知道这台机器
已经等待了太久。

铭文上的话
让你不确定它是警告还是欢迎：

'门会为所有被描述的人开启。
你被描述了吗？']],
        intelType = 'hazard',
        intelContent = [[⚠️ 【危险预警】+ ⚙️ 【机制提示】

竞速撤离 类型的关卡中，
撤离点通常不会出现在地图的前半段。
如果你在前半段就发现了看似撤离点的入口，
要警惕——

那可能是 陷阱房间，
进入后会显著缩短剩余撤离时间。]],
        triggerItem = 'RepairGear',
    },

    {
        id = 'CR_03',
        region = 'CaveRuins',
        title = '深渊的低语',
        narrativeText = [[你听到了。
不是从裂缝里——
是从耳坠本身传出来的。

很多声音叠在一起，太多太多了。
有人在朗读，有人在写字，
有人在撕书，有人在尖叫。

然后所有的声音突然停下来。
只有一个声音留下。

它在叫你的名字。

但你确定你没有名字。]],
        intelType = 'hazard',
        intelContent = [[⚠️ 【危险预警】

传送门型 撤离点会将你传送到一个随机位置——
通常是安全的，
但在困难/噩梦难度下有低概率传送到
下一难度的前置区域
（相当于跳级）。
如果你没准备好迎接更高难度，
进入传送门前确保装备齐全。]],
        triggerItem = 'SilentEarring',
    },

    {
        id = 'CR_04',
        region = 'CaveRuins',
        title = '最后的警告',
        -- 注意：CR-04 的 narrativeText 由 CR04_GRADIENT_TEXT 动态选择
        -- 此处存储完整版（13/13 满收）
        narrativeText = [[你站在入口。
纹路在你身上流转——

熄灭的守望者、
墙上的最后一行、
碎裂的回声、
石碑的无字面、
失衡的天平、
共鸣石的频率、
树洞里的眼睛、
足迹的终点、
不存在的果实、
矿物的脉搏、
机关的沉默、
深渊的低语。

所有的碎片拼在一起，
你说不出完整的句子，
但你明白了完整的意思：

"你正走进一本已经被写好的书。

而你——

你是书里的字，

还是翻书的手？"

门开了。
答案在里面。]],
        intelType = 'environment',
        intelContent = [[📋 【终极情报 — 全类型汇总】

═══════════════════════════════
 最终战准备清单
 （建议收集全部13个碎片后再进入
  最终阶段 / 31-40书页）
═══════════════════════════════

▸ 环境：
  · 地图深层必有书页房间，但需要耐心探索 (CR-01)
  · 对称结构中隐藏主路 (AT-01)
  · 可破坏墙壁存在于困难+地图 (AT-03)
  · 隐藏入口在"空白区域"中心 (WF-03)

▸ 资源：
  · 边缘小房间藏稀有书页，别只走主路 (AT-02)
  · Boss房在最远处，优先向远离入口探索 (WF-02)
  · 书页房间深度≥3，耐心走 (CR-01)

▸ 危险：
  · 时间窗口撤离可能有假出口 (AR-02)
  · 噩梦避免长时间停留同一位置 (WF-01)
  · 陷阱房间会伪装成撤离点 (CR-02)
  · 传送门可能跳级 (CR-03)

▸ 机制：
  · 谜题答案在观察细节中 (AR-01)
  · 机关顺序藏在环境线索里 (AR-03)

═══════════════════════════════
 以上情报在收集齐 40 页书页、
 面对最终选择前最为关键。
═══════════════════════════════]],
        triggerItem = nil,
    },
}

-- ════════════════════════════════════════════════════════════
-- 二、CR-04 渐进显现文案（根据已收集碎片数量显示不同版本）
-- ════════════════════════════════════════════════════════════

NarrativeContent.CR04_GRADIENT_TEXT = {
    -- 收集 1-4 个碎片时：简短引导版
    {
        minCollected = 0,
        maxCollected = 4,
        text = [[你站在入口。
有些事情你还不知道。
继续走吧。]],
    },

    -- 收集 5-8 个碎片时：中等版，列举部分碎片名称
    {
        minCollected = 5,
        maxCollected = 8,
        text = [[你站在入口。
熄灭的守望者、墙上的最后一行……
有些碎片已经开始拼合。
但还不够。还不够。]],
    },

    -- 收集 9-12 个碎片时：接近完整版
    {
        minCollected = 9,
        maxCollected = 12,
        text = [[你站在入口。
纹路在你身上流转——
熄灭的守望者、墙上的最后一行、
碎裂的回声、石碑的无字面、
失衡的天平、共鸣石的频率、
树洞里的眼睛、足迹的终点、
不存在的果实、矿物的脉搏、
机关的沉默、深渊的低语……
还差一点。就差一点。]],
    },

    -- 收集全部 12 个碎片后（本次获得第13个）：完整收束版
    -- 此文本与 FRAGMENTS[CR-04].narrativeText 相同，由系统自动使用
    {
        minCollected = 13,
        maxCollected = 13,
        text = nil, -- 使用 FRAGMENTS 表中的完整版 narrativeText
    },
}

-- 根据已收集数量返回对应的叙事文字
function NarrativeContent.getCR04Text(collectedCount: number): string
    for _, entry in ipairs(NarrativeContent.CR04_GRADIENT_TEXT) do
        if collectedCount >= entry.minCollected and collectedCount <= entry.maxCollected then
            if entry.text then
                return entry.text
            else
                -- 返回完整版（CR-04 的 narrativeText）
                local fullConfig = nil
                for _, frag in ipairs(NarrativeContent.FRAGMENTS) do
                    if frag.id == 'CR_04' then
                        fullConfig = frag
                        break
                    end
                end
                if fullConfig then
                    return fullConfig.narrativeText
                end
            end
        end
    end
    -- fallback：返回简短版
    return NarrativeContent.CR04_GRADIENT_TEXT[1].text
end

-- ════════════════════════════════════════════════════════════
-- 三、可触发物品定义（8个物品）
-- ════════════════════════════════════════════════════════════

NarrativeContent.TRIGGER_ITEMS = {
    KindlingStone = {
        name = 'KindlingStone',
        displayName = '引火石',
        description = '暗红色的粗糙石头，用于点燃古老装置',
        pickupActionText = '拾取',
        pickupObjectText = '发光的石头',
        pickupHoldDuration = 0.2,
        obtainMessage = '获得了 引火石',
        obtainHint = '这块石头还残留着温度。它想被使用。',
        isConsumable = true,
        consumedHint = '', -- 消耗时无额外提示，直接消耗
        color = Color3.fromRGB(180, 60, 40),
        material = Enum.Material.Sandstone,
    },
    ResonanceHammer = {
        name = 'ResonanceHammer',
        displayName = '共鸣锤',
        description = '表面有声波纹路的石质锤头',
        pickupActionText = '拔出',
        pickupObjectText = '埋在碎石中的东西',
        pickupHoldDuration = 0.3,
        obtainMessage = '获得了 共鸣锤',
        obtainHint = '它能听到石头记住的声音。',
        isConsumable = true,
        consumedHint = '',
        color = Color3.fromRGB(140, 130, 120),
        material = Enum.Material.Slate,
    },
    ObservationLens = {
        name = 'ObservationLens',
        displayName = '观测透镜',
        description = '半透明淡青色晶体，可观察隐形痕迹',
        pickupActionText = '拔出',
        pickupObjectText = '嵌在基座里的晶体',
        pickupHoldDuration = 0.3,
        obtainMessage = '获得了 观测透镜',
        obtainHint = '透过它，你能看到不该被看到的东西。',
        isConsumable = false, -- 持久工具
        color = Color3.fromRGB(180, 220, 230),
        material = Enum.Material.Glass,
    },
    TrackingDust = {
        name = 'TrackingDust',
        displayName = '追踪粉尘',
        description = '撒出金色微粒显示隐形路径',
        pickupActionText = '取下',
        pickupObjectText = '挂在枝头的布袋',
        pickupHoldDuration = 0.3,
        obtainMessage = '获得了 追踪粉尘',
        obtainHint = '它能显示那些不想被看见的路。',
        isConsumable = false, -- 持久工具
        color = Color3.fromRGB(220, 190, 100),
        material = Enum.Material.Fabric,
    },
    LightSeed = {
        name = 'LightSeed',
        displayName = '光源种子',
        description = '温橙色发光种子，照亮黑暗处',
        pickupActionText = '拾取',
        pickupObjectText = '发光的种子',
        pickupHoldDuration = 0.2,
        obtainMessage = '获得了 光源种子',
        obtainHint = '它是温暖的。它想照进某个黑暗的地方。',
        isConsumable = true,
        consumedHint = '',
        color = Color3.fromRGB(255, 180, 80),
        material = Enum.Material.Neon,
    },
    ResonanceShard = {
        name = 'ResonanceShard',
        displayName = '共振晶片',
        description = '薄片状晶体，读取矿物记忆',
        pickupActionText = '小心取出',
        pickupObjectText = '深橙色的矿物',
        pickupHoldDuration = 0.5,
        obtainMessage = '获得了 共振晶片',
        obtainHint = '它能读取石头记住的画面。',
        isConsumable = true,
        consumedHint = '',
        color = Color3.fromRGB(220, 150, 80),
        material = Enum.Material.Glass,
    },
    RepairGear = {
        name = 'RepairGear',
        displayName = '修复齿轮',
        description = '部分缺损的青铜齿轮，激活古代机关',
        pickupActionText = '取出齿轮', -- 从宝箱中取出
        pickupObjectText = '残缺的齿轮',
        pickupHoldDuration = 0.2,
        obtainMessage = '获得了 修复齿轮',
        obtainHint = '',
        isConsumable = true,
        consumedHint = '',
        color = Color3.fromRGB(160, 155, 140),
        material = Enum.Material.Metal,
    },
    SilentEarring = {
        name = 'SilentEarring',
        displayName = '静默耳坠',
        description = '耳坠状饰品，倾听隐藏的声音',
        pickupActionText = '拾取',
        pickupObjectText = '裂缝边的什么东西',
        pickupHoldDuration = 0.2,
        obtainMessage = '', -- 无普通获得提示——被叙事文字打断
        obtainHint = '',
        isConsumable = false, -- 持久工具
        color = Color3.fromRGB(120, 100, 140),
        material = Enum.Material.Glass,
    },
}

-- ════════════════════════════════════════════════════════════
-- 四、ProximityPrompt 配置表（所有交互点的 Prompt 文案和参数）
-- ════════════════════════════════════════════════════════════

NarrativeContent.PROMPTS = {

    -- ── AT-01: 引火石 & 灯塔 ──
    AT_01_PickupStone = {
        actionText = '拾取',
        objectText = '发光的石头',
        holdDuration = 0.2,
    },
    AT_01_LightBeacon = {
        actionText = '点燃残留',
        objectText = '倒塌的灯塔',
        holdDuration = 0.5,
    },

    -- ── AT-02: 刻痕墙壁 ──
    AT_02_ReadWall = {
        actionText = '辨认墙面痕迹',
        objectText = '刻痕墙壁',
        holdDuration = 3.0,
    },

    -- ── AT-03: 共鸣锤 & 碎石堆 ──
    AT_03_PickupHammer = {
        actionText = '拔出',
        objectText = '埋在碎石中的东西',
        holdDuration = 0.3,
    },
    AT_03_HitRubble = {
        actionText = '敲击',
        objectText = '碎石堆',
        holdDuration = 0.3,
    },

    -- ── AR-01: 观测透镜 & 石碑 ──
    AR_01_PickupLens = {
        actionText = '拔出',
        objectText = '嵌在基座里的晶体',
        holdDuration = 0.3,
    },
    AR_01_ObserveStele = {
        actionText = '透过透镜观察',
        objectText = '古代石碑',
        holdDuration = 0.0,
    },

    -- ── AR-02: 天平 ──
    AR_02_TouchScale = {
        actionText = '触碰天平',
        objectText = '古代天平',
        holdDuration = 0.0,
    },

    -- ── AR-03: 共鸣石 ──
    AR_03_ActivateStone = {
        actionText = '激活',
        objectText = '共鸣石',
        holdDuration = 0.0,
    },

    -- ── WF-01: 光源种子 & 树洞 ──
    WF_01_PickupSeed = {
        actionText = '拾取',
        objectText = '发光的种子',
        holdDuration = 0.2,
    },
    WF_01_DepositSeed = {
        actionText = '投入种子',
        objectText = '树洞',
        holdDuration = 0.5,
    },

    -- ── WF-02: 追踪粉尘 & 足迹 ──
    WF_02_PickupDust = {
        actionText = '取下',
        objectText = '挂在枝头的布袋',
        holdDuration = 0.3,
    },
    WF_02_TrackFootprint = {
        actionText = '追踪足迹',
        objectText = '奇怪的足迹',
        holdDuration = 0.0,
    },
    WF_02_Investigate = {
        actionText = '调查',
        objectText = '停留的痕迹',
        holdDuration = 0.0,
    },

    -- ── WF-03: 异常树枝 & 果实 ──
    WF_03_TouchBranch = {
        actionText = '触碰',
        objectText = '异常的树枝',
        holdDuration = 0.0,
    },
    WF_03_PickFruit = {
        actionText = '采摘',
        objectText = '不存在的果实',
        holdDuration = 0.0,
    },

    -- ── CR-03: 静默耳坠 ──
    CR_03_PickupEarring = {
        actionText = '拾取',
        objectText = '裂缝边的什么东西',
        holdDuration = 0.2,
    },

    -- ── CR-01: 共振晶片 & 矿物 ──
    CR_01_PickupShard = {
        actionText = '小心取出',
        objectText = '深橙色的矿物',
        holdDuration = 0.5,
    },
    CR_01_ReadMineral = {
        actionText = '读取记忆',
        objectText = '发光矿物',
        holdDuration = 0.0,
    },

    -- ── CR-02: 宝箱 & 机关 ──
    CR_02_OpenChest = {
        actionText = '打开',
        objectText = '古老的宝箱',
        holdDuration = 0.5,
    },
    CR_02_PickupGear = {
        actionText = '取出齿轮',
        objectText = '残缺的齿轮',
        holdDuration = 0.2,
    },
    CR_02_InstallGear = {
        actionText = '安装齿轮',
        objectText = '古代机关',
        holdDuration = 0.5,
    },

    -- ── CR-04: 入口凝视 ──
    CR_04_GazeEntrance = {
        actionText = '凝视入口',
        objectText = '洞穴入口',
        holdDuration = 2.0,
    },
}

-- ════════════════════════════════════════════════════════════
-- 五、"物品缺失时的拒绝提示"
-- 当玩家尝试交互但没有持有必需物品时显示的文案
-- ════════════════════════════════════════════════════════════

NarrativeContent.MISSING_ITEM_HINTS = {
    AT_01_BeaconNeedsFire = {
        title = '这座残骸冰冷而黑暗',
        hint = '似乎需要某种火源才能唤醒...',
    },
    AT_03_NeedHammer = { title = '', hint = '' }, -- 不敲击就不出 prompt，不需要额外提示
    AR_01_SteleBlank = {
        title = '石碑表面光滑无字',
        hint = '也许需要某种工具来观察...',
    },
    WF_01_TreeDark = {
        title = '树洞深处一片漆黑',
        hint = '似乎需要光源才能看清里面...',
    },
    WF_02_TrackMysterious = {
        title = '地面上有一个奇怪的凹陷',
        hint = '似乎需要某种方式来追踪来源...',
    },
    CR_01_MineralGlowing = {
        title = '矿物表面有微弱的光芒流动',
        hint = '也许需要某种媒介来读取...',
    },
    CR_02_MechanismMissing = {
        title = '机关表面有一个齿轮形的凹槽',
        hint = '似乎缺少了关键部件...',
    },
}

-- ════════════════════════════════════════════════════════════
-- 六、多步骤进度反馈文字
-- ════════════════════════════════════════════════════════════

NarrativeContent.PROGRESS_FEEDBACK = {

    -- AT-01 点燃灯塔进度
    AT_01_BeaconProgress = {
        format = '%d / 3', -- "1 / 3", "2 / 3", "3 / 3"
        completedEffect = '三座灯塔同时发出的光芒在空中交汇成一瞬间的图案',
    },

    -- AT-03 敲击碎石堆进度
    AT_03_RubbleProgress = {
        format = '%d / 4', -- "1 / 4", "2 / 4", ...
        completedEffect = '四个碎石堆同时发出强烈共鸣',
    },

    -- AR-03 激活共鸣石进度
    AR_03_StoneProgress = {
        format = '☆', -- 激活标记
        allActivatedEffect = '三道光柱从每块石头正上方射出，交汇于一点',
    },
}

-- ════════════════════════════════════════════════════════════
-- 七、区域进入/离开 提示文字
-- ════════════════════════════════════════════════════════════

NarrativeContent.AREA_HINTS = {

    -- 出生点
    Spawn = {
        birthText = '你在黑暗中醒来。',
        controlHint = '按 WASD 移动，空格跳跃',
        guideHint = '走向光的方向。那里有东西在等你。',
        firstStepHint = '荒野中有残留的记忆。找到它们。',
        sandbookTitle = '📖 沙之书',
        sandbookContent = '书页：0 / 40',
        sandbookSubtext = '书页尚为空白。去寻找它们吧。',
        promptAltar = '[E] 祭坛',
        promptAssemble = '[E] 拼凑书页',
        promptSandbook = '[E] 查看沙之书',
    },

    -- 进入各区域的边界提示
    AT_Enter = {
        complete = '废墟的气息。有什么东西曾经在这里存在过。',
        duration = 4,
    },
    AT_Leave = {
        allCollected = '废弃神庙区的回声已安静下来。还有更多东西在前方等待。',
        partial = '这片废墟还有话没说完。',
        duration = 3,
    },

    AR_Enter = {
        text = '这里的秩序感令人不安。好像有人精心安排过一切。',
        duration = 4,
    },
    AR_Leave = {
        allCollected = '被记录的东西已经向你展示了它的秩序。接下来……有些东西正在生长。',
        partial = '石头还在等待它的频率。',
        duration = 4,
    },

    WF_Enter = {
        text = '森林在呼吸。但有些呼吸……不太属于这里。',
        duration = 4,
    },
    WF_Leave = {
        allCollected = '有些东西不应该存在——但它确实在。而且它知道你知道。',
        partial = '森林里还有些异常没有被理解。',
        duration = 4,
    },

    CR_Enter = { text = '你站在入口。里面比你以为的更深。', duration = 3 },
}

-- ════════════════════════════════════════════════════════════
-- 八、碎片获得确认格式化模板
-- ════════════════════════════════════════════════════════════

NarrativeContent.FRAGMENT_AWARD_TEMPLATES = {

    -- 获得确认标题行
    awardHeader = '★ 叙事碎片已记录：%s', -- %s = title
    -- 进度行
    progressLine = '进度：%d / 13', -- %d = 已收集数

    -- 物品状态行（消耗品 vs 持久工具）
    itemConsumed = '%s 已消耗', -- %s = 物品displayName
    itemKept = '%s 已保留（持久工具）',

    -- 特殊标记（CR-04 满收集）
    collectionComplete = [[
═══════════════════════════════

 ✦ 所有荒野叙事碎片已收集完成 ✦

 你已经准备好进入图书馆了。
 情报日志已更新——
 进入图书馆前可在神庙查看。

═══════════════════════════════]],

    -- 状态变化标记
    wallDeciphered = '该墙壁已被你辨认',
    scaleCalmed = '该天平已平静',
    stonesResonated = '共鸣石已共鸣',
}

-- ════════════════════════════════════════════════════════════
-- 九、踏入图书馆 过渡文案
-- ════════════════════════════════════════════════════════════

NarrativeContent.LIBRARY_TRANSITION = {
    nearDoorHint = '你拥有了所有的碎片。门就在前面。',
    doorFrameHint = '进去之后，第一件事——找书页。',
    doorFrameNoSandbookHint = '你还没看过沙之书。也许进去之后，你会想起来了。',
    transitionDescription = '你进入了图书馆',
}

return NarrativeContent
