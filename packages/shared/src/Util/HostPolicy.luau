-- Deterministic host assignment for the run waiting phase.
-- Rules:
--  1. The first waiting player becomes host.
--  2. If the host leaves, promote the next waiting player still present.
--  3. An empty waiting roster has no host.

local HostPolicy = {}

function HostPolicy.assignHost(waitingPlayerOrderUserIds, currentHostUserId)
    if #waitingPlayerOrderUserIds == 0 then
        return nil
    end

    if HostPolicy.isValidHost(currentHostUserId, waitingPlayerOrderUserIds) then
        return currentHostUserId
    end

    for _, userId in ipairs(waitingPlayerOrderUserIds) do
        if type(userId) == 'number' then
            return userId
        end
    end

    return nil
end

function HostPolicy.isValidHost(hostUserId, waitingPlayerOrderUserIds)
    if hostUserId == nil then
        return false
    end

    for _, userId in ipairs(waitingPlayerOrderUserIds) do
        if userId == hostUserId then
            return true
        end
    end

    return false
end

return HostPolicy
