local FirstPersonController = {}

local TARGET_PLAYER_PROPERTIES = {
    CameraMode = Enum.CameraMode.LockFirstPerson,
    CameraMinZoomDistance = 0.5,
    CameraMaxZoomDistance = 0.5,
}

local OPTIONAL_PLAYER_PROPERTIES = {
    DevEnableMouseLock = false,
}

FirstPersonController.StarterPlayerProperties = {
    CameraMode = Enum.CameraMode.LockFirstPerson,
    CameraMinZoomDistance = 0.5,
    CameraMaxZoomDistance = 0.5,
    EnableMouseLockOption = false,
}

FirstPersonController.PlayerProperties = TARGET_PLAYER_PROPERTIES

local function applyProperties(target, properties)
    for propertyName, value in pairs(properties) do
        target[propertyName] = value
    end
end

local function applyOptionalProperties(target, properties)
    for propertyName, value in pairs(properties) do
        pcall(function()
            target[propertyName] = value
        end)
    end
end

function FirstPersonController.applyToPlayer(player)
    applyProperties(player, TARGET_PLAYER_PROPERTIES)
    applyOptionalProperties(player, OPTIONAL_PLAYER_PROPERTIES)
end

function FirstPersonController.start(player)
    local function reapply()
        FirstPersonController.applyToPlayer(player)
    end

    reapply()

    local connections = {
        player.CharacterAdded:Connect(reapply),
    }

    for propertyName, targetValue in pairs(TARGET_PLAYER_PROPERTIES) do
        table.insert(
            connections,
            player:GetPropertyChangedSignal(propertyName):Connect(function()
                if player[propertyName] ~= targetValue then
                    reapply()
                end
            end)
        )
    end

    local ok, mouseLockConnection = pcall(function()
        return player:GetPropertyChangedSignal('DevEnableMouseLock'):Connect(function()
            if player.DevEnableMouseLock ~= false then
                reapply()
            end
        end)
    end)

    if ok and mouseLockConnection ~= nil then
        table.insert(connections, mouseLockConnection)
    end

    return function()
        for _, connection in ipairs(connections) do
            connection:Disconnect()
        end
    end
end

return FirstPersonController
