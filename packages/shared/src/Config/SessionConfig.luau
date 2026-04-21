local ReplicatedStorage = game:GetService('ReplicatedStorage')

local DEFAULT_PLACE_IDS = {
    Lobby = 99207062749924,
    Maze = 114148445477110,
    Run = 137478567439901,
    Library = 0,
}
local DEFAULT_DEBUG_LOCAL_MAZE_HANDOFF = false

local PLACE_ID_KEYS = { 'Lobby', 'Maze', 'Run', 'Library' }

local function coercePlaceId(value)
    local numericValue = tonumber(value)

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

local function resolveBooleanAttribute(attributeName, defaultValue)
    local candidates = { game, ReplicatedStorage }

    for _, container in ipairs(candidates) do
        local value = container:GetAttribute(attributeName)
        if type(value) == 'boolean' then
            return value
        end
    end

    return defaultValue
end

local SessionConfig = {
    PlaceIds = resolvePlaceIds(),
    DebugLocalMazeHandoff = resolveBooleanAttribute(
        'SessionDebugLocalMazeHandoff',
        DEFAULT_DEBUG_LOCAL_MAZE_HANDOFF
    ),
    MinPlayers = 1,
    MaxPlayers = 4,
    DefaultSeed = 12345,
    DefaultQuota = 12,
    DefaultRunDurationSeconds = 15 * 60,
    SettlementDurationSeconds = 8,
    InventoryCapacity = 5,
    Mission = table.freeze({
        RoundCount = 5,
        TargetItemCount = 12,
    }),
    TOD = table.freeze({
        RoundMinutes = 15,
        StartHour = 7,
        EndHour = 22,
    }),
    ProcGen = {
        RoomCount = 20,
        ExitMin = 2,
        ExitMax = 4,
        MaxGenerationAttempts = 240,
        RoomSpacing = 40,
        RoomApothem = 20,
        RoomSize = Vector3.new(28, 16, 28),
        DoorLeafChance = 0.6,
    },
}

return SessionConfig
