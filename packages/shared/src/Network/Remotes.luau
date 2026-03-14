local ReplicatedStorage = game:GetService('ReplicatedStorage')

local REMOTE_NAMES = {
    'LobbyAction',
    'LobbyState',
    'PrivateState',
    'RunAction',
    'RunSnapshot',
}

local Remotes = {}

local function ensureContainer()
    local container = ReplicatedStorage:FindFirstChild('Remotes')
    if container then
        return container
    end

    container = Instance.new('Folder')
    container.Name = 'Remotes'
    container.Parent = ReplicatedStorage
    return container
end

local function ensureRemote(container, name)
    local remote = container:FindFirstChild(name)
    if remote then
        return remote
    end

    remote = Instance.new('RemoteEvent')
    remote.Name = name
    remote.Parent = container
    return remote
end

function Remotes.ensure()
    local container = ensureContainer()
    local resolved = {}

    for _, name in ipairs(REMOTE_NAMES) do
        resolved[name] = ensureRemote(container, name)
    end

    return resolved
end

return Remotes
