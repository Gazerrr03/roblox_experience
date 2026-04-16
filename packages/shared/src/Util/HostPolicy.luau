-- HostPolicy.luau
-- Deterministic host (party leader) assignment policy for a run session.
-- Rules:
--  1. First player to join becomes the initial host.
--  2. Host leaving → promote the next waiting player still present.
--  3. Empty session → no host (nil).

local HostPolicy = {}

function HostPolicy.assignHost(waitingPlayerOrderUserIds, currentHostUserId)
    if #waitingPlayerOrderUserIds == 0 then
        return nil
    end

    -- If current host is still present, keep them
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
