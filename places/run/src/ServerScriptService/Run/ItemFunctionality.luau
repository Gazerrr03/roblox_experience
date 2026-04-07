--!strict
--#region Services

local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local TweenService = game:GetService('TweenService')
local Debris = game:GetService('Debris')
local CollectionService = game:GetService('CollectionService')

--#endregion

--#region Requires

local Packages = ReplicatedStorage:WaitForChild('Packages')
local Shared = require(Packages:WaitForChild('Shared'))
local Remotes = Shared.Network.Remotes.waitForScope(Shared.Network.Remotes.Scope.Run)

local ItemService = require(script.Parent.ItemService)

--#endregion

--#region Module

local ItemFunctionality = {}

-- 玩家道具状态
ItemFunctionality.ActiveEffects = {}

-- ====================
-- 道具 1: 手电筒
-- ====================

-- 切换手电筒开关
function ItemFunctionality.toggleFlashlight(player: Player): boolean
    local itemData = ItemService.getItemData(player, 'Flashlight')
    if not itemData or not itemData.IsEquipped then
        return false
    end

    local character = player.Character
    if not character then
        return false
    end

    local head = character:FindFirstChild('Head')
    if not head then
        return false
    end

    -- 查找或创建手电筒光源
    local flashlightLight = head:FindFirstChild('FlashlightLight')
    local isNewLight = false

    if flashlightLight then
        flashlightLight.Enabled = not flashlightLight.Enabled
    else
        flashlightLight = Instance.new('SpotLight')
        flashlightLight.Name = 'FlashlightLight'
        flashlightLight.Color = Color3.fromRGB(255, 255, 240)
        flashlightLight.Brightness = 2
        flashlightLight.Range = 50
        flashlightLight.Angle = 45
        flashlightLight.Face = Enum.NormalId.Front
        flashlightLight.Parent = head
        isNewLight = true
    end

    if isNewLight then
        -- 刚创建时默认开启
        flashlightLight.Enabled = true
    end

    return flashlightLight.Enabled
end

-- ====================
-- 道具 2: 绳索
-- ====================

-- 攀爬高处
function ItemFunctionality.climbWithRope(player: Player, climbTarget: BasePart): boolean
    local itemData = ItemService.getItemData(player, 'Rope')
    if not itemData or not itemData.IsEquipped then
        return false
    end

    local character = player.Character
    if not character then
        return false
    end

    local humanoid = character:FindFirstChild('Humanoid')
    if not humanoid then
        return false
    end

    -- 攀爬动画效果
    humanoid:ChangeState(Enum.HumanoidStateType.Climbing)

    -- 使用 TweenService 实现平滑攀爬
    local targetPosition = climbTarget.Position + Vector3.new(0, 5, 0)
    local climbTween = TweenService:Create(
        character.HumanoidRootPart,
        TweenInfo.new(2, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut),
        {CFrame = CFrame.new(targetPosition)}
    )
    climbTween:Play()

    -- 2秒后恢复正常状态
    task.delay(2, function()
        humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
    end)

    return true
end

-- 跨越断层
function ItemFunctionality.crossWithRope(player: Player, crossTarget: CFrame): boolean
    local itemData = ItemService.getItemData(player, 'Rope')
    if not itemData or not itemData.IsEquipped then
        return false
    end

    local character = player.Character
    if not character then
        return false
    end

    -- 播放跨越动画
    local humanoid = character:FindFirstChild('Humanoid')
    if humanoid then
        humanoid.PlatformStand = true
    end

    -- 使用 Tween 跨越
    local crossTween = TweenService:Create(
        character.HumanoidRootPart,
        TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
        {CFrame = crossTarget}
    )
    crossTween:Play()

    -- 1.5秒后恢复正常
    task.delay(1.5, function()
        if humanoid then
            humanoid.PlatformStand = false
        end
    end)

    return true
end

-- 套住怪物
function ItemFunctionality.tetherMonster(player: Player, targetModel: Model): boolean
    local itemData = ItemService.getItemData(player, 'Rope')
    if not itemData or not itemData.IsEquipped then
        return false
    end

    local humanoid = targetModel:FindFirstChild('Humanoid')
    if not humanoid then
        return false
    end

    -- 创建绳索视觉效果
    local character = player.Character
    if not character then
        return false
    end

    local ropeVisual = Instance.new('Part')
    ropeVisual.Name = 'TetherRope'
    ropeVisual.Size = Vector3.new(0.1, 0.1, 1)
    ropeVisual.Color = Color3.fromRGB(139, 90, 43)
    ropeVisual.Material = Enum.Material.Fabric
    ropeVisual.Anchored = true
    ropeVisual.CanCollide = false
    ropeVisual.Parent = workspace -- 设置父级，使绳索可见

    -- 绳索两端的位置
    local startPos = character.HumanoidRootPart.Position
    local endPos = targetModel.HumanoidRootPart.Position

    -- 使用约束连接玩家和目标
    local ropeConstraint = Instance.new('RopeConstraint')
    ropeConstraint.Name = 'TetherConstraint'
    ropeConstraint.Visible = true
    ropeConstraint.Length = 0
    ropeConstraint.Restitution = 0
    ropeConstraint.Thickness = 0.1
    ropeConstraint.Color = Color3.fromRGB(139, 90, 43)

    local attachment1 = Instance.new('Attachment')
    attachment1.Parent = character.HumanoidRootPart

    local attachment2 = Instance.new('Attachment')
    attachment2.Parent = targetModel.HumanoidRootPart

    ropeConstraint.Attachment0 = attachment1
    ropeConstraint.Attachment1 = attachment2
    ropeConstraint.Parent = character.HumanoidRootPart

    -- 固定怪物 2 秒
    humanoid.PlatformStand = true
    humanoid.WalkSpeed = 0

    -- 2 秒后释放
    task.delay(2, function()
        humanoid.PlatformStand = false
        humanoid.WalkSpeed = 16 -- 恢复默认速度
        ropeConstraint:Destroy()
        attachment1:Destroy()
        attachment2:Destroy()
        ropeVisual:Destroy()
    end)

    return true
end

-- ====================
-- 道具 3: 撬棍
-- ====================

-- 撬开箱子/门
function ItemFunctionality.pryOpen(player: Player, targetPart: BasePart): boolean
    local itemData = ItemService.getItemData(player, 'Crowbar')
    if not itemData or not itemData.IsEquipped then
        return false
    end

    -- 检查目标是否已被撬开
    if targetPart:GetAttribute('PriedOpen') then
        return false
    end

    -- 撬棍动画
    local character = player.Character
    if not character then
        return false
    end

    -- 创建撬棍视觉提示
    local crowbarVisual = Instance.new('Part')
    crowbarVisual.Name = 'CrowbarAnimation'
    crowbarVisual.Size = Vector3.new(0.2, 4, 0.2)
    crowbarVisual.Color = Color3.fromRGB(120, 120, 120)
    crowbarVisual.Material = Enum.Material.Metal
    crowbarVisual.CanCollide = false
    crowbarVisual.Anchored = true

    local targetPosition = targetPart.Position + Vector3.new(0, 1, 0)
    crowbarVisual.CFrame = CFrame.new(targetPosition) * CFrame.Angles(math.rad(45), 0, 0)
    crowbarVisual.Parent = workspace

    -- 撬动动画
    local pryTween = TweenService:Create(
        crowbarVisual,
        TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.InOut),
        {CFrame = crowbarVisual.CFrame * CFrame.Angles(math.rad(-30), 0, 0)}
    )
    pryTween:Play()

    -- 撬开效果
    task.delay(0.5, function()
        -- 标记为已撬开
        targetPart:SetAttribute('PriedOpen', true)

        -- 移除目标(如果是锁)
        local lock = targetPart:FindFirstChild('Lock')
        if lock then
            lock:Destroy()
        end

        -- 或者移动目标(如果是门/盖)
        if targetPart.Name == 'ChestLid' then
            local openTween = TweenService:Create(
                targetPart,
                TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {CFrame = targetPart.CFrame * CFrame.Angles(math.rad(-45), 0, 0) * CFrame.new(0, 0.5, 0.5)}
            )
            openTween:Play()
        end

        -- 移除视觉提示
        crowbarVisual:Destroy()
    end)

    return true
end

-- ====================
-- 交互检测系统
-- ====================

-- 检测玩家周围的交互对象（优化版：使用标签系统）
function ItemFunctionality.detectInteractableObjects(player: Player, range: number): {BasePart}
    local interactables = {}
    local character = player.Character

    if not character or not character.HumanoidRootPart then
        return interactables
    end

    local playerPos = character.HumanoidRootPart.Position

    -- 使用CollectionService获取所有带有Interactable标签的对象，性能更好
    for _, object in ipairs(CollectionService:GetTagged('Interactable')) do
        if object:IsA('BasePart') then
            local distance = (object.Position - playerPos).Magnitude
            if distance <= range then
                table.insert(interactables, object)
            end
        end
    end

    return interactables
end

-- 注册可交互对象
function ItemFunctionality.registerInteractable(part: BasePart, interactionType: string, options: {[string]: any})
    -- 使用标签系统而不是属性，提升性能
    CollectionService:AddTag(part, 'Interactable')
    CollectionService:AddTag(part, interactionType)

    if options then
        for key, value in pairs(options) do
            part:SetAttribute(key, value)
        end
    end
end

-- ====================
-- 网络事件处理
-- ====================

-- 使用道具功能
Remotes.UseItemFunction.OnServerEvent:Connect(function(player: Player, itemName: string, target: any, actionType: string)
    local success = false

    if itemName == 'Flashlight' and actionType == 'toggle' then
        success = ItemFunctionality.toggleFlashlight(player)
    elseif itemName == 'Rope' then
        if actionType == 'climb' and target then
            success = ItemFunctionality.climbWithRope(player, target)
        elseif actionType == 'cross' and target then
            success = ItemFunctionality.crossWithRope(player, target)
        elseif actionType == 'tether' and target then
            success = ItemFunctionality.tetherMonster(player, target)
        end
    elseif itemName == 'Crowbar' and actionType == 'pry' and target then
        success = ItemFunctionality.pryOpen(player, target)
    end

    if success then
        print(player.Name .. " 使用了 " .. itemName .. " 功能: " .. actionType)
    else
        warn(player.Name .. " 使用 " .. itemName .. " 功能失败: " .. actionType)
    end
end)

-- 查询附近的可交互对象
Remotes.GetInteractables.OnServerInvoke = function(player: Player, range: number): {BasePart}
    return ItemFunctionality.detectInteractableObjects(player, range or 10)
end

return ItemFunctionality
