--!strict
--#region Types

export type InteractionPoint = {
    Name: string,
    Type: string,
    Description: string,
    Position: Vector3,
    Completed: { [number]: boolean }, -- 玩家完成状态，key = UserId
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

local ItemService = require(script.Parent.ItemService)

--#endregion

--#region Module

local NarrativeInteractionSystem = {}

-- 存储玩家的叙事状态，避免内存泄漏
local playerNarrativeStates = {}

-- 清理离开的玩家数据
Players.PlayerRemoving:Connect(function(player)
    playerNarrativeStates[player.UserId] = nil
end)

-- 交互点数据
NarrativeInteractionSystem.InteractionPoints = {}

-- 初始化交互点
function NarrativeInteractionSystem.initialize(outdoorFolder: Folder)
    local folder = Instance.new('Folder')
    folder.Name = 'InteractionPoints'
    folder.Parent = outdoorFolder

    -- 交互点 1：手电筒 - 废弃神庙区
    NarrativeInteractionSystem.createFlashlightInteraction(folder)

    -- 交互点 2：绳索 - 洞穴遗迹区
    NarrativeInteractionSystem.createRopeInteraction(folder)

    -- 交互点 3：撬棍 - 古代遗迹区
    NarrativeInteractionSystem.createCrowbarInteraction(folder)
end

-- ========================================
-- 交互点 1：手电筒
-- ========================================
function NarrativeInteractionSystem.createFlashlightInteraction(folder: Folder)
    local torchFolder = Instance.new('Folder')
    torchFolder.Name = 'FlashlightInteraction'
    torchFolder.Parent = folder

    -- 燃烧的火把
    local torch = Instance.new('Part')
    torch.Name = 'BurningTorch'
    torch.Size = Vector3.new(0.5, 3, 0.5)
    torch.CFrame = CFrame.new(-55, 2, 35) -- 废弃神庙区
    torch.Color = Color3.fromRGB(139, 90, 43)
    torch.Material = Enum.Material.Wood
    torch.CanCollide = true
    torch.Anchored = true
    torch.Parent = torchFolder

    -- 火把顶部（火焰）
    local fireTip = Instance.new('Part')
    fireTip.Name = 'FireTip'
    fireTip.Size = Vector3.new(0.3, 0.5, 0.3)
    fireTip.CFrame = torch.CFrame * CFrame.new(0, 1.75, 0)
    fireTip.Color = Color3.fromRGB(255, 200, 100)
    fireTip.Material = Enum.Material.Neon
    fireTip.Transparency = 0.3
    fireTip.CanCollide = false
    fireTip.Anchored = true
    fireTip.Parent = torch

    -- 火焰粒子特效
    local fireAttachment = Instance.new('Attachment')
    fireAttachment.Parent = fireTip

    local fireParticle = Instance.new('ParticleEmitter')
    fireParticle.Name = 'FireParticle'
    fireParticle.Rate = 50
    fireParticle.Lifetime = NumberRange.new(0.5, 1)
    fireParticle.Speed = NumberRange.new(2, 4)
    fireParticle.Size = NumberSequence.new(0.5, 0)
    fireParticle.Color =
        ColorSequence.new(Color3.fromRGB(255, 200, 100), Color3.fromRGB(255, 100, 50))
    fireParticle.Transparency = NumberSequence.new(0, 1)
    fireParticle.LightEmission = 1
    fireParticle.Parent = fireAttachment

    -- 火焰光照
    local fireLight = Instance.new('PointLight')
    fireLight.Name = 'FireLight'
    fireLight.Color = Color3.fromRGB(255, 200, 100)
    fireLight.Brightness = 2
    fireLight.Range = 15
    fireLight.Parent = fireTip

    -- 火把交互提示
    local torchPrompt = Instance.new('ProximityPrompt')
    torchPrompt.Name = 'TorchPrompt'
    torchPrompt.ActionText = '拾取'
    torchPrompt.ObjectText = '燃烧的火把'
    torchPrompt.MaxActivationDistance = 5
    torchPrompt.KeyboardKeyCode = Enum.KeyCode.E
    torchPrompt.HoldDuration = 0.5
    torchPrompt.Parent = torch

    torchPrompt.Triggered:Connect(function(player)
        if ItemService.hasItem(player, 'BurningTorch') then
            return -- 已经拾取过
        end

        -- 给予火把道具
        ItemService.giveItem(player, 'BurningTorch')

        -- 显示叙事文本
        Remotes.ShowNarrative:FireClient(
            player,
            '火把在燃烧中...',
            '它的光芒温暖而短暂',
            '用它点燃那些倒塌的灯塔吧'
        )

        -- 隐藏火把（拾取后）
        torch.Transparency = 1
        torch.CanCollide = false
        fireTip.Transparency = 1
        fireParticle.Enabled = false
        fireLight.Enabled = false
        torchPrompt.Enabled = false
    end)

    -- 三座倒塌的灯塔
    local lighthousePositions = {
        CFrame.new(-70, 6, 30) * CFrame.Angles(math.rad(25), 0, 0),
        CFrame.new(-75, 5, 25),
        CFrame.new(-80, 4, 35),
    }

    for i, pos in ipairs(lighthousePositions) do
        local lighthouse = Instance.new('Part')
        lighthouse.Name = 'Lighthouse' .. i
        lighthouse.Size = Vector3.new(6, 10, 6)
        lighthouse.CFrame = pos
        lighthouse.Color = Color3.fromRGB(110, 115, 120)
        lighthouse.Material = Enum.Material.Slate
        lighthouse.CanCollide = true
        lighthouse.Anchored = true
        lighthouse.Parent = torchFolder

        -- 灯塔顶部（灯室）
        local lantern = Instance.new('Part')
        lantern.Name = 'Lantern'
        lantern.Size = Vector3.new(3, 3, 3)
        lantern.CFrame = lighthouse.CFrame * CFrame.new(0, 6.5, 0)
        lantern.Color = Color3.fromRGB(100, 105, 110)
        lantern.Material = Enum.Material.Glass
        lantern.Transparency = 0.3
        lantern.CanCollide = false
        lantern.Anchored = true
        lantern.Parent = lighthouse

        -- 灯塔交互提示（用于点燃）
        local lighthousePrompt = Instance.new('ProximityPrompt')
        lighthousePrompt.Name = 'LighthousePrompt'
        lighthousePrompt.ActionText = '点燃'
        lighthousePrompt.ObjectText = '倒塌的灯塔'
        lighthousePrompt.MaxActivationDistance = 8
        lighthousePrompt.KeyboardKeyCode = Enum.KeyCode.E
        lighthousePrompt.HoldDuration = 0.5
        lighthousePrompt.Parent = lantern

        lighthousePrompt.Triggered:Connect(function(player)
            if not ItemService.hasItem(player, 'BurningTorch') then
                Remotes.ShowNarrative:FireClient(
                    player,
                    '灯塔曾是荒野的指引',
                    '现在只剩下残垣断壁',
                    '等待光明的重现'
                )
                return
            end

            -- 检查是否已经点燃
            if lantern:GetAttribute('Lit') then
                return
            end

            -- 点燃灯塔
            lantern:SetAttribute('Lit', true)

            -- 添加光照
            local lanternLight = Instance.new('PointLight')
            lanternLight.Name = 'LanternLight'
            lanternLight.Color = Color3.fromRGB(255, 230, 150)
            lanternLight.Brightness = 3
            lanternLight.Range = 20
            lanternLight.Parent = lantern

            -- 添加粒子特效
            local lanternAttachment = Instance.new('Attachment')
            lanternAttachment.Parent = lantern

            local lanternParticle = Instance.new('ParticleEmitter')
            lanternParticle.Name = 'LightParticle'
            lanternParticle.Rate = 30
            lanternParticle.Lifetime = NumberRange.new(1, 2)
            lanternParticle.Speed = NumberRange.new(1, 2)
            lanternParticle.Size = NumberSequence.new(0.8, 0)
            lanternParticle.Color =
                ColorSequence.new(Color3.fromRGB(255, 230, 150), Color3.fromRGB(255, 200, 100))
            lanternParticle.Transparency = NumberSequence.new(0, 0.5)
            lanternParticle.LightEmission = 0.5
            lanternParticle.Parent = lanternAttachment

            -- 检查是否三座都已点燃
            local litCount = 0
            for _, sibling in ipairs(torchFolder:GetChildren()) do
                if sibling.Name:sub(1, 10) == 'Lighthouse' then
                    local siblingLantern = sibling:FindFirstChild('Lantern')
                    if siblingLantern and siblingLantern:GetAttribute('Lit') then
                        litCount = litCount + 1
                    end
                end
            end

            if litCount >= 3 then
                -- 给予手电筒
                if not ItemService.hasItem(player, 'Flashlight') then
                    ItemService.giveItem(player, 'Flashlight')
                    Remotes.ShowNarrative:FireClient(
                        player,
                        '三座灯塔都已点燃',
                        '光芒照亮了荒野',
                        '你获得了手电筒！'
                    )
                end
            end
        end)
    end
end

-- ========================================
-- 交互点 2：绳索
-- ========================================
function NarrativeInteractionSystem.createRopeInteraction(folder: Folder)
    local ropeFolder = Instance.new('Folder')
    ropeFolder.Name = 'RopeInteraction'
    ropeFolder.Parent = folder

    -- 三段废弃的绳子
    local ropePositions = {
        Vector3.new(-5, 1, 165),
        Vector3.new(5, 1.5, 170),
        Vector3.new(0, 2, 175),
    }

    for i, pos in ipairs(ropePositions) do
        local rope = Instance.new('Part')
        rope.Name = 'RopeSegment' .. i
        rope.Size = Vector3.new(0.3, 2, 0.3)
        rope.CFrame = CFrame.new(pos)
        rope.Color = Color3.fromRGB(101, 67, 33)
        rope.Material = Enum.Material.Fabric
        rope.CanCollide = true
        rope.Anchored = true
        rope.Parent = ropeFolder

        -- 绳子交互提示
        local ropePrompt = Instance.new('ProximityPrompt')
        ropePrompt.Name = 'RopePrompt'
        ropePrompt.ActionText = '拾取'
        ropePrompt.ObjectText = '废弃的绳子'
        ropePrompt.MaxActivationDistance = 5
        ropePrompt.KeyboardKeyCode = Enum.KeyCode.E
        ropePrompt.HoldDuration = 0.2
        ropePrompt.Parent = rope

        ropePrompt.Triggered:Connect(function(player)
            if rope:GetAttribute('Collected') then
                return -- 已经拾取过
            end

            -- 标记为已拾取
            rope:SetAttribute('Collected', true)
            rope.Transparency = 1
            rope.CanCollide = false
            ropePrompt.Enabled = false

            -- 检查是否是第一段
            local collectedCount = 0
            for _, sibling in ipairs(ropeFolder:GetChildren()) do
                if sibling.Name:sub(1, 12) == 'RopeSegment' then
                    if sibling:GetAttribute('Collected') then
                        collectedCount = collectedCount + 1
                    end
                end
            end

            -- 第一段触发叙事
            if collectedCount == 1 then
                Remotes.ShowNarrative:FireClient(
                    player,
                    '历史的痕迹从未被抹去',
                    '可历史又从哪里来呢？',
                    '继续寻找其他段落的绳子...'
                )
            end

            -- 三段都拾取后，给予全新绳索
            if collectedCount >= 3 then
                if not ItemService.hasItem(player, 'Rope') then
                    ItemService.giveItem(player, 'Rope')
                    Remotes.ShowNarrative:FireClient(
                        player,
                        '三段绳子都已收集',
                        '你将它们编织成了一根完整的绳索',
                        '你获得了绳索！'
                    )
                end
            end
        end)
    end
end

-- ========================================
-- 交互点 3：撬棍
-- ========================================
function NarrativeInteractionSystem.createCrowbarInteraction(folder: Folder)
    local crowbarFolder = Instance.new('Folder')
    crowbarFolder.Name = 'CrowbarInteraction'
    crowbarFolder.Parent = folder

    -- 废弃的箱子
    local chest = Instance.new('Part')
    chest.Name = 'AbandonedChest'
    chest.Size = Vector3.new(5, 4, 3)
    chest.CFrame = CFrame.new(65, 2, 55) -- 古代遗迹区
    chest.Color = Color3.fromRGB(101, 67, 33)
    chest.Material = Enum.Material.Wood
    chest.CanCollide = true
    chest.Anchored = true
    chest.Parent = crowbarFolder

    -- 箱子盖
    local lid = Instance.new('Part')
    lid.Name = 'ChestLid'
    lid.Size = Vector3.new(5.2, 0.3, 3.2)
    lid.CFrame = chest.CFrame * CFrame.new(0, 2.2, 0)
    lid.Color = Color3.fromRGB(91, 57, 23)
    lid.Material = Enum.Material.Wood
    lid.CanCollide = true
    lid.Anchored = true
    lid.Parent = chest

    -- 箱子金属锁
    local lock = Instance.new('Part')
    lock.Name = 'ChestLock'
    lock.Size = Vector3.new(0.5, 0.8, 0.5)
    lock.CFrame = chest.CFrame * CFrame.new(0, 2.5, 1.5)
    lock.Color = Color3.fromRGB(112, 112, 112)
    lock.Material = Enum.Material.Metal
    lock.CanCollide = false
    lock.Anchored = true
    lock.Parent = chest

    -- 箱子靠近触发叙事
    local chestPrompt = Instance.new('ProximityPrompt')
    chestPrompt.Name = 'ChestNarrativePrompt'
    chestPrompt.ActionText = ''
    chestPrompt.ObjectText = '废弃的箱子'
    chestPrompt.MaxActivationDistance = 10
    chestPrompt.KeyboardKeyCode = Enum.KeyCode.E
    chestPrompt.HoldDuration = 0
    chestPrompt.GamepadKeyCode = Enum.KeyCode.ButtonA
    chestPrompt.Parent = chest

    local narrativeKey = 'chest_narrative_shown'

    chestPrompt.Triggered:Connect(function(player)
        if
            playerNarrativeStates[player.UserId]
            and playerNarrativeStates[player.UserId][narrativeKey]
        then
            return
        end

        if not playerNarrativeStates[player.UserId] then
            playerNarrativeStates[player.UserId] = {}
        end
        playerNarrativeStates[player.UserId][narrativeKey] = true
        Remotes.ShowNarrative:FireClient(
            player,
            '覆灭的文明留下了历史残骸',
            '这个箱子看起来锁住了',
            '按 R 键尝试打开它'
        )

        -- 显示打开提示
        local openPrompt = Instance.new('ProximityPrompt')
        openPrompt.Name = 'OpenPrompt'
        openPrompt.ActionText = '打开'
        openPrompt.ObjectText = '废弃的箱子'
        openPrompt.MaxActivationDistance = 5
        openPrompt.KeyboardKeyCode = Enum.KeyCode.R
        openPrompt.HoldDuration = 0.5
        openPrompt.Parent = chest

        openPrompt.Triggered:Connect(function(_opener)
            if chest:GetAttribute('Opened') then
                return
            end

            -- 打开箱子
            chest:SetAttribute('Opened', true)
            openPrompt:Destroy()

            -- 箱子盖打开动画
            lid.CFrame = chest.CFrame * CFrame.Angles(math.rad(-45), 0, 0) * CFrame.new(0, 2.5, 0.5)

            -- 显示撬棍
            local crowbar = Instance.new('Part')
            crowbar.Name = 'Crowbar'
            crowbar.Size = Vector3.new(0.3, 4, 0.3)
            crowbar.CFrame = chest.CFrame * CFrame.new(0, 1.5, 0)
            crowbar.Color = Color3.fromRGB(120, 120, 120)
            crowbar.Material = Enum.Material.Metal
            crowbar.CanCollide = true
            crowbar.Anchored = true
            crowbar.Parent = chest

            -- 撬棍拾取提示
            local crowbarPrompt = Instance.new('ProximityPrompt')
            crowbarPrompt.Name = 'CrowbarPrompt'
            crowbarPrompt.ActionText = '拾取'
            crowbarPrompt.ObjectText = '金属撬棍'
            crowbarPrompt.MaxActivationDistance = 5
            crowbarPrompt.KeyboardKeyCode = Enum.KeyCode.E
            crowbarPrompt.HoldDuration = 0.3
            crowbarPrompt.Parent = crowbar

            crowbarPrompt.Triggered:Connect(function(picker)
                if not ItemService.hasItem(picker, 'Crowbar') then
                    ItemService.giveItem(picker, 'Crowbar')
                    crowbar.Transparency = 1
                    crowbar.CanCollide = false
                    crowbarPrompt.Enabled = false
                    Remotes.ShowNarrative:FireClient(
                        picker,
                        '你捡起了撬棍',
                        '它可以用来撬开锁住的箱子',
                        '你获得了撬棍！'
                    )
                end
            end)
        end)
    end)
end

return NarrativeInteractionSystem
