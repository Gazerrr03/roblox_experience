-- HostPolicy.luau
-- Deterministic host (party leader) assignment policy for a run session.
-- Rules:
--  1. First player to join becomes the initial host.
--  2. Host leaving → randomly reassign from remaining players.
--  3. Empty session → no host (nil).

local HostPolicy = {}

function HostPolicy.assignHost(players, currentHostUserId)
    if #players == 0 then
        return nil
    end

    -- If current host is still present, keep them
    if currentHostUserId ~= nil then
        for _, player in ipairs(players) do
            if player.UserId == currentHostUserId then
                return currentHostUserId
            end
        end
    end

    -- No valid host; pick deterministically by lowest UserId
    local candidate = players[1]
    for _, player in ipairs(players) do
        if player.UserId < candidate.UserId then
            candidate = player
        end
    end
    return candidate.UserId
end

function HostPolicy.isValidHost(hostUserId, players)
    if hostUserId == nil then
        return false
    end
    for _, player in ipairs(players) do
        if player.UserId == hostUserId then
            return true
        end
    end
    return false
end

return HostPolicy
