--!strict
--#region Types

-- 叙事碎片数据类型
export type NarrativeFragment = {
	id: string,
	region: string,
	title: string,
	narrativeText: string,
	intelType: string, -- "environment" | "resource" | "hazard" | "mechanic"
	intelContent: string,
	isCollected: { [number]: boolean }, -- 玩家收集状态，key = UserId
}

-- 可触发物品数据类型
export type TriggerItem = {
	name: string,
	description: string,
	isConsumable: boolean,
	color: Color3,
	material: Enum.Material,
}

-- 碎片配置（13个碎片）
local FRAGMENT_CONFIGS = {
	-- ==================== 废弃神庙区 (AbandonedTemple) ====================

	{
		id = 'AT_01',
		region = 'AbandonedTemple',
		title = '熄灭的守望者',
		narrativeText =
			'它们曾经指向某个方向。现在方向消失了，只剩下这些焦黑的骨架。但你点燃它们的时候——有一瞬间，你感觉它们仍在看着什么。',
		intelType = 'environment',
		intelContent =
			'【环境线索】图书馆入口区域的房间排列并非随机——两侧对称的结构中，通常有一条路径通向书页房间。注意观察对称性。',
		triggerItem = 'KindlingStone', -- 引火石
	},
	{
		id = 'AT_02',
		region = 'AbandonedTemple',
		title = '墙上的最后一行',
		narrativeText =
			'墙上的刻痕几乎被风磨平了。你只能看清最后一行："……被写下之前，我们就已经在这里等待。" 等待什么？',
		intelType = 'resource',
		intelContent =
			'【资源提示】简单难度和普通难度的稀有书页通常出现在地图边缘的独立小房间，而非主路径上。如果你只走直线，会错过它们。',
		triggerItem = nil, -- 无需物品
	},
	{
		id = 'AT_03',
		region = 'AbandonedTemple',
		title = '碎裂的回声',
		narrativeText =
			'每一次敲击都让空气震颤。不是声音——是某种更深的东西在回应。像是整片废墟记得自己曾经的形状。',
		intelType = 'environment',
		intelContent =
			'【环境线索】困难及以上的图书馆地图中，部分墙壁是可以破坏的。如果你在一个房间里找不到出口，检查那些看起来"不太一样"的墙面。',
		triggerItem = 'ResonanceHammer', -- 共鸣锤
	},

	-- ==================== 古代遗迹区 (AncientRuins) ====================

	{
		id = 'AR_01',
		region = 'AncientRuins',
		title = '石碑的无字面',
		narrativeText =
			'透过它，你看到了石碑上本不存在的文字。它们不是被刻上去的——它们是从内部渗出来的，像水从石头缝里渗出。写的是同一段话，反复重叠："谁在看？"',
		intelType = 'mechanic',
		intelContent =
			'【机制提示】图书馆内的谜题通常与"观察"有关。如果你卡关了，试试切换视角、贴近墙面、或使用光照类道具——答案往往藏在细节里。',
		triggerItem = 'ObservationLens', -- 观测透镜
	},
	{
		id = 'AR_02',
		region = 'AncientRuins',
		title = '失衡的天平',
		narrativeText =
			'你的手刚碰到天平，它就停住了。像是在等你等了很久。你听到了叹息——很轻，像翻书的声音。这个天平衡量的不是重量。它在衡量"被记录"和"被遗忘"的分量。而它们永远不可能相等。',
		intelType = 'hazard',
		intelContent =
			'【危险预警】图书馆撤离点的时间窗口类型关卡中，倒计时结束时出口会消失——但有时假的出口会在倒计时最后10秒出现。不要急着冲向第一个看到的出口。',
		triggerItem = nil,
	},
	{
		id = 'AR_03',
		region = 'AncientRuins',
		title = '共鸣石的频率',
		narrativeText =
			'三块石头唱出了同一个音符的不同泛音。你不知道是怎么知道顺序的——你的手指在自己意识到之前就已经按了下去。好像有什么东西在你的手到达之前，已经在那里等了。',
		intelType = 'mechanic',
		intelContent =
			'【机制提示】机关解锁型撤离点通常需要按正确顺序操作多个机关。如果附近有环境线索（壁画/铭文），仔细看——顺序往往藏在其中。',
		triggerItem = nil,
	},

	-- ==================== 荒野森林区 (WildernessForest) ====================

	{
		id = 'WF_01',
		region = 'WildernessForest',
		title = '树洞里的眼睛',
		narrativeText =
			'光照进树洞的一瞬间，你看到里面的纹路在退缩。像是某种东西被光惊醒了，又迅速躲回了更深的黑暗里。那些纹路——你不愿把它们叫做文字，但它们确实在说着什么。',
		intelType = 'hazard',
		intelContent =
			'【危险预警】噩梦难度图书馆中存在伪装型环境威胁——看起来安全的区域可能在玩家经过一定时间后活化。保持移动，不要在同一位置停留过久。',
		triggerItem = 'LightSeed', -- 光源种子
	},
	{
		id = 'WF_02',
		region = 'WildernessForest',
		title = '足迹的终点',
		narrativeText =
			'足迹不属于任何你见过的动物。步距太小，爪痕太规律——像是在模仿某种脚步，但又模仿得不到位。足迹在这里停了很久。久到地面都记住了它的形状。',
		intelType = 'resource',
		intelContent =
			'【资源提示】Boss房间在生成时会偏向地图中距离入口最远的区域。如果你想快速找到Boss挑战获取额外书页，优先向远离入口的方向探索。',
		triggerItem = 'TrackingDust', -- 追踪粉尘
	},
	{
		id = 'WF_03',
		region = 'WildernessForest',
		title = '不存在的果实',
		narrativeText =
			'那颗果实碰到你手掌的时候没有重量。它像是一个念头——一个关于"果实"的念头——在你碰到的瞬间才决定让自己被看见。然后它就消失了，留给你一个问题：是你摘到了它，还是它允许了自己被摘到？',
		intelType = 'environment',
		intelContent =
			'【环境线索】普通及以上难度的图书馆地图中，镜像室环境类型的房间入口通常被刻意隐藏。如果在地图上发现一片区域周围都有房间但中间空了一块，那里很可能有隐藏入口。',
		triggerItem = nil,
	},

	-- ==================== 洞穴遗迹区 (CaveRuins) ====================

	{
		id = 'CR_01',
		region = 'CaveRuins',
		title = '矿物的脉搏',
		narrativeText =
			'晶片接触到矿物的每一瞬你都听到了声音。不是耳朵听到的——是骨头在震动。四个声音叠在一起组成了一句话，但你来不及抓住就消散了。只剩下那个轮廓。一扇门。一扇不该存在于洞穴深处的门。',
		intelType = 'environment',
		intelContent = '【环境线索+资源提示】图书馆地图的书页房间往往位于需要经过至少两个其他房间才能到达的位置（即深度≥3）。',
		triggerItem = 'ResonanceShard', -- 共振晶片
	},
	{
		id = 'CR_02',
		region = 'CaveRuins',
		title = '机关的沉默',
		narrativeText =
			'机关启动的声音不像金属摩擦——像呼吸。沉重的、缓慢的、古老的呼吸。齿轮咬合的那一刻你知道这台机器已经等待了太久。铭文上的话让你不确定它是警告还是欢迎："门会为所有被描述的人开启。你被描述了吗？"',
		intelType = 'hazard',
		intelContent =
			'【危险预警+机制提示】竞速撤离类型的关卡中，撤离点通常不会出现在地图的前半段。如果在前半段发现看似撤离点的入口，要警惕——那可能是陷阱房间。',
		triggerItem = 'RepairGear', -- 修复齿轮
	},
	{
		id = 'CR_03',
		region = 'CaveRuins',
		title = '深渊的低语',
		narrativeText =
			'你听到了。不是从裂缝里——是从耳坠本身传出来的。很多声音叠在一起，太多太多了。有人在朗读，有人在写字，有人在撕书，有人在尖叫。然后所有的声音突然停下来。只有一个声音留下。它在叫你的名字。但你确定你没有名字。',
		intelType = 'hazard',
		intelContent =
			'【危险预警】传送门型撤离点会将你传送到一个随机位置——通常是安全的，但在困难/噩梦难度下有低概率传送到下一个难度的前置区域（相当于跳级）。进入传送门前确保装备齐全。',
		triggerItem = 'SilentEarring', -- 静默耳坠
	},
	{
		id = 'CR_04',
		region = 'CaveRuins',
		title = '最后的警告',
		narrativeText =
			'你站在入口。纹路在你身上流转——熄灭的守望者、墙上的最后一行、碎裂的回声、石碑的无字面、失衡的天平、共鸣石的频率、树洞里的眼睛、足迹的终点、不存在的果实、矿物的脉搏、机关的沉默、深渊的低语。所有的碎片拼在一起，你说不出完整的句子，但你明白了完整的意思：**你正走进一本已经被写好的书。而你——你是书里的字，还是翻书的手？** 门开了。答案在里面。',
		intelType = 'environment',
		intelContent =
			'【终极情报—全类型汇总】\n• 地图深层必有书页房间，但需要耐心探索\n• 边缘小房间藏稀有书页，别只走主路\n• 可破坏墙壁存在于困难+地图\n• 谜题答案在观察细节中\n• 时间窗口撤离点可能出现假出口\n• 机关顺序藏在环境线索里\n• 噩梦难度避免长时间停留同一位置\n• Boss房在最远处\n• 隐藏入口在"空白区域"中心\n• 陷阱房间会伪装成撤离点\n• 传送门可能跳级',
		triggerItem = nil,
	},
}

-- 可触发物品定义（8个物品）
local TRIGGER_ITEMS: { [string]: TriggerItem } = {
	KindlingStone = {
		name = 'KindlingStone',
		description = '暗红色的粗糙石头，用于点燃古老装置',
		isConsumable = true,
		color = Color3.fromRGB(180, 60, 40),
		material = Enum.Material.Sandstone,
	},
	ResonanceHammer = {
		name = 'ResonanceHammer',
		description = '表面有声波纹路的石质锤头',
		isConsumable = true,
		color = Color3.fromRGB(140, 130, 120),
		material = Enum.Material.Stone,
	},
	ObservationLens = {
		name = 'ObservationLens',
		description = '半透明淡青色晶体，可观察隐形痕迹',
		isConsumable = false, -- 持久工具
		color = Color3.fromRGB(180, 220, 230),
		material = Enum.Material.Glass,
	},
	TrackingDust = {
		name = 'TrackingDust',
		description = '撒出金色微粒显示隐形路径',
		isConsumable = false, -- 持久工具
		color = Color3.fromRGB(220, 190, 100),
		material = Enum.Material.Fabric,
	},
	LightSeed = {
		name = 'LightSeed',
		description = '温橙色发光种子，照亮黑暗处',
		isConsumable = true,
		color = Color3.fromRGB(255, 180, 80),
		material = Enum.Material.Neon,
	},
	ResonanceShard = {
		name = 'ResonanceShard',
		description = '薄片状晶体，读取矿物记忆',
		isConsumable = true,
		color = Color3.fromRGB(220, 150, 80),
		material = Enum.Material.Glass,
	},
	RepairGear = {
		name = 'RepairGear',
		description = '部分缺损的青铜齿轮，激活古代机关',
		isConsumable = true,
		color = Color3.fromRGB(160, 155, 140),
		material = Enum.Material.Metal,
	},
	SilentEarring = {
		name = 'SilentEarring',
		description = '耳坠状饰品，倾听隐藏的声音',
		isConsumable = false, -- 持久工具
		color = Color3.fromRGB(120, 100, 140),
		material = Enum.Material.Glass,
	},
}

--#endregion

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

local NarrativeInteractionSystem = {}

-- 存储玩家的叙事碎片收集状态
local playerFragments: { [number]: { [string]: boolean } } = {}

-- 存储玩家持有的可触发物品
local playerItems: { [number]: { [string]: boolean } } = {}

-- 清理离开的玩家数据
Players.PlayerRemoving:Connect(function(player)
	playerFragments[player.UserId] = nil
	playerItems[player.UserId] = nil
end)

-- 初始化交互点
function NarrativeInteractionSystem.initialize(outdoorFolder: Folder)
	local folder = Instance.new('Folder')
	folder.Name = 'NarrativeInteractionPoints'
	folder.Parent = outdoorFolder

	-- 废弃神庙区交互点 (3个)
	NarrativeInteractionSystem.createAT_01(folder) -- 熄灭的守望者（引火石+灯塔）
	NarrativeInteractionSystem.createAT_02(folder) -- 墙上的最后一行
	NarrativeInteractionSystem.createAT_03(folder) -- 碎裂的回声（共鸣锤）

	-- 古代遗迹区交互点 (3个)
	NarrativeInteractionSystem.createAR_01(folder) -- 石碑的无字面（观测透镜）
	NarrativeInteractionSystem.createAR_02(folder) -- 失衡的天平
	NarrativeInteractionSystem.createAR_03(folder) -- 共鸣石的频率

	-- 荒野森林区交互点 (3个)
	NarrativeInteractionSystem.createWF_01(folder) -- 树洞里的眼睛（光源种子）
	NarrativeInteractionSystem.createWF_02(folder) -- 足迹的终点（追踪粉尘）
	NarrativeInteractionSystem.createWF_03(folder) -- 不存在的果实

	-- 洞穴遗迹区交互点 (4个)
	NarrativeInteractionSystem.createCR_01(folder) -- 矿物的脉搏（共振晶片）
	NarrativeInteractionSystem.createCR_02(folder) -- 机关的沉默（修复齿轮）
	NarrativeInteractionSystem.createCR_03(folder) -- 深渊的低语（静默耳坠）
	NarrativeInteractionSystem.createCR_04(folder) -- 最后的警告
end

-- 辅助方法：确保玩家的数据表存在
local function ensurePlayerData(player: Player)
	if not playerFragments[player.UserId] then
		playerFragments[player.UserId] = {}
	end
	if not playerItems[player.UserId] then
		playerItems[player.UserId] = {}
	end
end

-- 辅助方法：检查玩家是否已收集某碎片
function NarrativeInteractionSystem.hasCollected(player: Player, fragmentId: string): boolean
	local fragments = playerFragments[player.UserId]
	return fragments ~= nil and fragments[fragmentId] == true
end

-- 辅助方法：检查玩家是否持有某物品
function NarrativeInteractionSystem.hasItem(player: Player, itemName: string): boolean
	local items = playerItems[player.UserId]
	return items ~= nil and items[itemName] == true
end

-- 辅助方法：给玩家物品
function NarrativeInteractionSystem.giveItem(player: Player, itemName: string)
	ensurePlayerData(player)
	playerItems[player.UserId][itemName] = true
	Remotes.ShowNarrative:FireClient(
		player,
		'你获得了 ' .. (TRIGGER_ITEMS[itemName] and TRIGGER_ITEMS[itemName].description or itemName),
		'',
		''
	)
end

-- 辅助方法：消耗玩家物品
function NarrativeInteractionSystem.consumeItem(player: Player, itemName: string)
	if playerItems[player.UserId] then
		playerItems[player.UserId][itemName] = nil
	end
end

-- 辅助方法：给予碎片并显示内容
function NarrativeInteractionSystem.awardFragment(player: Player, fragmentId: string)
	ensurePlayerData(player)

	-- 已收集则不再重复
	if playerFragments[player.UserId][fragmentId] then
		return false
	end

	-- 标记已收集
	playerFragments[player.UserId][fragmentId] = true

	-- 找到碎片配置
	local config = nil
	for _, frag in ipairs(FRAGMENT_CONFIGS) do
		if frag.id == fragmentId then
			config = frag
			break
		end
	end

	if config then
		-- 显示叙事文字 + 情报内容
		Remotes.ShowNarrative:FireClient(
			player,
			config.title,
			config.narrativeText,
			config.intelContent
		)
	end

	return true
end

-- 辅助方法：创建ProximityPrompt
local function createPrompt(
	parent: Instance,
	actionText: string,
	objectText: string,
	keyCode: Enum.KeyCode,
	holdDuration: number,
	maxDistance: number?
): ProximityPrompt
	local prompt = Instance.new('ProximityPrompt')
	prompt.Name = actionText .. 'Prompt'
	prompt.ActionText = actionText
	prompt.ObjectText = objectText
	prompt.KeyboardKeyCode = keyCode
	prompt.HoldDuration = holdDuration
	if maxDistance then
		prompt.MaxActivationDistance = maxDistance
	else
		prompt.MaxActivationDistance = 6
	end
	prompt.RequiresLineOfSight = false
	prompt.Parent = parent
	return prompt
end

-- ========================================
-- AT-01: 熄灭的守望者（引火石 + 灯塔残骸）
-- ========================================
function NarrativeInteractionSystem.createAT_01(folder: Folder)
	local atFolder = Instance.new('Folder')
	atFolder.Name = 'AT_01_ExtinctWatchman'
	atFolder.Parent = folder

	-- 步骤1：引火石（在碎石堆旁）
	local kindlingStone = Instance.new('Part')
	kindlingStone.Name = 'KindlingStone'
	kindlingStone.Size = Vector3.new(0.8, 0.6, 0.8)
	kindlingStone.CFrame = CFrame.new(-55, 1, 50) -- 靠近Rubble1
	kindlingStone.Color = TRIGGER_ITEMS.KindlingStone.color
	kindlingStone.Material = TRIGGER_ITEMS.KindlingStone.material
	kindlingStone.CanCollide = false
	kindlingStone.Anchored = true
	atFolder.Parent = folder
	kindlingStone.Parent = atFolder

	-- 引火石发光提示
	local stoneLight = Instance.new('PointLight')
	stoneLight.Color = Color3.fromRGB(255, 100, 50)
	stoneLight.Brightness = 0.5
	stoneLight.Range = 4
	stoneLight.Parent = kindlingStone

	local stonePrompt = createPrompt(kindlingStone, '拾取', '引火石', Enum.KeyCode.E, 0.3)
	stonePrompt.Triggered:Connect(function(player)
		if NarrativeInteractionSystem.hasItem(player, 'KindlingStone') or kindlingStone:GetAttribute('Collected') then
			return
		end
		kindlingStone:SetAttribute('Collected', true)
		kindlingStone.Transparency = 1
		stoneLight.Enabled = false
		stonePrompt.Enabled = false
		NarrativeInteractionSystem.giveItem(player, 'KindlingStone')
	end)

	-- 步骤2：三座灯塔残骸（复用废弃神庙区的倒塌灯塔位置附近）
	local lighthousePositions = {
		CFrame.new(-68, 5, 28),
		CFrame.new(-75, 4, 33),
		CFrame.new(-82, 3, 38),
	}
	local litCount = 0

	for i, pos in ipairs(lighthousePositions) do
		local lhPart = Instance.new('Part')
		lhPart.Name = 'LighthouseRemnant_' .. i
		lhPart.Size = Vector3.new(4, 8, 4)
		lhPart.CFrame = pos
		lhPart.Color = Color3.fromRGB(90, 95, 100)
		lhPart.Material = Enum.Material.Slate
		lhPart.CanCollide = true
		lhPart.Anchored = true
		lhPart.Parent = atFolder

		local lhPrompt = createPrompt(lhPart, '点燃残留', '倒塌的灯塔残骸', Enum.KeyCode.E, 0.5, 8)

		lhPrompt.Triggered:Connect(function(player)
			if lhPart:GetAttribute('Lit') then
				return
			end
			if not NarrativeInteractionSystem.hasItem(player, 'KindlingStone') then
				Remotes.ShowNarrative:FireClient(
					player,
					'这座残骸冰冷而黑暗',
					'似乎需要某种火源才能唤醒...',
					''
				)
				return
			end

			lhPart:SetAttribute('Lit', true)

			-- 点燃特效
			local lhLight = Instance.new('PointLight')
			lhLight.Color = Color3.fromRGB(255, 200, 100)
			lhLight.Brightness = 2
			lhLight.Range = 15
			lhLight.Parent = lhPart

			-- 延迟熄灭（约3秒）
			task.delay(3, function()
				if lhLight then
					lhLight.Enabled = false
					lhLight:Destroy()
				end
			end)

			litCount += 1
			if litCount >= 3 then
				-- 三座点燃完成 → 给予碎片
				if NarrativeInteractionSystem.awardFragment(player, 'AT_01') then
					NarrativeInteractionSystem.consumeItem(player, 'KindlingStone')
				end
			end
		end)
	end
end

-- ========================================
-- AT-02: 墙上的最后一行（纯观察交互）
-- ========================================
function NarrativeInteractionSystem.createAT_02(folder: Folder)
	local atFolder = Instance.new('Folder')
	atFolder.Name = 'AT_02_LastLine'
	atFolder.Parent = folder

	-- 使用FallenWall1作为交互对象（通过属性标记找到）
	-- 在这里创建一个独立的交互部件
	local wallPart = Instance.new('Part')
	wallPart.Name = 'InscriptionWall'
	wallPart.Size = Vector3.new(12, 6, 0.5)
	wallPart.CFrame = CFrame.new(-50, 5, 42) * CFrame.Angles(0, math.rad(30), math.rad(-15))
	wallPart.Color = Color3.fromRGB(100, 105, 110)
	wallPart.Material = Enum.Material.Slate
	wallPart.CanCollide = false
	wallPart.Anchored = true
	wallPart.Transparency = 0.3
	wallPart.Parent = atFolder

	local wallPrompt = createPrompt(wallPart, '辨认墙面痕迹', '刻痕墙壁', Enum.KeyCode.E, 3, 7)
	wallPrompt.Triggered:Connect(function(player)
		if NarrativeInteractionSystem.hasCollected(player, 'AT_02') then
			return
		end
		NarrativeInteractionSystem.awardFragment(player, 'AT_02')
	end)
end

-- ========================================
-- AT-03: 碎裂的回声（共鸣锤 + 碎石堆）
-- ========================================
function NarrativeInteractionSystem.createAT_03(folder: Folder)
	local atFolder = Instance.new('Folder')
	atFolder.Name = 'AT_03_ShatteredEcho'
	atFolder.Parent = folder

	-- 共鸣锤（埋在第3个碎石堆中）
	local hammer = Instance.new('Part')
	hammer.Name = 'ResonanceHammer'
	hammer.Size = Vector3.new(0.6, 1.2, 0.6)
	hammer.CFrame = CFrame.new(-65, 2, 36) -- Rubble3附近
	hammer.Color = TRIGGER_ITEMS.ResonanceHammer.color
	hammer.Material = TRIGGER_ITEMS.ResonanceHammer.material
	hammer.CanCollide = false
	hammer.Anchored = true
	hammer.Parent = atFolder

	local hammerPrompt = createPrompt(hammer, '拾取', '共鸣锤', Enum.KeyCode.E, 0.3)
	hammerPrompt.Triggered:Connect(function(player)
		if NarrativeInteractionSystem.hasItem(player, 'ResonanceHammer') or hammer:GetAttribute('Collected') then
			return
		end
		hammer:SetAttribute('Collected', true)
		hammer.Transparency = 1
		hammerPrompt.Enabled = false
		NarrativeInteractionSystem.giveItem(player, 'ResonanceHammer')
	end)

	-- 敲击目标碎石堆（用4个碎石代表敲击序列）
	local rubbleTargets = {
		Vector3.new(-45, 1.5, 52),
		Vector3.new(-55, 1, 47),
		Vector3.new(-65, 2, 37),
		Vector3.new(-75, 1.3, 27),
	}
	local hitCount = 0

	for i, pos in ipairs(rubbleTargets) do
		local target = Instance.new('Part')
		target.Name = 'RubbleTarget_' .. i
		target.Size = Vector3.new(2, 1.5, 2)
		target.CFrame = CFrame.new(pos)
		target.Color = Color3.fromRGB(90, 95, 100)
		target.Material = Enum.Material.Slate
		target.Shape = Enum.PartType.Ball
		target.CanCollide = true
		target.Anchored = true
		target.Parent = atFolder

		local targetPrompt = createPrompt(target, '敲击', '碎石堆', Enum.KeyCode.E, 0.3)
		targetPrompt.Triggered:Connect(function(player)
			if target:GetAttribute('Hit') then
				return
			end
			if not NarrativeInteractionSystem.hasItem(player, 'ResonanceHammer') then
				return
			end
			target:SetAttribute('Hit', true)

			-- 敲击反馈
			target.Color = Color3.fromRGB(200, 180, 150)
			task.delay(0.5, function()
				target.Color = Color3.fromRGB(90, 95, 100)
			end)

			hitCount += 1
			if hitCount >= #rubbleTargets then
				if NarrativeInteractionSystem.awardFragment(player, 'AT_03') then
					NarrativeInteractionSystem.consumeItem(player, 'ResonanceHammer')
				end
			end
		end)
	end
end

-- ========================================
-- AR-01: 石碑的无字面（观测透镜 + 石碑1）
-- ========================================
function NarrativeInteractionSystem.createAR_01(folder: Folder)
	local arFolder = Instance.new('Folder')
	arFolder.Name = 'AR_01_BlankStele'
	arFolder.Parent = folder

	-- 观测透镜（嵌在石碑2基座）
	local lens = Instance.new('Part')
	lens.Name = 'ObservationLens'
	lens.Size = Vector3.new(0.4, 0.1, 0.4)
	lens.CFrame = CFrame.new(70, 4.2, 35) -- AncientStele2附近
	lens.Color = TRIGGER_ITEMS.ObservationLens.color
	lens.Material = TRIGGER_ITEMS.ObservationLens.material
	lens.CanCollide = false
	lens.Anchored = true
	lens.Parent = arFolder

	local lensPrompt = createPrompt(lens, '拔出', '观测透镜', Enum.KeyCode.E, 0.3)
	lensPrompt.Triggered:Connect(function(player)
		if NarrativeInteractionSystem.hasItem(player, 'ObservationLens') or lens:GetAttribute('Collected') then
			return
		end
		lens:SetAttribute('Collected', true)
		lens.Transparency = 1
		lensPrompt.Enabled = false
		NarrativeInteractionSystem.giveItem(player, 'ObservationLens')
	end)

	-- 目标石碑（石碑1位置）
	local steleTarget = Instance.new('Part')
	steleTarget.Name = 'SteleTarget'
	steleTarget.Size = Vector3.new(3.5, 9, 1.2) -- 与AncientStele1同尺寸
	steleTarget.CFrame = CFrame.new(60, 4.5, 30)
	steleTarget.Color = Color3.fromRGB(130, 135, 140)
	steleTarget.Material = Enum.Material.Slate
	steleTarget.CanCollide = false
	steleTarget.Anchored = true
	steleTarget.Transparency = 0.5
	steleTarget.Parent = arFolder

	local stelePrompt = createPrompt(steleTarget, '透过透镜观察', '古代石碑', Enum.KeyCode.E, 0)
	stelePrompt.Triggered:Connect(function(player)
		if NarrativeInteractionSystem.hasCollected(player, 'AR_01') then
			return
		end
		if not NarrativeInteractionSystem.hasItem(player, 'ObservationLens') then
			Remotes.ShowNarrative:FireClient(
				player,
				'石碑表面光滑无字',
				'也许需要某种工具来观察...',
				''
			)
			return
		end
		-- 自动播放文字浮现效果（客户端展示），然后给予碎片
		NarrativeInteractionSystem.awardFragment(player, 'AR_01')
	end)
end

-- ========================================
-- AR-02: 失衡的天平（直接触碰交互）
-- ========================================
function NarrativeInteractionSystem.createAR_02(folder: Folder)
	local arFolder = Instance.new('Folder')
	arFolder.Name = 'AR_02_UnbalancedScale'
	arFolder.Parent = folder

	-- 天平交互体（独立于OutdoorAreaBuilder中的装饰天平）
	local scalePart = Instance.new('Part')
	scalePart.Name = 'ScaleInteraction'
	scalePart.Size = Vector3.new(6, 0.5, 6)
	scalePart.CFrame = CFrame.new(75, 3, 55) -- 在AncientScalePillar顶部附近
	scalePart.Color = Color3.fromRGB(140, 145, 150)
	scalePart.Material = Enum.Material.Slate
	scalePart.CanCollide = false
	scalePart.Anchored = true
	scalePart.Transparency = 0.3
	scalePart.Parent = arFolder

	local scalePrompt = createPrompt(scalePart, '触碰天平', '古代天平', Enum.KeyCode.E, 0)
	scalePrompt.Triggered:Connect(function(player)
		if NarrativeInteractionSystem.hasCollected(player, 'AR_02') or scalePart:GetAttribute('Calmed') then
			return
		end
		scalePart:SetAttribute('Calmed', true)
		NarrativeInteractionSystem.awardFragment(player, 'AR_02')
	end)
end

-- ========================================
-- AR-03: 共鸣石的频率（逐个激活，无序）
-- ========================================
function NarrativeInteractionSystem.createAR_03(folder: Folder)
	local arFolder = Instance.new('Folder')
	arFolder.Name = 'AR_03_ResonanceFrequency'
	arFolder.Parent = folder

	-- 三个共鸣石交互点（与OutdoorAreaBuilder中的装饰石位置对应）
	local stonePositions = {
		Vector3.new(50, 2, 60),
		Vector3.new(55, 1.5, 70),
		Vector3.new(65, 2.5, 65),
	}
	local activatedCount = 0
	local playerActivations: { [number]: number } = {}

	for i, pos in ipairs(stonePositions) do
		local stonePart = Instance.new('Part')
		stonePart.Name = 'ResonanceStone_' .. i
		stonePart.Size = Vector3.new(4.2, 4.2, 4.2)
		stonePart.CFrame = CFrame.new(pos)
		stonePart.Color = Color3.fromRGB(145, 150, 155)
		stonePart.Material = Enum.Material.Slate
		stonePart.Shape = Enum.PartType.Ball
		stonePart.CanCollide = false
		stonePart.Anchored = true
		stonePart.Transparency = 0.3
		stonePart.Parent = arFolder

		local stonePrompt = createPrompt(stonePart, '激活', '共鸣石', Enum.KeyCode.E, 0)

		stonePrompt.Triggered:Connect(function(player)
			if NarrativeInteractionSystem.hasCollected(player, 'AR_03') then
				return
			end

			-- 每个玩家独立计数
			if not playerActivations[player.UserId] then
				playerActivations[player.UserId] = 0
			end

			if stonePart:GetAttribute('ActivatedBy' .. player.UserId) then
				return -- 该玩家已激活过这块
			end

			stonePart:SetAttribute('ActivatedBy' .. player.UserId, true)
			playerActivations[player.UserId] += 1

			-- 激活反馈：发光增强
			stonePart.Color = Color3.fromRGB(180, 190, 200)
			task.delay(1, function()
				stonePart.Color = Color3.fromRGB(145, 150, 155)
			end)

			if playerActivations[player.UserId] >= #stonePositions then
				NarrativeInteractionSystem.awardFragment(player, 'AR_03')
			end
		end)
	end
end

-- ========================================
-- WF-01: 树洞里的眼睛（光源种子 + 树洞树）
-- ========================================
function NarrativeInteractionSystem.createWF_01(folder: Folder)
	local wfFolder = Instance.new('Folder')
	wfFolder.Name = 'WF_01_EyesInTree'
	wfFolder.Parent = folder

	-- 光源种子（在某棵灌木丛根部）
	local seed = Instance.new('Part')
	seed.Name = 'LightSeed'
	seed.Size = Vector3.new(0.5, 0.5, 0.5)
	seed.CFrame = CFrame.new(18, 1, 82) -- Bush1附近
	seed.Color = TRIGGER_ITEMS.LightSeed.color
	seed.Material = TRIGGER_ITEMS.LightSeed.material
	seed.Shape = Enum.PartType.Ball
	seed.CanCollide = false
	seed.Anchored = true
	seed.Parent = wfFolder

	-- 种子发光
	local seedLight = Instance.new('PointLight')
	seedLight.Color = Color3.fromRGB(255, 180, 80)
	seedLight.Brightness = 1
	seedLight.Range = 5
	seedLight.Parent = seed

	local seedPrompt = createPrompt(seed, '拾取', '发光种子', Enum.KeyCode.E, 0.3)
	seedPrompt.Triggered:Connect(function(player)
		if NarrativeInteractionSystem.hasItem(player, 'LightSeed') or seed:GetAttribute('Collected') then
			return
		end
		seed:SetAttribute('Collected', true)
		seed.Transparency = 1
		seedLight.Enabled = false
		seedPrompt.Enabled = false
		NarrativeInteractionSystem.giveItem(player, 'LightSeed')
	end)

	-- 目标树洞（特定树木上的空洞标记）
	local treeHollow = Instance.new('Part')
	treeHollow.Name = 'TreeHollow'
	treeHollow.Size = Vector3.new(1.5, 2, 1.5)
	treeHollow.CFrame = CFrame.new(25, 7, 85) -- ForestTreeTrunk3附近
	treeHollow.Color = Color3.fromRGB(60, 40, 20)
	treeHollow.Material = Enum.Material.Wood
	treeHollow.CanCollide = false
	treeHollow.Anchored = true
	treeHollow.Transparency = 0.5
	treeHollow.Parent = wfFolder

	local hollowPrompt = createPrompt(treeHollow, '投入种子', '树洞', Enum.KeyCode.E, 0.5)
	hollowPrompt.Triggered:Connect(function(player)
		if NarrativeInteractionSystem.hasCollected(player, 'WF_01') or treeHollow:GetAttribute('Illuminated') then
			return
		end
		if not NarrativeInteractionSystem.hasItem(player, 'LightSeed') then
			Remotes.ShowNarrative:FireClient(
				player,
				'树洞深处一片漆黑',
				'似乎需要光源才能看清里面...',
				''
			)
			return
		end
		treeHollow:SetAttribute('Illuminated', true)

		-- 光照效果
		local hollowLight = Instance.new('PointLight')
		hollowLight.Color = Color3.fromRGB(255, 200, 100)
		hollowLight.Brightness = 2
		hollowLight.Range = 8
		hollowLight.Parent = treeHollow

		task.delay(5, function()
			if hollowLight then
				hollowLight.Enabled = false
				hollowLight:Destroy()
			end
		end)

		if NarrativeInteractionSystem.awardFragment(player, 'WF_01') then
			NarrativeInteractionSystem.consumeItem(player, 'LightSeed')
		end
	end)
end

-- ========================================
-- WF-02: 足迹的终点（追踪粉尘 + 足迹链）
-- ========================================
function NarrativeInteractionSystem.createWF_02(folder: Folder)
	local wfFolder = Instance.new('Folder')
	wfFolder.Name = 'WF_02_TrackEnd'
	wfFolder.Parent = folder

	-- 追踪粉尘（挂在树枝上）
	local dust = Instance.new('Part')
	dust.Name = 'TrackingDust'
	dust.Size = Vector3.new(0.3, 0.5, 0.3)
	dust.CFrame = CFrame.new(28, 14, 90) -- ForestTreeTrunk5附近（高处）
	dust.Color = TRIGGER_ITEMS.TrackingDust.color
	dust.Material = TRIGGER_ITEMS.TrackingDust.material
	dust.CanCollide = false
	dust.Anchored = true
	dust.Parent = wfFolder

	local dustPrompt = createPrompt(dust, '取下', '追踪粉尘袋', Enum.KeyCode.E, 0.3)
	dustPrompt.Triggered:Connect(function(player)
		if NarrativeInteractionSystem.hasItem(player, 'TrackingDust') or dust:GetAttribute('Collected') then
			return
		end
		dust:SetAttribute('Collected', true)
		dust.Transparency = 1
		dustPrompt.Enabled = false
		NarrativeInteractionSystem.giveItem(player, 'TrackingDust')
	end)

	-- 足迹终点（凹陷地面）
	local trackEnd = Instance.new('Part')
	trackEnd.Name = 'TrackEnd'
	trackEnd.Size = Vector3.new(1.5, 0.2, 2)
	trackEnd.CFrame = CFrame.new(31, 0.2, 97) -- 最后一个足迹标记附近
	trackEnd.Color = Color3.fromRGB(70, 70, 75)
	trackEnd.Material = Enum.Material.Slate
	trackEnd.CanCollide = false
	trackEnd.Anchored = true
	trackEnd.Transparency = 0.3
	trackEnd.Parent = wfFolder

	local trackPrompt = createPrompt(trackEnd, '调查', '凹陷痕迹', Enum.KeyCode.E, 0)
	trackPrompt.Triggered:Connect(function(player)
		if NarrativeInteractionSystem.hasCollected(player, 'WF_02') then
			return
		end
		if not NarrativeInteractionSystem.hasItem(player, 'TrackingDust') then
			Remotes.ShowNarrative:FireClient(
				player,
				'地面上有一个奇怪的凹陷',
				'似乎需要某种方式来追踪来源...',
				''
			)
			return
		end
		NarrativeInteractionSystem.awardFragment(player, 'WF_02')
	end)
end

-- ========================================
-- WF-03: 不存在的果实（直接交互）
-- ========================================
function NarrativeInteractionSystem.createWF_03(folder: Folder)
	local wfFolder = Instance.new('Folder')
	wfFolder.Name = 'WF_03_NonexistentFruit'
	wfFolder.Parent = folder

	-- 异常树枝（某棵树的异色分支）
	local branchPart = Instance.new('Part')
	branchPart.Name = 'AnomalousBranch'
	branchPart.Size = Vector3.new(1, 2, 1)
	branchPart.CFrame = CFrame.new(35, 15, 110) -- 某棵树的高处
	branchPart.Color = Color3.fromRGB(140, 100, 160) -- 偏紫色调，与其他树不同
	branchPart.Material = Enum.Material.Wood
	branchPart.CanCollide = false
	branchPart.Anchored = true
	branchPart.Transparency = 0.3
	branchPart.Parent = wfFolder

	local branchPrompt = createPrompt(branchPart, '触碰', '异色树枝', Enum.KeyCode.E, 0)
	branchPrompt.Triggered:Connect(function(player)
		if NarrativeInteractionSystem.hasCollected(player, 'WF_03') or branchPart:GetAttribute('Touched') then
			return
		end
		branchPart:SetAttribute('Touched', true)
		-- 树枝闪烁效果
		branchPart.Color = Color3.fromRGB(200, 150, 220)
		task.delay(2, function()
			branchPart.Color = Color3.fromRGB(140, 100, 160)
		end)
		NarrativeInteractionSystem.awardFragment(player, 'WF_03')
	end)
end

-- ========================================
-- CR-01: 矿物的脉搏（共振晶片 + 矿物）
-- ========================================
function NarrativeInteractionSystem.createCR_01(folder: Folder)
	local crFolder = Instance.new('Folder')
	crFolder.Name = 'CR_01_MineralPulse'
	crFolder.Parent = folder

	-- 共振晶片（嵌在特殊深橙色矿物中）
	local shard = Instance.new('Part')
	shard.Name = 'ResonanceShard'
	shard.Size = Vector3.new(0.4, 0.15, 0.4)
	shard.CFrame = CFrame.new(-6, 6.3, 175) -- GlowingMineral3位置（偏深橙色）
	shard.Color = TRIGGER_ITEMS.ResonanceShard.color
	shard.Material = TRIGGER_ITEMS.ResonanceShard.material
	shard.CanCollide = false
	shard.Anchored = true
	shard.Parent = crFolder

	local shardPrompt = createPrompt(shard, '小心取出', '共振晶片', Enum.KeyCode.E, 0.5)
	shardPrompt.Triggered:Connect(function(player)
		if NarrativeInteractionSystem.hasItem(player, 'ResonanceShard') or shard:GetAttribute('Collected') then
			return
		end
		shard:SetAttribute('Collected', true)
		shard.Transparency = 1
		shardPrompt.Enabled = false
		NarrativeInteractionSystem.giveItem(player, 'ResonanceShard')
	end)

	-- 目标矿物（普通发光矿物）
	local targetMineral = Instance.new('Part')
	targetMineral.Name = 'TargetMineral'
	targetMineral.Size = Vector3.new(1.8, 1.8, 1.8)
	targetMineral.CFrame = CFrame.new(8, 4.8, 165) -- GlowingMineral2附近
	targetMineral.Color = Color3.fromRGB(200, 150, 100)
	targetMineral.Material = Enum.Material.Neon
	targetMineral.Shape = Enum.PartType.Ball
	targetMineral.CanCollide = false
	targetMineral.Anchored = true
	targetMineral.Parent = crFolder

	local mineralPrompt = createPrompt(targetMineral, '读取记忆', '发光矿物', Enum.KeyCode.E, 0)
	mineralPrompt.Triggered:Connect(function(player)
		if NarrativeInteractionSystem.hasCollected(player, 'CR_01') or targetMineral:GetAttribute('Read') then
			return
		end
		if not NarrativeInteractionSystem.hasItem(player, 'ResonanceShard') then
			Remotes.ShowNarrative:FireClient(
				player,
				'矿物表面有微弱的光芒流动',
				'也许需要某种媒介来读取...',
				''
			)
			return
		end
		targetMineral:SetAttribute('Read', true)

		-- 强光投影效果
		targetMineral.Color = Color3.fromRGB(255, 230, 180)
		local projLight = Instance.new('PointLight')
		projLight.Color = Color3.fromRGB(255, 230, 180)
		projLight.Brightness = 3
		projLight.Range = 20
		projLight.Parent = targetMineral

		task.delay(3, function()
			projLight.Enabled = false
			projLight:Destroy()
			targetMineral.Color = Color3.fromRGB(200, 150, 100)
		end)

		if NarrativeInteractionSystem.awardFragment(player, 'CR_01') then
			NarrativeInteractionSystem.consumeItem(player, 'ResonanceShard')
		end
	end)
end

-- ========================================
-- CR-02: 机关的沉默（修复齿轮 + 古代机关）
-- ========================================
function NarrativeInteractionSystem.createCR_02(folder: Folder)
	local crFolder = Instance.new('Folder')
	crFolder.Name = 'CR_02_MechanismSilence'
	crFolder.Parent = folder

	-- 修复齿轮在宝藏箱内 → 这里直接放在宝藏箱旁边作为拾取物
	local gear = Instance.new('Part')
	gear.Name = 'RepairGear'
	gear.Size = Vector3.new(0.5, 0.25, 0.5)
	gear.CFrame = CFrame.new(2.5, 2, 165) -- TreasureChest附近
	gear.Color = TRIGGER_ITEMS.RepairGear.color
	gear.Material = TRIGGER_ITEMS.RepairGear.material
	gear.CanCollide = false
	gear.Anchored = true
	gear.Parent = crFolder

	local gearPrompt = createPrompt(gear, '取出', '修复齿轮', Enum.KeyCode.E, 0.3)
	gearPrompt.Triggered:Connect(function(player)
		if NarrativeInteractionSystem.hasItem(player, 'RepairGear') or gear:GetAttribute('Collected') then
			return
		end
		gear:SetAttribute('Collected', true)
		gear.Transparency = 1
		gearPrompt.Enabled = false
		NarrativeInteractionSystem.giveItem(player, 'RepairGear')
	end)

	-- 目标古代机关（独立交互体）
	local mechPart = Instance.new('Part')
	mechPart.Name = 'MechanismTarget'
	mechPart.Size = Vector3.new(7, 3.5, 7)
	mechPart.CFrame = CFrame.new(0, 3, 180) -- AncientMechanism上方
	mechPart.Color = Color3.fromRGB(125, 130, 135)
	mechPart.Material = Enum.Material.Metal
	mechPart.CanCollide = false
	mechPart.Anchored = true
	mechPart.Transparency = 0.3
	mechPart.Parent = crFolder

	local mechPrompt = createPrompt(mechPart, '安装齿轮', '古代机关', Enum.KeyCode.E, 0.5)
	mechPrompt.Triggered:Connect(function(player)
		if NarrativeInteractionSystem.hasCollected(player, 'CR_02') or mechPart:GetAttribute('Activated') then
			return
		end
		if not NarrativeInteractionSystem.hasItem(player, 'RepairGear') then
			Remotes.ShowNarrative:FireClient(
				player,
				'机关表面有一个齿轮形的凹槽',
				'似乎缺少了关键部件...',
				''
			)
			return
		end
		mechPart:SetAttribute('Activated', true)

		-- 启动效果
		mechPart.Color = Color3.fromRGB(170, 175, 180)
		task.delay(3, function()
			mechPart.Color = Color3.fromRGB(125, 130, 135)
		end)

		if NarrativeInteractionSystem.awardFragment(player, 'CR_02') then
			NarrativeInteractionSystem.consumeItem(player, 'RepairGear')
		end
	end)
end

-- ========================================
-- CR-03: 深渊的低语（静默耳坠 + 裂缝）
-- ========================================
function NarrativeInteractionSystem.createCR_03(folder: Folder)
	local crFolder = Instance.new('Folder')
	crFolder.Name = 'CR_03_AbyssWhisper'
	crFolder.Parent = folder

	-- 静默耳坠（半埋在裂缝边缘）
	local earring = Instance.new('Part')
	earring.Name = 'SilentEarring'
	earring.Size = Vector3.new(0.2, 0.4, 0.1)
	earring.CFrame = CFrame.new(-1, 0.2, 170) -- CaveInteriorGround附近（裂缝位置）
	earring.Color = TRIGGER_ITEMS.SilentEarring.color
	earring.Material = TRIGGER_ITEMS.SilentEarring.material
	earring.CanCollide = false
	earring.Anchored = true
	earring.Parent = crFolder

	local earringPrompt = createPrompt(earring, '拾取', '静默耳坠', Enum.KeyCode.E, 0.3)
	earringPrompt.Triggered:Connect(function(player)
		if NarrativeInteractionSystem.hasItem(player, 'SilentEarring') or earring:GetAttribute('Collected') then
			return
		end
		earring:SetAttribute('Collected', true)
		earring.Transparency = 1
		earringPrompt.Enabled = false
		NarrativeInteractionSystem.giveItem(player, 'SilentEarring')

		-- 拾取后自动触发碎片效果（简化设计：不需要额外走到裂缝处）
		if NarrativeInteractionSystem.awardFragment(player, 'CR_03') then
			-- 暗紫色脉冲效果通过客户端叙事文本暗示
			-- 持久工具，不消耗
		end
	end)
end

-- ========================================
-- CR-04: 最后的警告（直接凝视交互）
-- ========================================
function NarrativeInteractionSystem.createCR_04(folder: Folder)
	local crFolder = Instance.new('Folder')
	crFolder.Name = 'CR_04_FinalWarning'
	crFolder.Parent = folder

	-- 洞穴入口交互体（迷宫入口区域）
	local gatePart = Instance.new('Part')
	gatePart.Name = 'GateInsight'
	gatePart.Size = Vector3.new(24, 2, 6) -- 门梁宽度范围
	gatePart.CFrame = CFrame.new(0, 19, 132) -- MazeGateBeam上方
	gatePart.Color = Color3.fromRGB(91, 95, 102)
	gatePart.Material = Enum.Material.Slate
	gatePart.CanCollide = false
	gatePart.Anchored = true
	gatePart.Transparency = 0.8
	gatePart.Parent = crFolder

	local gatePrompt = createPrompt(gatePart, '凝视入口', '洞穴入口', Enum.KeyCode.E, 2, 12)
	gatePrompt.Triggered:Connect(function(player)
		if NarrativeInteractionSystem.hasCollected(player, 'CR_04') or gatePart:GetAttribute('Witnessed') then
			return
		end
		gatePart:SetAttribute('Witnessed', true)

		-- 入口发光效果
		gatePart.Color = Color3.fromRGB(200, 200, 220)
		task.delay(2, function()
			gatePart.Color = Color3.fromRGB(91, 95, 102)
		end)

		NarrativeInteractionSystem.awardFragment(player, 'CR_04')
	end)
end

--#endregion

return NarrativeInteractionSystem


