local SessionStateMachine = require(script.Parent.SessionStateMachine)

local MazeRunTracker = {}
MazeRunTracker.__index = MazeRunTracker

local function cloneSummary(summary)
    return {
        UserId = summary.UserId,
        Name = summary.Name,
        ReturnReason = summary.ReturnReason,
        Value = summary.Value or 0,
        ItemCount = summary.ItemCount or 0,
        Weight = summary.Weight or 0,
        WasExtracted = summary.WasExtracted == true,
        WasSettled = summary.WasSettled == true,
    }
end

function MazeRunTracker.new()
    return setmetatable({
        StateMachine = SessionStateMachine.new('Camp'),
        ActivePlayersByUserId = {},
        ReturnedSummaries = {},
        IsCompleted = false,
    }, MazeRunTracker)
end

function MazeRunTracker:addPlayer(playerInfo)
    if self.IsCompleted then
        return false, 'Completed'
    end

    self.ActivePlayersByUserId[playerInfo.UserId] = {
        UserId = playerInfo.UserId,
        Name = playerInfo.Name,
    }

    return true
end

function MazeRunTracker:removePlayer(userId)
    self.ActivePlayersByUserId[userId] = nil
end

function MazeRunTracker:isPlayerActive(userId)
    return self.ActivePlayersByUserId[userId] ~= nil
end

function MazeRunTracker:getActiveCount()
    local count = 0
    for _ in pairs(self.ActivePlayersByUserId) do
        count += 1
    end

    return count
end

function MazeRunTracker:getState()
    return self.StateMachine.Current
end

function MazeRunTracker:getReturnedSummaries()
    local summaries = {}

    for index, summary in ipairs(self.ReturnedSummaries) do
        summaries[index] = cloneSummary(summary)
    end

    return summaries
end

function MazeRunTracker:beginExpedition()
    if self.StateMachine.Current ~= 'Camp' then
        return false, 'InvalidState'
    end

    self.StateMachine:transition('Expedition')
    return true
end

function MazeRunTracker:beginExtraction()
    if self.StateMachine.Current ~= 'Expedition' then
        return false, 'InvalidState'
    end

    self.StateMachine:transition('Extraction')
    return true
end

function MazeRunTracker:recordReturn(summary)
    if not self:isPlayerActive(summary.UserId) then
        return false, 'MissingActivePlayer'
    end

    self.ActivePlayersByUserId[summary.UserId] = nil
    table.insert(self.ReturnedSummaries, cloneSummary(summary))

    return true
end

function MazeRunTracker:completeExpedition()
    if self.StateMachine.Current ~= 'Expedition' then
        return false, 'InvalidState'
    end

    if self:getActiveCount() ~= 0 then
        return false, 'ActivePlayersRemaining'
    end

    self.StateMachine:transition('Settlement')
    self.IsCompleted = true

    return true
end

function MazeRunTracker:completeSettlement(summaries)
    if self.StateMachine.Current ~= 'Extraction' then
        return false, 'InvalidState'
    end

    for _, summary in ipairs(summaries) do
        if not self:isPlayerActive(summary.UserId) then
            return false, 'MissingActivePlayer'
        end
    end

    self.StateMachine:transition('Settlement')

    for _, summary in ipairs(summaries) do
        self:recordReturn(summary)
    end

    self.IsCompleted = true
    return true
end

return MazeRunTracker
