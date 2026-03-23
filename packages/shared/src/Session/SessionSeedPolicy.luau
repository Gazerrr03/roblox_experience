local SessionSeedPolicy = {}

SessionSeedPolicy.SeedMin = 100000
SessionSeedPolicy.SeedMax = 999999
SessionSeedPolicy.MaxAttempts = 32

local function getRandomSource(randomSource)
    if randomSource ~= nil then
        return randomSource
    end

    return Random.new()
end

function SessionSeedPolicy.issueSessionSeed(randomSource, defaultSeed)
    local source = getRandomSource(randomSource)

    for _ = 1, SessionSeedPolicy.MaxAttempts do
        local seed = source:NextInteger(SessionSeedPolicy.SeedMin, SessionSeedPolicy.SeedMax)
        if type(defaultSeed) ~= 'number' or seed ~= defaultSeed then
            return seed
        end
    end

    error('Failed to issue a session seed distinct from the configured default seed.', 0)
end

function SessionSeedPolicy.ensureAuthoritativeSeed(params)
    local currentSeed = params.CurrentSeed
    if params.HasAuthoritativeSeed == true and type(currentSeed) == 'number' then
        return currentSeed, false
    end

    return SessionSeedPolicy.issueSessionSeed(params.RandomSource, params.DefaultSeed), true
end

return SessionSeedPolicy
