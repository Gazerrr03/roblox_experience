return function()
    local ReplicatedStorage = game:GetService('ReplicatedStorage')
    local shared = require(ReplicatedStorage:WaitForChild('Packages'):WaitForChild('Shared'))

    local existingContainer = ReplicatedStorage:FindFirstChild('Remotes')
    if existingContainer then
        existingContainer:Destroy()
    end

    local remotes = shared.Network.Remotes.ensure()
    local container = ReplicatedStorage:FindFirstChild('Remotes')

    assert(container ~= nil, 'Remotes.ensure should create the Remotes folder')

    local expectedNames = {
        'LobbyAction',
        'LobbyState',
        'PrivateState',
        'RunAction',
        'RunSnapshot',
    }

    for _, name in ipairs(expectedNames) do
        local remote = remotes[name]
        assert(remote ~= nil, string.format('Expected %s to be present in the resolved map', name))
        assert(remote.ClassName == 'RemoteEvent', string.format('%s should be a RemoteEvent', name))
        assert(
            remote.Parent == container,
            string.format('%s should live under ReplicatedStorage.Remotes', name)
        )
    end

    local repeatedEnsure = shared.Network.Remotes.ensure()
    assert(
        repeatedEnsure.RunSnapshot == remotes.RunSnapshot,
        'ensure should be idempotent for existing remotes'
    )
    assert(
        #container:GetChildren() == #expectedNames,
        'ensure should not duplicate remotes on repeated calls'
    )
end
