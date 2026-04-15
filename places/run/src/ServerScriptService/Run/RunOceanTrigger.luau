local Players = game:GetService('Players')

local RunOceanTrigger = {}
RunOceanTrigger.__index = RunOceanTrigger

local OCEAN_ENTRY_COOLDOWN_SECONDS = 0.75

local OceanState = {
    None = 'None',
    Touching = 'Touching',
    Immersed = 'Immersed',
}

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

-- Returns the state transition for a player: { state, isNewState }
function RunOceanTrigger:bind(callback)
    return self.Part.Touched:Connect(function(hit)
        local player = findPlayerFromHit(hit)
        if player == nil then
            return
        end

        local now = os.clock()
        local lastEnteredAt = self.LastEnteredAtByUserId[player.UserId]
        if lastEnteredAt ~= nil and now - lastEnteredAt < OCEAN_ENTRY_COOLDOWN_SECONDS then
            return
        end

        self.LastEnteredAtByUserId[player.UserId] = now
        callback(player, OceanState.Touching)
    end)
end

RunOceanTrigger.OceanState = OceanState

return RunOceanTrigger
