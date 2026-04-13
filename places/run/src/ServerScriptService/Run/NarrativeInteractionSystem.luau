--!strict
-- ════════════════════════════════════════════════════════════
-- NarrativeInteractionSystem.luau — 叙事交互系统（逻辑层）
--
-- 所有文字内容已抽离到 NarrativeContent.luau 本文件只负责：
-- 1. 创建物体、设置位置和材质
-- 2. 绑定 ProximityPrompt 和交互回调
-- 3. 管理玩家状态（碎片/物品/进度）
-- 4. 调用 RemoteEvent 显示叙事内容
-- 5. 视觉特效逻辑
--
-- 修改文案 → 改 NarrativeContent.luau
-- 修改交互逻辑/坐标/特效 → 改本文件
-- ════════════════════════════════════════════════════════════

local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')

-- ── 加载纯文案配置 ──
local Content = require(script.Parent.NarrativeContent)

-- ── 网络模块 ──
local Packages = ReplicatedStorage:WaitForChild('Packages')
local Shared = require(Packages:WaitForChild('Shared'))
local Remotes = Shared.Network.Remotes.waitForScope(Shared.Network.Remotes.Scope.Run)

-- ════════════════════════════════════════════════════════════
-- 模块
-- ════════════════════════════════════════════════════════════

local NarrativeInteractionSystem = {}

-- 玩家状态存储
local playerFragments: { [number]: { [string]: boolean } } = {}
local playerItems: { [number]: { [string]: boolean } } = {}
local playerProgress: { [number]: { [string]: number } } = {}

-- 清理离开的玩家数据
Players.PlayerRemoving:Connect(function(player)
	local uid = player.UserId
	playerFragments[uid] = nil
	playerItems[uid] = nil
	playerProgress[uid] = nil
end)

-- ════════════════════════════════════════════════════════════
-- 初始化入口：按区域创建所有交互点
-- ════════════════════════════════════════════════════════════

function NarrativeInteractionSystem.initialize(outdoorFolder: Folder)
	local folder = Instance.new('Folder')
	folder.Name = 'NarrativeInteractionPoints'
	folder.Parent = outdoorFolder

	-- 废弃神庙区 (AT)
	NarrativeInteractionSystem.createAT_01(folder)
	NarrativeInteractionSystem.createAT_02(folder)
	NarrativeInteractionSystem.createAT_03(folder)

	-- 古代遗迹区 (AR)
	NarrativeInteractionSystem.createAR_01(folder)
	NarrativeInteractionSystem.createAR_02(folder)
	NarrativeInteractionSystem.createAR_03(folder)

	-- 荒野森林区 (WF)
	NarrativeInteractionSystem.createWF_01(folder)
	NarrativeInteractionSystem.createWF_02(folder)
	NarrativeInteractionSystem.createWF_03(folder)

	-- 洞穴遗迹区 (CR)
	-- 注意顺序：CR-03 在空间上比 CR-01/02 更靠前，先创建
	NarrativeInteractionSystem.createCR_03(folder)
	NarrativeInteractionSystem.createCR_01(folder)
	NarrativeInteractionSystem.createCR_02(folder)
	NarrativeInteractionSystem.createCR_04(folder)
end

-- ════════════════════════════════════════════════════════════
-- 玩家状态查询辅助方法
-- ════════════════════════════════════════════════════════════

local function ensurePlayerData(player: Player)
	if not playerFragments[player.UserId] then
		playerFragments[player.UserId] = {}
	end
	if not playerItems[player.UserId] then
		playerItems[player.UserId] = {}
	end
end

function NarrativeInteractionSystem.hasCollected(player: Player, fragmentId: string): boolean
	local fragments = playerFragments[player.UserId]
	return fragments ~= nil and fragments[fragmentId] == true
end

function NarrativeInteractionSystem.hasItem(player: Player, itemName: string): boolean
	local items = playerItems[player.UserId]
	return items ~= nil and items[itemName] == true
end

function NarrativeInteractionSystem.getCollectedCount(player: Player): number
	local fragments = playerFragments[player.UserId]
	if not fragments then return 0 end
	local count = 0
	for _ in pairs(fragments) do count += 1 end
	return count
end

-- ════════════════════════════════════════════════════════════
-- 物品操作辅助方法
-- ════════════════════════════════════════════════════════════

function NarrativeInteractionSystem.giveItem(player: Player, itemName: string)
	ensurePlayerData(player)
	playerItems[player.UserId][itemName] = true

	local itemDef = Content.TRIGGER_ITEMS[itemName]
	if itemDef and itemDef.obtainMessage ~= '' then
		Remotes.ShowNarrative:FireClient(
			player,
			itemDef.obtainMessage,
			itemDef.obtainHint,
			''
		)
	end
end

function NarrativeInteractionSystem.consumeItem(player: Player, itemName: string)
	if playerItems[player.UserId] then
		playerItems[player.UserId][itemName] = nil
	end
end

-- ════════════════════════════════════════════════════════════
-- 碎片发放 + 叙事显示
-- ════════════════════════════════════════════════════════════

function NarrativeInteractionSystem.awardFragment(player: Player, fragmentId: string): boolean
	ensurePlayerData(player)

	-- 已收集则跳过
	if playerFragments[player.UserId][fragmentId] then
		return false
	end

	-- 标记已收集
	playerFragments[player.UserId][fragmentId] = true

	-- 从 Content 中查找碎片配置
	local config = nil
	for _, frag in ipairs(Content.FRAGMENTS) do
		if frag.id == fragmentId then
			config = frag
			break
		end
	end

	if config then
		-- CR-04 特殊处理：渐进显现
		if fragmentId == 'CR_04' then
			local collectedCount = NarrativeInteractionSystem.getCollectedCount(player)
			-- collectedCount 此时已包含 CR-04（刚标记），所以是总数
			local displayText = Content.getCR04Text(collectedCount)
			Remotes.ShowNarrative:FireClient(
				player,
				config.title,
				displayText,
				config.intelContent
			)
		else
			-- 普通碎片：显示叙事文字 + 情报内容
			Remotes.ShowNarrative:FireClient(
				player,
				config.title,
				config.narrativeText,
				config.intelContent
			)
		end
	end

	return true
end

-- ════════════════════════════════════════════════════════════
-- ProximityPrompt 工厂方法（统一创建 Prompt）
-- ════════════════════════════════════════════════════════════

local function createPrompt(
	parent: Instance,
	promptKey: string,
	maxDistance: number?
): ProximityPrompt
	local promptConfig = Content.PROMPTS[promptKey]
	if not promptConfig then
		error('[NarrativeSystem] 未找到 Prompt 配置: ' .. promptKey)
	end

	local prompt = Instance.new('ProximityPrompt')
	prompt.Name = promptConfig.actionText .. 'Prompt'
	prompt.ActionText = promptConfig.actionText
	prompt.ObjectText = promptConfig.objectText
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = promptConfig.holdDuration
	prompt.MaxActivationDistance = maxDistance or 6
	prompt.RequiresLineOfSight = false
	prompt.Parent = parent
	return prompt
end

-- ════════════════════════════════════════════════════════════
-- AT-01: 熄灭的守望者（引火石 + 3座灯塔残骸）
-- ════════════════════════════════════════════════════════════

function NarrativeInteractionSystem.createAT_01(folder: Folder)
	local atFolder = Instance.new('Folder')
	atFolder.Name = 'AT_01_ExtinctWatchman'
	atFolder.Parent = folder

	local itemDef = Content.TRIGGER_ITEMS.KindlingStone
	local promptPickup = Content.PROMPTS.AT_01_PickupStone

	-- 步骤1：引火石（碎石堆旁）
	local kindlingStone = Instance.new('Part')
	kindlingStone.Name = 'KindlingStone'
	kindlingStone.Size = Vector3.new(0.8, 0.6, 0.8)
	kindlingStone.CFrame = CFrame.new(-55, 1, 50)
	kindlingStone.Color = itemDef.color
	kindlingStone.Material = itemDef.material
	kindlingStone.CanCollide = false
	kindlingStone.Anchored = true
	kindlingStone.Parent = atFolder

	-- 引火石发光提示
	local stoneLight = Instance.new('PointLight')
	stoneLight.Color = Color3.fromRGB(255, 100, 50)
	stoneLight.Brightness = 0.5
	stoneLight.Range = 4
	stoneLight.Parent = kindlingStone

	local stonePrompt = createPrompt(kindlingStone, 'AT_01_PickupStone')
	stonePrompt.Triggered:Connect(function(player)
		if NarrativeInteractionSystem.hasItem(player, 'KindlingStone') then return end
		NarrativeInteractionSystem.giveItem(player, 'KindlingStone')
	end)

	-- 步骤2：三座灯塔残骸
	local lighthousePositions = {
		CFrame.new(-68, 5, 28),
		CFrame.new(-75, 4, 33),
		CFrame.new(-82, 3, 38),
	}
	local totalBeacons = #lighthousePositions
	local progressFormat = Content.PROGRESS_FEEDBACK.AT_01_BeaconProgress.format

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

		local lhPrompt = createPrompt(lhPart, 'AT_01_LightBeacon', 8)
		local missingHint = Content.MISSING_ITEM_HINTS.AT_01_BeaconNeedsFire

		lhPrompt.Triggered:Connect(function(player)
			if NarrativeInteractionSystem.hasCollected(player, 'AT_01') then return end
			if not NarrativeInteractionSystem.hasItem(player, 'KindlingStone') then
				Remotes.ShowNarrative:FireClient(player, missingHint.title, missingHint.hint, '')
				return
			end

			local playerLitKey = 'LitBy' .. player.UserId
			if lhPart:GetAttribute(playerLitKey) then return end
			lhPart:SetAttribute(playerLitKey, true)

			-- 点燃特效
			local lhLight = Instance.new('PointLight')
			lhLight.Color = Color3.fromRGB(255, 200, 100)
			lhLight.Brightness = 2
			lhLight.Range = 15
			lhLight.Parent = lhPart

			task.delay(3, function()
				if lhLight then
					lhLight.Enabled = false
					lhLight:Destroy()
				end
			end)

			-- 按玩家独立计数
			local uid = player.UserId
			if not playerProgress[uid] then playerProgress[uid] = {} end
			if not playerProgress[uid]['AT_01'] then playerProgress[uid]['AT_01'] = 0 end
			playerProgress[uid]['AT_01'] += 1
			local currentCount = playerProgress[uid]['AT_01']

			-- ★ 进度反馈文字（通过 ShowNarrative 发送给客户端渲染 "N / 3"）
			local progressText = string.format(progressFormat, currentCount)
			if currentCount >= totalBeacons then
				-- 三座点燃完成 → 给予碎片
				progressText = progressText .. '\n\n' .. Content.PROGRESS_FEEDBACK.AT_01_BeaconProgress.completedEffect
				Remotes.ShowNarrative:FireClient(player, progressText, '', '')
				task.delay(0.5, function()
					if NarrativeInteractionSystem.awardFragment(player, 'AT_01') then
						NarrativeInteractionSystem.consumeItem(player, 'KindlingStone')
					end
				end)
			else
				-- 显示进度数字
				Remotes.ShowNarrative:FireClient(player, progressText, '', '')
			end
		end)
	end
end

-- ════════════════════════════════════════════════════════════
-- AT-02: 墙上的最后一行（纯观察交互，Hold 3秒）
-- ════════════════════════════════════════════════════════════

function NarrativeInteractionSystem.createAT_02(folder: Folder)
	local atFolder = Instance.new('Folder')
	atFolder.Name = 'AT_02_LastLine'
	atFolder.Parent = folder

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

	local wallPrompt = createPrompt(wallPart, 'AT_02_ReadWall', 7)
	wallPrompt.Triggered:Connect(function(player)
		if NarrativeInteractionSystem.hasCollected(player, 'AT_02') then return end
		NarrativeInteractionSystem.awardFragment(player, 'AT_02')

		-- 标记墙壁状态
		wallPart:SetAttribute('DecipheredBy' .. player.UserId, true)
	end)
end

-- ════════════════════════════════════════════════════════════
-- AT-03: 碎裂的回声（共鸣锤 + 4个碎石堆）
-- ════════════════════════════════════════════════════════════

function NarrativeInteractionSystem.createAT_03(folder: Folder)
	local atFolder = Instance.new('Folder')
	atFolder.Name = 'AT_03_ShardedEcho'
	atFolder.Parent = folder

	local hammerDef = Content.TRIGGER_ITEMS.ResonanceHammer

	-- 共鸣锤（埋在第3个碎石堆中）
	local hammer = Instance.new('Part')
	hammer.Name = 'ResonanceHammer'
	hammer.Size = Vector3.new(0.6, 1.2, 0.6)
	hammer.CFrame = CFrame.new(-65, 2, 36)
	hammer.Color = hammerDef.color
	hammer.Material = hammerDef.material
	hammer.CanCollide = false
	hammer.Anchored = true
	hammer.Parent = atFolder

	local hammerPrompt = createPrompt(hammer, 'AT_03_PickupHammer')
	hammerPrompt.Triggered:Connect(function(player)
		if NarrativeInteractionSystem.hasItem(player, 'ResonanceHammer') then return end
		NarrativeInteractionSystem.giveItem(player, 'ResonanceHammer')
	end)

	-- 敲击目标碎石堆
	local rubbleTargets = {
		Vector3.new(-45, 1.5, 52),
		Vector3.new(-55, 1, 47),
		Vector3.new(-65, 2, 37),
		Vector3.new(-75, 1.3, 27),
	}
	local totalTargets = #rubbleTargets
	local progressFormat = Content.PROGRESS_FEEDBACK.AT_03_RubbleProgress.format

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

		local targetPrompt = createPrompt(target, 'AT_03_HitRubble')
		targetPrompt.Triggered:Connect(function(player)
			if NarrativeInteractionSystem.hasCollected(player, 'AT_03') then return end
			if not NarrativeInteractionSystem.hasItem(player, 'ResonanceHammer') then return end

			local hitKey = 'HitBy' .. player.UserId
			if target:GetAttribute(hitKey) then return end
			target:SetAttribute(hitKey, true)

			-- 敲击视觉反馈（全局可见）
			target.Color = Color3.fromRGB(200, 180, 150)
			task.delay(0.5, function()
				target.Color = Color3.fromRGB(90, 95, 100)
			end)

			-- 按玩家独立计数
			local uid = player.UserId
			if not playerProgress[uid] then playerProgress[uid] = {} end
			if not playerProgress[uid]['AT_03'] then playerProgress[uid]['AT_03'] = 0 end
			playerProgress[uid]['AT_03'] += 1
			local currentCount = playerProgress[uid]['AT_03']

			if currentCount >= totalTargets then
				local progressText = string.format(progressFormat, currentCount)
					.. '\n\n'
					.. Content.PROGRESS_FEEDBACK.AT_03_RubbleProgress.completedEffect
				Remotes.ShowNarrative:FireClient(player, progressText, '', '')
				task.delay(0.5, function()
					if NarrativeInteractionSystem.awardFragment(player, 'AT_03') then
						NarrativeInteractionSystem.consumeItem(player, 'ResonanceHammer')
					end
				end)
			else
				-- 显示进度
				Remotes.ShowNarrative:FireClient(player, string.format(progressFormat, currentCount), '', '')
			end
		end)
	end
end

-- ════════════════════════════════════════════════════════════
-- AR-01: 石碑的无字面（观测透镜 + 石碑1）
-- ════════════════════════════════════════════════════════════

function NarrativeInteractionSystem.createAR_01(folder: Folder)
	local arFolder = Instance.new('Folder')
	arFolder.Name = 'AR_01_BlankStele'
	arFolder.Parent = folder

	local lensDef = Content.TRIGGER_ITEMS.ObservationLens

	-- 观测透镜（嵌在石碑2基座）
	local lens = Instance.new('Part')
	lens.Name = 'ObservationLens'
	lens.Size = Vector3.new(0.4, 0.1, 0.4)
	lens.CFrame = CFrame.new(70, 4.2, 35)
	lens.Color = lensDef.color
	lens.Material = lensDef.material
	lens.CanCollide = false
	lens.Anchored = true
	lens.Parent = arFolder

	local lensPrompt = createPrompt(lens, 'AR_01_PickupLens')
	lensPrompt.Triggered:Connect(function(player)
		if NarrativeInteractionSystem.hasItem(player, 'ObservationLens') then return end
		NarrativeInteractionSystem.giveItem(player, 'ObservationLens')
	end)

	-- 目标石碑（石碑1位置）
	local steleTarget = Instance.new('Part')
	steleTarget.Name = 'SteleTarget'
	steleTarget.Size = Vector3.new(3.5, 9, 1.2)
	steleTarget.CFrame = CFrame.new(60, 4.5, 30)
	steleTarget.Color = Color3.fromRGB(130, 135, 140)
	steleTarget.Material = Enum.Material.Slate
	steleTarget.CanCollide = false
	steleTarget.Anchored = true
	steleTarget.Transparency = 0.5
	steleTarget.Parent = arFolder

	local stelePrompt = createPrompt(steleTarget, 'AR_01_ObserveStele')
	local missingHint = Content.MISSING_ITEM_HINTS.AR_01_SteleBlank

	stelePrompt.Triggered:Connect(function(player)
		if NarrativeInteractionSystem.hasCollected(player, 'AR_01') then return end
		if not NarrativeInteractionSystem.hasItem(player, 'ObservationLens') then
			Remotes.ShowNarrative:FireClient(player, missingHint.title, missingHint.hint, '')
			return
		end
		NarrativeInteractionSystem.awardFragment(player, 'AR_01')
	end)
end

-- ════════════════════════════════════════════════════════════
-- AR-02: 失衡的天平（直接触碰交互）
-- ════════════════════════════════════════════════════════════

function NarrativeInteractionSystem.createAR_02(folder: Folder)
	local arFolder = Instance.new('Folder')
	arFolder.Name = 'AR_02_UnbalancedScale'
	arFolder.Parent = folder

	local scalePart = Instance.new('Part')
	scalePart.Name = 'ScaleInteraction'
	scalePart.Size = Vector3.new(6, 0.5, 6)
	scalePart.CFrame = CFrame.new(75, 3, 55)
	scalePart.Color = Color3.fromRGB(140, 145, 150)
	scalePart.Material = Enum.Material.Slate
	scalePart.CanCollide = false
	scalePart.Anchored = true
	scalePart.Transparency = 0.3
	scalePart.Parent = arFolder

	local scalePrompt = createPrompt(scalePart, 'AR_02_TouchScale')
	scalePrompt.Triggered:Connect(function(player)
		if NarrativeInteractionSystem.hasCollected(player, 'AR_02') or scalePart:GetAttribute('Calmed') then
			return
		end
		scalePart:SetAttribute('Calmed', true)
		NarrativeInteractionSystem.awardFragment(player, 'AR_02')
	end)
end

-- ════════════════════════════════════════════════════════════
-- AR-03: 共鸣石的频率（3块石头逐个激活）
-- ════════════════════════════════════════════════════════════

function NarrativeInteractionSystem.createAR_03(folder: Folder)
	local arFolder = Instance.new('Folder')
	arFolder.Name = 'AR_03_ResonanceFrequency'
	arFolder.Parent = folder

	local stonePositions = {
		Vector3.new(50, 2, 60),
		Vector3.new(55, 1.5, 70),
		Vector3.new(65, 2.5, 65),
	}
	local totalStones = #stonePositions

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

		local stonePrompt = createPrompt(stonePart, 'AR_03_ActivateStone')

		stonePrompt.Triggered:Connect(function(player)
			if NarrativeInteractionSystem.hasCollected(player, 'AR_03') then return end

			if stonePart:GetAttribute('ActivatedBy' .. player.UserId) then return end
			stonePart:SetAttribute('ActivatedBy' .. player.UserId, true)

			-- 激活视觉效果
			stonePart.Color = Color3.fromRGB(180, 190, 200)
			task.delay(1, function()
				stonePart.Color = Color3.fromRGB(145, 150, 155)
			end)

			-- 计数
			local uid = player.UserId
			if not playerProgress[uid] then playerProgress[uid] = {} end
			if not playerProgress[uid]['AR_03'] then playerProgress[uid]['AR_03'] = 0 end
			playerProgress[uid]['AR_03'] += 1

			if playerProgress[uid]['AR_03'] >= totalStones then
				-- 全部激活完成
				Remotes.ShowNarrative:FireClient(
					player,
					Content.PROGRESS_FEEDBACK.AR_03_StoneProgress.allActivatedEffect,
					'',
					''
				)
				task.delay(0.5, function()
					NarrativeInteractionSystem.awardFragment(player, 'AR_03')
				end)
			end
		end)
	end
end

-- ════════════════════════════════════════════════════════════
-- WF-01: 树洞里的眼睛（光源种子 + 树洞树）
-- ════════════════════════════════════════════════════════════

function NarrativeInteractionSystem.createWF_01(folder: Folder)
	local wfFolder = Instance.new('Folder')
	wfFolder.Name = 'WF_01_EyesInTree'
	wfFolder.Parent = folder

	local seedDef = Content.TRIGGER_ITEMS.LightSeed

	-- 光源种子（灌木丛根部）
	local seed = Instance.new('Part')
	seed.Name = 'LightSeed'
	seed.Size = Vector3.new(0.5, 0.5, 0.5)
	seed.CFrame = CFrame.new(18, 1, 82)
	seed.Color = seedDef.color
	seed.Material = seedDef.material
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

	local seedPrompt = createPrompt(seed, 'WF_01_PickupSeed')
	seedPrompt.Triggered:Connect(function(player)
		if NarrativeInteractionSystem.hasItem(player, 'LightSeed') then return end
		NarrativeInteractionSystem.giveItem(player, 'LightSeed')
	end)

	-- 目标树洞
	local treeHollow = Instance.new('Part')
	treeHollow.Name = 'TreeHollow'
	treeHollow.Size = Vector3.new(1.5, 2, 1.5)
	treeHollow.CFrame = CFrame.new(25, 7, 85)
	treeHollow.Color = Color3.fromRGB(60, 40, 20)
	treeHollow.Material = Enum.Material.Wood
	treeHollow.CanCollide = false
	treeHollow.Anchored = true
	treeHollow.Transparency = 0.5
	treeHollow.Parent = wfFolder

	local hollowPrompt = createPrompt(treeHollow, 'WF_01_DepositSeed')
	local missingHint = Content.MISSING_ITEM_HINTS.WF_01_TreeDark

	hollowPrompt.Triggered:Connect(function(player)
		if NarrativeInteractionSystem.hasCollected(player, 'WF_01') or treeHollow:GetAttribute('Illuminated') then
			return
		end
		if not NarrativeInteractionSystem.hasItem(player, 'LightSeed') then
			Remotes.ShowNarrative:FireClient(player, missingHint.title, missingHint.hint, '')
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

-- ════════════════════════════════════════════════════════════
-- WF-02: 足迹的终点（追踪粉尘 + 足迹链终点）
-- ════════════════════════════════════════════════════════════

function NarrativeInteractionSystem.createWF_02(folder: Folder)
	local wfFolder = Instance.new('Folder')
	wfFolder.Name = 'WF_02_TrackEnd'
	wfFolder.Parent = folder

	local dustDef = Content.TRIGGER_ITEMS.TrackingDust

	-- 追踪粉尘（挂在树枝上）
	local dust = Instance.new('Part')
	dust.Name = 'TrackingDust'
	dust.Size = Vector3.new(0.3, 0.5, 0.3)
	dust.CFrame = CFrame.new(28, 14, 90)
	dust.Color = dustDef.color
	dust.Material = dustDef.material
	dust.CanCollide = false
	dust.Anchored = true
	dust.Parent = wfFolder

	local dustPrompt = createPrompt(dust, 'WF_02_PickupDust')
	dustPrompt.Triggered:Connect(function(player)
		if NarrativeInteractionSystem.hasItem(player, 'TrackingDust') then return end
		NarrativeInteractionSystem.giveItem(player, 'TrackingDust')
	end)

	-- 足迹终点（凹陷地面）
	local trackEnd = Instance.new('Part')
	trackEnd.Name = 'TrackEnd'
	trackEnd.Size = Vector3.new(1.5, 0.2, 2)
	trackEnd.CFrame = CFrame.new(31, 0.2, 97)
	trackEnd.Color = Color3.fromRGB(70, 70, 75)
	trackEnd.Material = Enum.Material.Slate
	trackEnd.CanCollide = false
	trackEnd.Anchored = true
	trackEnd.Transparency = 0.3
	trackEnd.Parent = wfFolder

	local trackPrompt = createPrompt(trackEnd, 'WF_02_Investigate')
	local missingHint = Content.MISSING_ITEM_HINTS.WF_02_TrackMysterious

	trackPrompt.Triggered:Connect(function(player)
		if NarrativeInteractionSystem.hasCollected(player, 'WF_02') then return end
		if not NarrativeInteractionSystem.hasItem(player, 'TrackingDust') then
			Remotes.ShowNarrative:FireClient(player, missingHint.title, missingHint.hint, '')
			return
		end
		NarrativeInteractionSystem.awardFragment(player, 'WF_02')
	end)
end

-- ════════════════════════════════════════════════════════════
-- WF-03: 不存在的果实（异常树枝直接交互）
-- ════════════════════════════════════════════════════════════

function NarrativeInteractionSystem.createWF_03(folder: Folder)
	local wfFolder = Instance.new('Folder')
	wfFolder.Name = 'WF_03_NonexistentFruit'
	wfFolder.Parent = folder

	-- 异常树枝
	local branchPart = Instance.new('Part')
	branchPart.Name = 'AnomalousBranch'
	branchPart.Size = Vector3.new(1, 2, 1)
	branchPart.CFrame = CFrame.new(35, 15, 110)
	branchPart.Color = Color3.fromRGB(140, 100, 160) -- 偏紫色调
	branchPart.Material = Enum.Material.Wood
	branchPart.CanCollide = false
	branchPart.Anchored = true
	branchPart.Transparency = 0.3
	branchPart.Parent = wfFolder

	local branchPrompt = createPrompt(branchPart, 'WF_03_TouchBranch')
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

-- ════════════════════════════════════════════════════════════
-- CR-01: 矿物的脉搏（共振晶片 + 发光矿物）
-- ════════════════════════════════════════════════════════════

function NarrativeInteractionSystem.createCR_01(folder: Folder)
	local crFolder = Instance.new('Folder')
	crFolder.Name = 'CR_01_MineralPulse'
	crFolder.Parent = folder

	local shardDef = Content.TRIGGER_ITEMS.ResonanceShard

	-- 共振晶片（嵌在特殊深橙色矿物中）
	local shard = Instance.new('Part')
	shard.Name = 'ResonanceShard'
	shard.Size = Vector3.new(0.4, 0.15, 0.4)
	shard.CFrame = CFrame.new(-6, 6.3, 175)
	shard.Color = shardDef.color
	shard.Material = shardDef.material
	shard.CanCollide = false
	shard.Anchored = true
	shard.Parent = crFolder

	local shardPrompt = createPrompt(shard, 'CR_01_PickupShard')
	shardPrompt.Triggered:Connect(function(player)
		if NarrativeInteractionSystem.hasItem(player, 'ResonanceShard') then return end
		NarrativeInteractionSystem.giveItem(player, 'ResonanceShard')
	end)

	-- 目标矿物
	local targetMineral = Instance.new('Part')
	targetMineral.Name = 'TargetMineral'
	targetMineral.Size = Vector3.new(1.8, 1.8, 1.8)
	targetMineral.CFrame = CFrame.new(8, 4.8, 165)
	targetMineral.Color = Color3.fromRGB(200, 150, 100)
	targetMineral.Material = Enum.Material.Neon
	targetMineral.Shape = Enum.PartType.Ball
	targetMineral.CanCollide = false
	targetMineral.Anchored = true
	targetMineral.Parent = crFolder

	local mineralPrompt = createPrompt(targetMineral, 'CR_01_ReadMineral')
	local missingHint = Content.MISSING_ITEM_HINTS.CR_01_MineralGlowing

	mineralPrompt.Triggered:Connect(function(player)
		if NarrativeInteractionSystem.hasCollected(player, 'CR_01') or targetMineral:GetAttribute('Read') then
			return
		end
		if not NarrativeInteractionSystem.hasItem(player, 'ResonanceShard') then
			Remotes.ShowNarrative:FireClient(player, missingHint.title, missingHint.hint, '')
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

-- ════════════════════════════════════════════════════════════
-- CR-02: 机关的沉默（修复齿轮 + 古代机关）
-- ════════════════════════════════════════════════════════════

function NarrativeInteractionSystem.createCR_02(folder: Folder)
	local crFolder = Instance.new('Folder')
	crFolder.Name = 'CR_02_MechanismSilence'
	crFolder.Parent = folder

	local gearDef = Content.TRIGGER_ITEMS.RepairGear

	-- 修复齿轮（宝藏箱旁）
	local gear = Instance.new('Part')
	gear.Name = 'RepairGear'
	gear.Size = Vector3.new(0.5, 0.25, 0.5)
	gear.CFrame = CFrame.new(2.5, 2, 165)
	gear.Color = gearDef.color
	gear.Material = gearDef.material
	gear.CanCollide = false
	gear.Anchored = true
	gear.Parent = crFolder

	local gearPrompt = createPrompt(gear, 'CR_02_PickupGear')
	gearPrompt.Triggered:Connect(function(player)
		if NarrativeInteractionSystem.hasItem(player, 'RepairGear') then return end
		NarrativeInteractionSystem.giveItem(player, 'RepairGear')
	end)

	-- 目标古代机关
	local mechPart = Instance.new('Part')
	mechPart.Name = 'MechanismTarget'
	mechPart.Size = Vector3.new(7, 3.5, 7)
	mechPart.CFrame = CFrame.new(0, 3, 180)
	mechPart.Color = Color3.fromRGB(125, 130, 135)
	mechPart.Material = Enum.Material.Metal
	mechPart.CanCollide = false
	mechPart.Anchored = true
	mechPart.Transparency = 0.3
	mechPart.Parent = crFolder

	local mechPrompt = createPrompt(mechPart, 'CR_02_InstallGear')
	local missingHint = Content.MISSING_ITEM_HINTS.CR_02_MechanismMissing

	mechPrompt.Triggered:Connect(function(player)
		if NarrativeInteractionSystem.hasCollected(player, 'CR_02') or mechPart:GetAttribute('Activated') then
			return
		end
		if not NarrativeInteractionSystem.hasItem(player, 'RepairGear') then
			Remotes.ShowNarrative:FireClient(player, missingHint.title, missingHint.hint, '')
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

-- ════════════════════════════════════════════════════════════
-- CR-03: 深渊的低语（静默耳坠 — 拾取即触发碎片效果）
-- ════════════════════════════════════════════════════════════

function NarrativeInteractionSystem.createCR_03(folder: Folder)
	local crFolder = Instance.new('Folder')
	crFolder.Name = 'CR_03_AbyssWhisper'
	crFolder.Parent = folder

	local earringDef = Content.TRIGGER_ITEMS.SilentEarring

	-- 静默耳坠（裂缝边缘）
	local earring = Instance.new('Part')
	earring.Name = 'SilentEarring'
	earring.Size = Vector3.new(0.2, 0.4, 0.1)
	earring.CFrame = CFrame.new(-1, 0.2, 170)
	earring.Color = earringDef.color
	earring.Material = earringDef.material
	earring.CanCollide = false
	earring.Anchored = true
	earring.Parent = crFolder

	local earringPrompt = createPrompt(earring, 'CR_03_PickupEarring')
	earringPrompt.Triggered:Connect(function(player)
		if NarrativeInteractionSystem.hasItem(player, 'SilentEarring') then return end
		-- 先给物品标记
		ensurePlayerData(player)
		playerItems[player.UserId]['SilentEarring'] = true

		-- 静默耳坠拾取后立即触发碎片（特殊体验：无普通获得提示，被叙事打断）
		NarrativeInteractionSystem.awardFragment(player, 'CR_03')
	end)
end

-- ════════════════════════════════════════════════════════════
-- CR-04: 最后的警告（入口凝视 — 渐进显现）
-- ════════════════════════════════════════════════════════════

function NarrativeInteractionSystem.createCR_04(folder: Folder)
	local crFolder = Instance.new('Folder')
	crFolder.Name = 'CR_04_FinalWarning'
	crFolder.Parent = folder

	-- 洞穴入口交互体
	local gatePart = Instance.new('Part')
	gatePart.Name = 'GateInsight'
	gatePart.Size = Vector3.new(24, 2, 6)
	gatePart.CFrame = CFrame.new(0, 19, 132)
	gatePart.Color = Color3.fromRGB(91, 95, 102)
	gatePart.Material = Enum.Material.Slate
	gatePart.CanCollide = false
	gatePart.Anchored = true
	gatePart.Transparency = 0.8
	gatePart.Parent = crFolder

	local gatePrompt = createPrompt(gatePart, 'CR_04_GazeEntrance', 12)

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

		-- 发放碎片（awardFragment 内部会自动调用 getCR04Text 处理渐进显现）
		NarrativeInteractionSystem.awardFragment(player, 'CR_04')
	end)
end

-- ════════════════════════════════════════════════════════════

return NarrativeInteractionSystem
