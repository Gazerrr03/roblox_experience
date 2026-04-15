local Players = game:GetService('Players')

local RunOceanTrigger = {}
RunOceanTrigger.__index = RunOceanTrigger

local ENTRY_COOLDOWN_SECONDS = 0.75

local function findPlayerFromHit(hit)
    if hit == nil then
        return nil
    end

    local character = hit:FindFirstAncestorOfClass('Model')
    if character == nil then
        return nil
    end

    local humanoid = character:FindFirstChildOfClass('Humanoid')
    if humanoid == nil then
        return nil
    end

    return Players:GetPlayerFromCharacter(character)
end

function RunOceanTrigger.new(part)
    return setmetatable({
        Part = part,
        LastEnteredAtByUserId = {},
    }, RunOceanTrigger)
end

function RunOceanTrigger:bind(callback)
    return self.Part.Touched:Connect(function(hit)
        local player = findPlayerFromHit(hit)
        if player == nil then
            return
        end

        local now = os.clock()
        local lastEnteredAt = self.LastEnteredAtByUserId[player.UserId]
        if lastEnteredAt ~= nil and now - lastEnteredAt < ENTRY_COOLDOWN_SECONDS then
            return
        end

        self.LastEnteredAtByUserId[player.UserId] = now
        callback(player, self)
    end)
end

return RunOceanTrigger
