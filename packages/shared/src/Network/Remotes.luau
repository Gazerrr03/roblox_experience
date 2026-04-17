local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService('RunService')

local Remotes = {}

Remotes.Scope = table.freeze({
    Run = 'Run',
    Maze = 'Maze',
})

local REMOTE_NAMES_BY_SCOPE = table.freeze({
    [Remotes.Scope.Run] = table.freeze({
        'RunAction',
        'RunState',
        'RunPrivateState',
    }),
    [Remotes.Scope.Maze] = table.freeze({
        'MazeAction',
        'MazeState',
        'MazePrivateState',
    }),
})

local ALL_REMOTE_NAMES = table.freeze({
    'RunAction',
    'RunState',
    'RunPrivateState',
    'MazeAction',
    'MazeState',
    'MazePrivateState',
    'TODState',
})

local function assertServer(operationName)
    if RunService:IsClient() then
        error(string.format('%s can only be called on the server.', operationName), 0)
    end
end

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

local REMOTE_FUNCTION_NAMES = {}

local function ensureRemote(container, name)
    local remote = container:FindFirstChild(name)
    if remote then
        return remote
    end

    -- 使用 table.find 检查是否需要创建 RemoteFunction
    local isFunction = table.find(REMOTE_FUNCTION_NAMES, name) ~= nil

    if isFunction then
        remote = Instance.new('RemoteFunction')
    else
        remote = Instance.new('RemoteEvent')
    end
    remote.Name = name
    remote.Parent = container
    return remote
end

local function waitForContainer(timeoutSeconds)
    if timeoutSeconds == nil then
        return ReplicatedStorage:WaitForChild('Remotes')
    end

    return ReplicatedStorage:WaitForChild('Remotes', timeoutSeconds)
end

local function waitForRemote(container, name, timeoutSeconds)
    if timeoutSeconds == nil then
        return container:WaitForChild(name)
    end

    return container:WaitForChild(name, timeoutSeconds)
end

function Remotes.ensure()
    assertServer('Remotes.ensure')

    local container = ensureContainer()
    local resolved = {}

    for _, name in ipairs(ALL_REMOTE_NAMES) do
        resolved[name] = ensureRemote(container, name)
    end

    return resolved
end

function Remotes.ensureScope(scope)
    assertServer('Remotes.ensureScope')

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

function Remotes.waitForScope(scope, timeoutSeconds)
    local remoteNames = REMOTE_NAMES_BY_SCOPE[scope]
    if remoteNames == nil then
        error(string.format('Unknown remote scope %q', tostring(scope)), 0)
    end

    local startTime = os.clock()
    local function getRemainingTimeout()
        if timeoutSeconds == nil then
            return nil
        end

        local elapsed = os.clock() - startTime
        local remaining = timeoutSeconds - elapsed
        if remaining < 0 then
            return 0
        end

        return remaining
    end

    local container = waitForContainer(getRemainingTimeout())
    if container == nil then
        error('Timed out waiting for ReplicatedStorage.Remotes.', 0)
    end

    local resolved = {}

    for _, name in ipairs(remoteNames) do
        local remote = waitForRemote(container, name, getRemainingTimeout())
        if remote == nil then
            error(string.format('Timed out waiting for remote %s.', name), 0)
        end

        resolved[name] = remote
    end

    return resolved
end

return Remotes
