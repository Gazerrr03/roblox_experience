local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Remotes = {}

Remotes.Scope = table.freeze({
    Lobby = 'Lobby',
    Run = 'Run',
    Maze = 'Maze',
})

local REMOTE_NAMES_BY_SCOPE = table.freeze({
    [Remotes.Scope.Lobby] = {
        'LobbyAction',
        'LobbyState',
    },
    [Remotes.Scope.Run] = {
        'RunAction',
        'RunState',
        'RunPrivateState',
    },
    [Remotes.Scope.Maze] = {
        'MazeAction',
        'MazeState',
        'MazePrivateState',
    },
})

local ALL_REMOTE_NAMES = {
    'LobbyAction',
    'LobbyState',
    'RunAction',
    'RunState',
    'RunPrivateState',
    'MazeAction',
    'MazeState',
    'MazePrivateState',
}

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

    for _, name in ipairs(ALL_REMOTE_NAMES) do
        resolved[name] = ensureRemote(container, name)
    end

    return resolved
end

function Remotes.ensureScope(scope)
    local remoteNames = REMOTE_NAMES_BY_SCOPE[scope]
    if remoteNames == nil then
        error(string.format('Unknown remote scope %q', tostring(scope)), 0)
    end

    local container = ensureContainer()
    local resolved = {}

    for _, name in ipairs(remoteNames) do
        resolved[name] = ensureRemote(container, name)
    end

    return resolved
end

return Remotes
