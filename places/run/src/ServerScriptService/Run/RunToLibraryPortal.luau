--!strict
-- ════════════════════════════════════════════════════════════
-- RunToLibraryPortal.luau — 荒野(Run) → 图书馆(Library) 传送模块
--
-- 职责：
--   1. 在 CR-04 洞穴入口处创建传送门交互体
--   2. 玩家收集满碎片后，入口从"凝视获得碎片"变为"进入图书馆"
--   3. 使用 TeleportService 将玩家传送到 Library Place
--
-- 依赖：
--   - SessionConfig.PlaceIds.Library（需要在 Roblox 后台创建 Place 并填入 ID）
--   - NarrativeInteractionSystem（判断玩家是否已收集全部碎片）
--
-- 版本: 1.0
-- 最后更新: 2026-04-14
-- ════════════════════════════════════════════════════════════

local ReplicatedStorage = game:GetService('ReplicatedStorage')
local TeleportService = game:GetService('TeleportService')

local Packages = ReplicatedStorage:WaitForChild('Packages')
local Shared = require(Packages:WaitForChild('Shared'))

local SessionConfig = Shared.Config.SessionConfig

local RunToLibraryPortal = {}

-- ════════════════════════════════════════════════════════════
-- 核心传送函数
-- ════════════════════════════════════════════════════════════

--- 将单个玩家传送到图书馆
--- @param player Player 要传送的玩家
--- @param teleportData table? 传递给图书馆的数据（如已收集的碎片列表、书页数等）
--- @return boolean success 是否成功发起传送
--- @return string? error 错误信息（失败时）
function RunToLibraryPortal.teleportPlayer(
    player: Player,
    teleportData: { [string]: any }?
): (boolean, string?)
    local libraryPlaceId = SessionConfig.PlaceIds.Library

    -- 检查 Library PlaceId 是否已配置
    if not libraryPlaceId or libraryPlaceId == 0 then
        return false,
            'Library PlaceId 未配置。请在 SessionConfig 中设置有效的 Library Place ID。'
    end

    -- 构建传送数据：携带玩家的荒野进度
    local data = teleportData or {}
    data.SourcePlace = 'Run'
    data.TransitionType = 'RunToLibrary'
    data.Timestamp = os.time()

    local success, err = pcall(function()
        TeleportService:TeleportAsync(libraryPlaceId, { player }, data)
    end)

    if not success then
        return false, '传送失败: ' .. tostring(err)
    end

    return true, nil
end

-- ════════════════════════════════════════════════════════════
-- 创建图书馆传送门（替代/增强 CR-04 入口）
--
-- 在 NarrativeInteractionSystem 初始化后调用，
-- 将 CR-04 的 gatePart 升级为可传送状态
-- ════════════════════════════════════════════════════════════

--- 在指定的 Part 上安装图书馆传送门
--- @param gatePart Part CR-04 的洞穴入口 Part（已有 Prompt）
--- @param checkAllCollected function? 回调函数：检查玩家是否已收集满全部碎片
--- @param onTeleportStart function? 传送开始时的回调（可用于播放过渡动画）
function RunToLibraryPortal.installPortal(
    gatePart: Part,
    checkAllCollected: ((player: Player) -> boolean)?,
    onTeleportStart: ((player: Player) -> ())?
)
    -- 给入口 Part 打标记：这是一个图书馆传送门
    gatePart:SetAttribute('IsLibraryPortal', true)

    -- 监听已有 Prompt 的 Triggered 事件
    -- 当玩家在已收集满碎片后再次触发时，执行传送
    local existingPrompt = gatePart:FindFirstChildWhichIsA('ProximityPrompt')
    if not existingPrompt then
        warn('[RunToLibraryPortal] 未找到已有的 ProximityPrompt')
        return
    end

    existingPrompt.Triggered:Connect(function(player)
        -- 如果提供了检查函数且未通过检查，不传送
        if checkAllCollected and not checkAllCollected(player) then
            return
        end

        -- 额外确认：确保玩家已经获得了 CR-04
        -- （防止未完成探索就尝试进入）
        local witnessed = gatePart:GetAttribute('Witnessed')
        if not witnessed then
            return
        end

        -- 执行传送前回调（如播放过渡动画、屏幕特效等）
        if onTeleportStart then
            onTeleportStart(player)
        end

        -- 延迟一小段时间让过渡动画播放
        task.delay(1.5, function()
            -- 收集传送数据
            local teleportData = {
                HasCompletedWilderness = true,
            }

            local ok, errMsg = RunToLibraryPortal.teleportPlayer(player, teleportData)
            if not ok then
                warn('[RunToLibraryPortal] ' .. errMsg)
                -- 可以在这里通知客户端显示错误提示
            end
        end)
    end)
end

return RunToLibraryPortal
