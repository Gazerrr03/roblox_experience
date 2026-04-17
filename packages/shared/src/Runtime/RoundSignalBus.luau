local MessagingService = game:GetService('MessagingService')

local RoundSignalBus = {}
RoundSignalBus.__index = RoundSignalBus

RoundSignalBus.MessageKind = table.freeze({
    RoundClosure = 'RoundClosure',
    MazePresence = 'MazePresence',
})

local DEFAULT_TOPIC_PREFIX = 'roblox-experience-round-v1'

local function resolveScopeKey(session)
    if type(session) ~= 'table' then
        return nil
    end

    if type(session.SignalScope) == 'string' and session.SignalScope ~= '' then
        return session.SignalScope
    end

    if type(session.SessionId) == 'string' and session.SessionId ~= '' then
        return session.SessionId
    end

    return nil
end

function RoundSignalBus.new(options)
    local resolved = options or {}

    return setmetatable({
        MessagingService = resolved.MessagingService or MessagingService,
        TopicPrefix = resolved.TopicPrefix or DEFAULT_TOPIC_PREFIX,
        Warn = resolved.Warn or warn,
    }, RoundSignalBus)
end

function RoundSignalBus:_resolveTopic(session)
    local scopeKey = resolveScopeKey(session)
    if scopeKey == nil then
        return nil
    end

    return string.format('%s:%s', self.TopicPrefix, scopeKey)
end

function RoundSignalBus:publish(session, payload)
    local topic = self:_resolveTopic(session)
    if topic == nil or type(payload) ~= 'table' then
        return false, 'MissingSignalScope'
    end

    local ok, result = pcall(function()
        self.MessagingService:PublishAsync(topic, payload)
    end)

    if not ok then
        self.Warn(string.format('[RoundSignalBus] publish failed: %s', tostring(result)))
        return false, tostring(result)
    end

    return true
end

function RoundSignalBus:subscribe(session, handler)
    local topic = self:_resolveTopic(session)
    if topic == nil or type(handler) ~= 'function' then
        return nil, false, 'MissingSignalScope'
    end

    local ok, result = pcall(function()
        return self.MessagingService:SubscribeAsync(topic, function(message)
            local data = message and message.Data
            if type(data) == 'table' then
                handler(data)
            end
        end)
    end)

    if not ok then
        self.Warn(string.format('[RoundSignalBus] subscribe failed: %s', tostring(result)))
        return nil, false, tostring(result)
    end

    return result, true
end

return RoundSignalBus
