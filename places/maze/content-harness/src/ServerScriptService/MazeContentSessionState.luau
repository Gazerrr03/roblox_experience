local MazeContentSessionState = {}
MazeContentSessionState.__index = MazeContentSessionState

local function cloneSummary(summary)
    return {
        UserId = summary.UserId,
        Name = summary.Name,
        ReturnReason = summary.ReturnReason,
        Value = summary.Value or 0,
        ItemCount = summary.ItemCount or 0,
        Weight = summary.Weight or 0,
        WasSettled = summary.WasSettled == true,
        CountedInSettlement = summary.CountedInSettlement ~= false,
        LootItemCount = summary.LootItemCount or summary.MissionCount or summary.ItemCount or 0,
        ClueCount = summary.ClueCount or 0,
        ToolCount = summary.ToolCount or 0,
        MissionCount = summary.MissionCount or summary.LootItemCount or summary.ItemCount or 0,
    }
end

local function cloneArray(list)
    return table.clone(list or {})
end

local function cloneDropNode(dropNode)
    local entries = {}
    for index, entry in ipairs(dropNode.Entries or {}) do
        entries[index] = table.clone(entry)
    end

    local position = dropNode.Position
    local clonedPosition
    if type(position) == 'table' then
        clonedPosition = table.clone(position)
    else
        clonedPosition = position
    end

    return {
        DropNodeId = dropNode.DropNodeId,
        Label = dropNode.Label,
        Position = clonedPosition,
        Entries = entries,
    }
end

local function clonePersistentWorldState(state)
    local dropNodes = {}
    for index, dropNode in ipairs(state.DropNodes or {}) do
        dropNodes[index] = cloneDropNode(dropNode)
    end

    return {
        CollectedLootRoomIds = cloneArray(state.CollectedLootRoomIds or {}),
        DropNodes = dropNodes,
    }
end

function MazeContentSessionState.new(seed)
    return setmetatable({
        Seed = seed,
        SessionId = 'local-content-harness',
        MazeAccessCode = 'local-content-harness',
        IsDirectBoot = true,
        CurrentRound = 1,
        MaxRounds = 1,
        Status = '本地直启：迷宫内容测试场已启动。开始探索、拿 loot、验证玩法。',
        Objective = '观察房间、躲开威胁、拿到战利品，然后活着走到返回点。',
        MazeStatus = 'active',
        SessionPhase = 'MazeActive',
        WorldBuildSource = 'ContentHarness',
        BankedItemCount = 0,
        TargetItemCount = 0,
        LoopState = 'Staging',
        ActivePlayersByUserId = {},
        ReturnedPlayerSummaries = {},
        PersistentWorldState = {
            CollectedLootRoomIds = {},
            DropNodes = {},
        },
    }, MazeContentSessionState)
end

function MazeContentSessionState:addPlayer(playerInfo)
    self.ActivePlayersByUserId[playerInfo.UserId] = {
        UserId = playerInfo.UserId,
        Name = playerInfo.Name,
    }
end

function MazeContentSessionState:removePlayer(userId)
    self.ActivePlayersByUserId[userId] = nil
end

function MazeContentSessionState:isPlayerActive(userId)
    return self.ActivePlayersByUserId[userId] ~= nil
end

function MazeContentSessionState:getActiveCount()
    local count = 0
    for _ in pairs(self.ActivePlayersByUserId) do
        count += 1
    end
    return count
end

function MazeContentSessionState:getReturnedSummaries()
    local summaries = {}
    for index, summary in ipairs(self.ReturnedPlayerSummaries) do
        summaries[index] = cloneSummary(summary)
    end
    return summaries
end

function MazeContentSessionState:recordReturn(summary)
    if not self:isPlayerActive(summary.UserId) then
        return false, 'MissingActivePlayer'
    end

    self.ActivePlayersByUserId[summary.UserId] = nil
    table.insert(self.ReturnedPlayerSummaries, cloneSummary(summary))
    return true
end

function MazeContentSessionState:beginExpedition()
    if self.LoopState ~= 'Staging' then
        return false, 'InvalidState'
    end

    self.LoopState = 'Expedition'
    self.MazeStatus = 'active'
    self.SessionPhase = 'MazeActive'
    return true
end

function MazeContentSessionState:completeExpedition()
    if self.LoopState ~= 'Expedition' then
        return false, 'InvalidState'
    end

    if self:getActiveCount() ~= 0 then
        return false, 'ActivePlayersRemaining'
    end

    self.LoopState = 'Completed'
    self.MazeStatus = 'completed'
    self.SessionPhase = 'RunIntermission'
    return true
end

function MazeContentSessionState:setStatus(status)
    self.Status = status
end

function MazeContentSessionState:setObjective(objective)
    self.Objective = objective
end

function MazeContentSessionState:addBankedItems(amount)
    if type(amount) == 'number' and amount > 0 then
        self.BankedItemCount += amount
    end
end

function MazeContentSessionState:getPersistentWorldState()
    return clonePersistentWorldState(self.PersistentWorldState)
end

function MazeContentSessionState:setPersistentWorldState(state)
    self.PersistentWorldState = clonePersistentWorldState(state)
end

function MazeContentSessionState:markLootCollected(roomId)
    local collectedLootRoomIds = self.PersistentWorldState.CollectedLootRoomIds

    for _, collectedRoomId in ipairs(collectedLootRoomIds) do
        if collectedRoomId == roomId then
            return
        end
    end

    table.insert(collectedLootRoomIds, roomId)
    table.sort(collectedLootRoomIds)
end

return MazeContentSessionState
