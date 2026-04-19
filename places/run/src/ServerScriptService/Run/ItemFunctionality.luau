--!strict
--#region Services

local ReplicatedStorage = game:GetService('ReplicatedStorage')
local TweenService = game:GetService('TweenService')
local CollectionService = game:GetService('CollectionService')

--#endregion

--#region Requires

local Packages = ReplicatedStorage:WaitForChild('Packages')
local Shared = require(Packages:WaitForChild('Shared'))
local Remotes = Shared.Network.Remotes.waitForScope(Shared.Network.Remotes.Scope.Run)

local RunInventoryBridge = require(script.Parent.RunInventoryBridge)

--#endregion

--#region Module

local ItemFunctionality = {}

-- 玩家道具状态
ItemFunctionality.ActiveEffects = {}

local function heldMatchesToolCategory(player: Player, toolCategory: string): boolean
    local session = RunInventoryBridge.get()
    if not session or not session.IsLaunched then
        return false
    end

    local held = session.InventoryService:getSummary(player).HeldItem
    return held ~= nil and held.ToolCategory == toolCategory
end

-- ====================
-- 道具 1: 手电筒
-- ====================

-- 切换手电筒开关
function ItemFunctionality.toggleFlashlight(player: Player): boolean
    if not heldMatchesToolCategory(player, 'Flashlight') then
        return false
    end

    local enabled = Shared.Runtime.HeldFlashlightHeadlight.toggle(player)
    return if enabled == nil then false else enabled
end

-- ====================
-- 道具 2: 绳索
-- ====================

-- 攀爬高处
function ItemFunctionality.climbWithRope(player: Player, climbTarget: BasePart): boolean
    if not heldMatchesToolCategory(player, 'Rope') then
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

    -- 验证距离(防止远程交互攻击)
    local characterPosition = character.HumanoidRootPart.Position
    local distance = (climbTarget.Position - characterPosition).Magnitude
    local MAX_INTERACTION_DISTANCE = 15 -- 最大交互距离

    if distance > MAX_INTERACTION_DISTANCE then
        warn(player.Name .. ' 尝试从过远的距离使用绳索: ' .. tostring(distance))
        return false
    end

    -- 获取攀爬高度(使用交互对象的属性而非硬编码)
    local climbHeight = climbTarget:GetAttribute('Height') or 5

    -- 攀爬动画效果
    humanoid:ChangeState(Enum.HumanoidStateType.Climbing)

    -- 使用 TweenService 实现平滑攀爬,保留原始朝向
    local targetPosition = climbTarget.Position + Vector3.new(0, climbHeight, 0)
    local targetCFrame = CFrame.new(targetPosition, character.HumanoidRootPart.Position)
    local climbTween = TweenService:Create(
        character.HumanoidRootPart,
        TweenInfo.new(2, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut),
        { CFrame = targetCFrame }
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
    if not heldMatchesToolCategory(player, 'Rope') then
        return false
    end

    local character = player.Character
    if not character then
        return false
    end

    -- 验证距离(防止远程交互攻击)
    local characterPosition = character.HumanoidRootPart.Position
    local targetPosition = crossTarget.Position
    local distance = (targetPosition - characterPosition).Magnitude
    local MAX_INTERACTION_DISTANCE = 20 -- 跨越距离可以稍大一些

    if distance > MAX_INTERACTION_DISTANCE then
        warn(player.Name .. ' 尝试从过远的距离使用绳索跨越: ' .. tostring(distance))
        return false
    end

    -- 播放跨越动画
    local humanoid = character:FindFirstChild('Humanoid')
    if humanoid then
        humanoid.PlatformStand = true
    end

    -- 使用 Tween 跨越,保留原始朝向
    local currentLookVector = character.HumanoidRootPart.CFrame.LookVector
    local targetCFrame = CFrame.new(crossTarget.Position, crossTarget.Position + currentLookVector)
    local crossTween = TweenService:Create(
        character.HumanoidRootPart,
        TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
        { CFrame = targetCFrame }
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
    if not heldMatchesToolCategory(player, 'Rope') then
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

    -- 验证距离(防止远程交互攻击)
    local characterPosition = character.HumanoidRootPart.Position
    local targetPosition = targetModel.HumanoidRootPart.Position
    local distance = (targetPosition - characterPosition).Magnitude
    local MAX_INTERACTION_DISTANCE = 25 -- 套怪物的距离可以稍大一些

    if distance > MAX_INTERACTION_DISTANCE then
        warn(player.Name .. ' 尝试从过远的距离套住怪物: ' .. tostring(distance))
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
    local originalWalkSpeed = humanoid.WalkSpeed
    humanoid.PlatformStand = true
    humanoid.WalkSpeed = 0

    -- 2 秒后释放
    task.delay(2, function()
        humanoid.PlatformStand = false
        humanoid.WalkSpeed = originalWalkSpeed -- 恢复原始速度
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
    if not heldMatchesToolCategory(player, 'Crowbar') then
        return false
    end

    -- 验证距离(防止远程交互攻击)
    local character = player.Character
    if not character or not character.HumanoidRootPart then
        return false
    end

    local characterPosition = character.HumanoidRootPart.Position
    local targetPosition = targetPart.Position
    local distance = (targetPosition - characterPosition).Magnitude
    local MAX_INTERACTION_DISTANCE = 10 -- 撬开的距离需要比较近

    if distance > MAX_INTERACTION_DISTANCE then
        warn(player.Name .. ' 尝试从过远的距离撬开: ' .. tostring(distance))
        return false
    end

    -- 检查目标是否已被撬开
    if targetPart:GetAttribute('PriedOpen') then
        return false
    end

    -- 撬棍动画
    -- 创建撬棍视觉提示
    local crowbarVisual = Instance.new('Part')
    crowbarVisual.Name = 'CrowbarAnimation'
    crowbarVisual.Size = Vector3.new(0.2, 4, 0.2)
    crowbarVisual.Color = Color3.fromRGB(120, 120, 120)
    crowbarVisual.Material = Enum.Material.Metal
    crowbarVisual.CanCollide = false
    crowbarVisual.Anchored = true

    local pryTargetPosition = targetPart.Position + Vector3.new(0, 1, 0)
    crowbarVisual.CFrame = CFrame.new(pryTargetPosition) * CFrame.Angles(math.rad(45), 0, 0)
    crowbarVisual.Parent = workspace

    -- 撬动动画
    local pryTween = TweenService:Create(
        crowbarVisual,
        TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.InOut),
        { CFrame = crowbarVisual.CFrame * CFrame.Angles(math.rad(-30), 0, 0) }
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
                {
                    CFrame = targetPart.CFrame
                        * CFrame.Angles(math.rad(-45), 0, 0)
                        * CFrame.new(0, 0.5, 0.5),
                }
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
function ItemFunctionality.detectInteractableObjects(player: Player, range: number): { BasePart }
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
function ItemFunctionality.registerInteractable(
    part: BasePart,
    interactionType: string,
    options: { [string]: any }
)
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
Remotes.UseItemFunction.OnServerEvent:Connect(
    function(player: Player, itemName: string, target: any, actionType: string)
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
            print(player.Name .. ' 使用了 ' .. itemName .. ' 功能: ' .. actionType)
        else
            warn(player.Name .. ' 使用 ' .. itemName .. ' 功能失败: ' .. actionType)
        end
    end
)

-- 查询附近的可交互对象
Remotes.GetInteractables.OnServerInvoke = function(player: Player, range: number): { BasePart }
    return ItemFunctionality.detectInteractableObjects(player, range or 10)
end

return ItemFunctionality
