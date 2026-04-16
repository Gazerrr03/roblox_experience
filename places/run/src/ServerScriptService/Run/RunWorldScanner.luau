-- RunWorldScanner.luau
-- 扫描 RunStaticWorld 下所有 SpawnPoint_* BasePart，提供 canTraverse raycast 验证
local Workspace = game:GetService('Workspace')

local RunStaticWorldContract = require(script.Parent.RunStaticWorldContract)

local RunWorldScanner = {}

local SPAWN_POINT_PREFIX = 'SpawnPoint_'

-- 扫描所有 SpawnPoint_* BasePart，返回位置数组
function RunWorldScanner.scanSpawnPoints()
    local staticWorldRoot = Workspace:FindFirstChild(RunStaticWorldContract.RootName)
    if not staticWorldRoot then
        return {}
    end

    local positions = {}
    for _, descendant in ipairs(staticWorldRoot:GetDescendants()) do
        if descendant:IsA('BasePart') and string.find(descendant.Name, SPAWN_POINT_PREFIX, 1, true) then
            table.insert(positions, descendant.Position)
        end
    end

    return positions
end

-- 从 RunScene.Collision 构建 RaycastParams（只 raycast 场景碰撞体）
local function buildCollisionRaycastParams(collisionScene, collisionShip)
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Include
    local instances = {}
    if collisionScene and collisionScene:IsA('BasePart') then
        table.insert(instances, collisionScene)
    elseif collisionScene then
        for _, child in ipairs(collisionScene:GetDescendants()) do
            if child:IsA('BasePart') then
                table.insert(instances, child)
            end
        end
    end
    if collisionShip and collisionShip:IsA('BasePart') then
        table.insert(instances, collisionShip)
    elseif collisionShip then
        for _, child in ipairs(collisionShip:GetDescendants()) do
            if child:IsA('BasePart') then
                table.insert(instances, child)
            end
        end
    end
    raycastParams.FilterDescendantsInstances = instances
    return raycastParams
end

-- 从 RunScene 获取碰撞体并构建 canTraverse(fromPosition, toPosition) 函数
function RunWorldScanner.buildCanTraverseFn(runScene)
    local collisionScene = runScene and runScene.Collision and runScene.Collision.Scene
    local collisionShip = runScene and runScene.Collision and runScene.Collision.Ship

    if not collisionScene and not collisionShip then
        -- 无碰撞体时直接返回可通行
        return function()
            return true
        end
    end

    local raycastParams = buildCollisionRaycastParams(collisionScene, collisionShip)

    return function(fromPosition, toPosition)
        local direction = toPosition - fromPosition
        local distance = direction.Magnitude
        if distance <= 1e-3 then
            return true
        end

        local normalizedDir = direction.Unit
        local rayResult = Workspace:Raycast(fromPosition, normalizedDir * distance, raycastParams)
        return rayResult == nil
    end
end

return RunWorldScanner
