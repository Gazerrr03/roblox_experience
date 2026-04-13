return function()
    local ReplicatedStorage = game:GetService('ReplicatedStorage')
    local Workspace = game:GetService('Workspace')

    local lobbyModules = ReplicatedStorage:WaitForChild('PlaceModules'):WaitForChild('Lobby')
    local builder = require(lobbyModules:WaitForChild('LobbyWorldBuilder'))

    local root = Instance.new('Folder')
    root.Name = 'LobbyStaticWorld'
    root.Parent = Workspace

    local spawnMarker = Instance.new('Part')
    spawnMarker.Name = 'SpawnMarker'
    spawnMarker.Anchored = true
    spawnMarker.CFrame = CFrame.new(12, 5, -8)
    spawnMarker.Parent = root

    local readyPart = Instance.new('Part')
    readyPart.Name = 'ReadyPrompt'
    readyPart.Anchored = true
    readyPart.Parent = root

    local readyPrompt = Instance.new('ProximityPrompt')
    readyPrompt.Parent = readyPart

    local startPart = Instance.new('Part')
    startPart.Name = 'StartRunPrompt'
    startPart.Anchored = true
    startPart.Parent = root

    local startPrompt = Instance.new('ProximityPrompt')
    startPrompt.Parent = startPart

    local world = builder.build()

    assert(world ~= nil, 'Lobby static world should be detected when present in Workspace')
    assert(world.Root == root, 'Lobby static world should preserve the authored root')
    assert(
        world.SpawnCFrame == spawnMarker.CFrame,
        'Lobby static world should expose the authored spawn marker'
    )
    assert(world.ReadyPrompt == readyPrompt, 'Lobby static world should expose the ready prompt')
    assert(world.StartRunPrompt == startPrompt, 'Lobby static world should expose the start prompt')

    root:Destroy()

    local missingPromptRoot = Instance.new('Folder')
    missingPromptRoot.Name = 'LobbyStaticWorld'
    missingPromptRoot.Parent = Workspace

    local ok, err = pcall(function()
        builder.build()
    end)
    assert(ok == false, 'Lobby static world should fail loudly when required prompts are missing')
    assert(
        string.find(tostring(err), 'ReadyPrompt', 1, true) ~= nil,
        'Lobby static world failures should mention the missing prompt part'
    )

    missingPromptRoot:Destroy()
end
