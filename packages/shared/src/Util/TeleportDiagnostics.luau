local ReplicatedStorage = game:GetService('ReplicatedStorage')

local TeleportDiagnostics = {}

local function attributeNameFor(targetKey)
    if type(targetKey) ~= 'string' or targetKey == '' then
        return nil
    end

    return string.format('SessionPlaceId%s', targetKey)
end

function TeleportDiagnostics.captureSnapshot(params)
    local targetKey = params and params.TargetKey or nil
    local targetPlaceId = params and params.TargetPlaceId or nil
    local targetAttributeName = attributeNameFor(targetKey)

    return {
        CurrentPlaceId = game.PlaceId,
        GameId = game.GameId,
        TargetKey = targetKey,
        TargetPlaceId = targetPlaceId,
        TargetAttributeName = targetAttributeName,
        GameAttributeValue = targetAttributeName and game:GetAttribute(targetAttributeName) or nil,
        ReplicatedStorageAttributeValue = targetAttributeName and ReplicatedStorage:GetAttribute(
            targetAttributeName
        ) or nil,
    }
end

local function appendDetail(details, key, value)
    table.insert(details, string.format('%s=%s', key, tostring(value)))
end

local function appendForbiddenHint(details, snapshot)
    local currentPlaceId = snapshot and snapshot.CurrentPlaceId or nil
    local targetPlaceId = snapshot and snapshot.TargetPlaceId or nil

    if targetPlaceId == currentPlaceId then
        table.insert(
            details,
            'hint=ReserveServer on the current place is forbidden; check experience teleport permissions and published place ownership.'
        )
        return
    end

    table.insert(
        details,
        'hint=check that the target place belongs to this experience and that reserved-server teleports are allowed.'
    )
end

function TeleportDiagnostics.formatFailure(step, message, snapshot)
    local details = {}
    local text = tostring(message)

    if snapshot then
        appendDetail(details, 'currentPlaceId', snapshot.CurrentPlaceId)
        appendDetail(details, 'gameId', snapshot.GameId)
        appendDetail(details, 'targetPlaceId', snapshot.TargetPlaceId)

        if snapshot.TargetKey then
            appendDetail(details, 'targetKey', snapshot.TargetKey)
        end

        if snapshot.TargetAttributeName then
            appendDetail(
                details,
                string.format('game.%s', snapshot.TargetAttributeName),
                snapshot.GameAttributeValue
            )
            appendDetail(
                details,
                string.format('ReplicatedStorage.%s', snapshot.TargetAttributeName),
                snapshot.ReplicatedStorageAttributeValue
            )
        end
    end

    if string.find(text, 'HTTP 403', 1, true) then
        appendForbiddenHint(details, snapshot)
    end

    if #details == 0 then
        return string.format('%s failed: %s', step, text)
    end

    return string.format('%s failed: %s [%s]', step, text, table.concat(details, ', '))
end

return TeleportDiagnostics
