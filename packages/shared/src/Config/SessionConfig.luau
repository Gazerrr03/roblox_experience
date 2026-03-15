local ReplicatedStorage = game:GetService('ReplicatedStorage')

local DEFAULT_PLACE_IDS = {
    Lobby = 0,
    Maze = 0,
    Run = 0,
}

local PLACE_ID_KEYS = { 'Lobby', 'Maze', 'Run' }

local function coercePlaceId(value)
    local numericValue = value
    if type(value) == 'string' then
        numericValue = tonumber(value)
    end

    if type(numericValue) ~= 'number' or numericValue <= 0 then
        return nil
    end

    return math.floor(numericValue)
end

local function resolvePlaceIds()
    local resolved = table.clone(DEFAULT_PLACE_IDS)
    local candidates = { game, ReplicatedStorage }

    for _, key in ipairs(PLACE_ID_KEYS) do
        local attributeName = string.format('SessionPlaceId%s', key)
        for _, container in ipairs(candidates) do
            local placeId = coercePlaceId(container:GetAttribute(attributeName))
            if placeId then
                resolved[key] = placeId
                break
            end
        end
    end

    return resolved
end

local SessionConfig = {
    PlaceIds = resolvePlaceIds(),
    MinPlayers = 1,
    MaxPlayers = 4,
    DefaultSeed = 12345,
    DefaultQuota = 120,
    DefaultRunDurationSeconds = 180,
    SettlementDurationSeconds = 8,
    InventoryCapacity = 5,
    ProcGen = {
        MainPathRooms = 4,
        MaxBranches = 2,
        RoomSpacing = 40,
        RoomSize = Vector3.new(28, 16, 28),
    },
}

return SessionConfig
