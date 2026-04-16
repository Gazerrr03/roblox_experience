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
        'RunAction',
        'RunState',
        'RunPrivateState',
        'MazeAction',
        'MazeState',
        'MazePrivateState',
    }
    local unexpectedRunLegacyNames = {
        'ShowNarrative',
        'GetInventory',
        'EquipItem',
        'UseItem',
        'UseItemFunction',
        'GetInteractables',
        'GetItemData',
        'ItemUsageFeedback',
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
        repeatedEnsure.RunState == remotes.RunState,
        'ensure should be idempotent for existing remotes'
    )
    assert(
        #container:GetChildren() == #expectedNames,
        'ensure should not duplicate remotes on repeated calls'
    )

    for _, legacyName in ipairs(unexpectedRunLegacyNames) do
        assert(
            remotes[legacyName] == nil and container:FindFirstChild(legacyName) == nil,
            string.format('Legacy run remote %s should no longer be created', legacyName)
        )
    end

    local mazeScoped = shared.Network.Remotes.ensureScope(shared.Network.Remotes.Scope.Maze)
    assert(mazeScoped.MazeAction == remotes.MazeAction, 'Maze scope should reuse MazeAction')
    assert(mazeScoped.MazeState == remotes.MazeState, 'Maze scope should reuse MazeState')
    assert(
        mazeScoped.MazePrivateState == remotes.MazePrivateState,
        'Maze scope should reuse MazePrivateState'
    )

    local waitedMazeScope =
        shared.Network.Remotes.waitForScope(shared.Network.Remotes.Scope.Maze, 0)
    assert(
        waitedMazeScope.MazeState == remotes.MazeState,
        'waitForScope should reuse an existing MazeState remote without creating a new one'
    )

    existingContainer:Destroy()
    local missingWaitOk, missingWaitError = pcall(function()
        shared.Network.Remotes.waitForScope(shared.Network.Remotes.Scope.Maze, 0)
    end)
    assert(missingWaitOk == false, 'waitForScope should fail when remotes are missing')
    assert(
        string.find(tostring(missingWaitError), 'ReplicatedStorage%.Remotes') ~= nil,
        'waitForScope should explain that the remotes container is missing'
    )
    assert(
        ReplicatedStorage:FindFirstChild('Remotes') == nil,
        'waitForScope should not create the remotes container when it is missing'
    )

    local invalidScopeOk = pcall(function()
        shared.Network.Remotes.waitForScope('Nope', 0)
    end)
    assert(invalidScopeOk == false, 'waitForScope should reject unknown scopes')
end
