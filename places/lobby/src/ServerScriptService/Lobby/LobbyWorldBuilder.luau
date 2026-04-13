local Workspace = game:GetService('Workspace')

local LobbyWorldBuilder = {}

local STATIC_WORLD_ROOT_NAME = 'LobbyStaticWorld'
local DEFAULT_SPAWN_CFRAME = CFrame.new(0, 4, 0)

local function findNamedDescendant(root, name)
    for _, descendant in ipairs(root:GetDescendants()) do
        if descendant.Name == name then
            return descendant
        end
    end

    return nil
end

local function findPromptOnPart(root, partName)
    local part = findNamedDescendant(root, partName)
    if not part or not part:IsA('BasePart') then
        return nil
    end

    return part:FindFirstChildOfClass('ProximityPrompt')
end

local function requirePromptOnPart(root, partName)
    local prompt = findPromptOnPart(root, partName)
    if prompt ~= nil then
        return prompt
    end

    error(
        string.format(
            '%s is missing a ProximityPrompt on part "%s".',
            STATIC_WORLD_ROOT_NAME,
            partName
        ),
        0
    )
end

local function resolveMarkerCFrame(root, markerName, fallback)
    local marker = findNamedDescendant(root, markerName)
    if marker and marker:IsA('BasePart') then
        return marker.CFrame
    end

    return fallback
end

function LobbyWorldBuilder.build()
    local staticWorldRoot = Workspace:FindFirstChild(STATIC_WORLD_ROOT_NAME)
    if staticWorldRoot == nil then
        return nil
    end

    if not (staticWorldRoot:IsA('Folder') or staticWorldRoot:IsA('Model')) then
        error(string.format('%s must be a Folder or Model.', STATIC_WORLD_ROOT_NAME), 0)
    end

    return {
        Root = staticWorldRoot,
        SpawnCFrame = resolveMarkerCFrame(staticWorldRoot, 'SpawnMarker', DEFAULT_SPAWN_CFRAME),
        ReadyPrompt = requirePromptOnPart(staticWorldRoot, 'ReadyPrompt'),
        StartRunPrompt = requirePromptOnPart(staticWorldRoot, 'StartRunPrompt'),
    }
end

LobbyWorldBuilder.SpawnCFrame = DEFAULT_SPAWN_CFRAME

return LobbyWorldBuilder
