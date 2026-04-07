--!strict
--#region Services

local ReplicatedStorage = game:GetService('ReplicatedStorage')

--#endregion

--#region Requires

local Packages = ReplicatedStorage:WaitForChild('Packages')
local Shared = require(Packages:WaitForChild('Shared'))
local Remotes = Shared.Network.Remotes.waitForScope(Shared.Network.Remotes.Scope.Run)

local ItemFunctionality = require(script.Parent.ItemFunctionality)

--#endregion

--#region Module

local InteractableObjectsSetup = {}

-- 设置地图中的可交互对象
function InteractableObjectsSetup.setupInteractables(outdoorFolder: Folder)
    -- ====================
    -- 攀爬点 (绳索)
    -- ====================

    -- 洞穴遗迹区的攀爬墙
    local climbWall1 = outdoorFolder:FindFirstChild('CaveRuinsZone')
    if climbWall1 then
        for _, child in ipairs(climbWall1:GetDescendants()) do
            if child:IsA('Part') and (child.Name:find('Wall') or child.Name:find('Climb')) then
                ItemFunctionality.registerInteractable(child, 'Climbable', {
                    Height = 10,
                })
            end
        end
    end

    -- 古代遗迹区的高墙
    local climbWall2 = outdoorFolder:FindFirstChild('AncientRuinsZone')
    if climbWall2 then
        for _, child in ipairs(climbWall2:GetDescendants()) do
            if child:IsA('Part') and child.Name:find('Wall') then
                ItemFunctionality.registerInteractable(child, 'Climbable', {
                    Height = 8,
                })
            end
        end
    end

    -- ====================
    -- 跨越点 (绳索)
    -- ====================

    -- 洞穴入口的断层
    local gap1 = outdoorFolder:FindFirstChild('CaveRuinsZone')
    if gap1 then
        local gapMarker = gap1:FindFirstChild('GapMarker')
        if gapMarker and gapMarker:IsA('Part') then
            ItemFunctionality.registerInteractable(gapMarker, 'Crossable', {
                TargetCFrame = gapMarker.CFrame * CFrame.new(0, 0, 20), -- 跨越后的位置（相对于gapMarker）
            })
        end
    end

    -- ====================
    -- 可撬开的箱子/门 (撬棍)
    -- ====================

    -- 古代遗迹区的锁住箱子
    local ancientRuins = outdoorFolder:FindFirstChild('AncientRuinsZone')
    if ancientRuins then
        for _, child in ipairs(ancientRuins:GetDescendants()) do
            if child:IsA('Part') and (child.Name:find('Chest') or child.Name:find('Door')) then
                -- 检查是否已经有锁
                if child:FindFirstChild('Lock') == nil then
                    -- 添加锁部件
                    local lock = Instance.new('Part')
                    lock.Name = 'Lock'
                    lock.Size = Vector3.new(0.5, 0.5, 0.5)
                    lock.Color = Color3.fromRGB(112, 112, 112)
                    lock.Material = Enum.Material.Metal
                    lock.CanCollide = false
                    lock.Anchored = true
                    lock.Parent = child

                    -- 注册为可撬开
                    ItemFunctionality.registerInteractable(child, 'Pryable', {
                        RequiredItem = 'Crowbar',
                    })
                end
            end
        end
    end

    -- ====================
    -- 隐藏通道 (手电筒)
    -- ====================

    -- 洞穴内部的黑暗区域
    local cave = outdoorFolder:FindFirstChild('CaveZone')
    if cave then
        for _, child in ipairs(cave:GetDescendants()) do
            if child:IsA('Part') and (child.Name:find('Dark') or child.Name:find('Hidden')) then
                ItemFunctionality.registerInteractable(child, 'FlashlightRequired', {
                    DarknessLevel = 0.8,
                })
            end
        end
    end

    print("可交互对象设置完成")
end

return InteractableObjectsSetup
