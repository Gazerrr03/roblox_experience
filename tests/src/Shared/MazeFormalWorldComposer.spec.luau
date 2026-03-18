return function()
    local Workspace = game:GetService('Workspace')
    local ReplicatedStorage = game:GetService('ReplicatedStorage')
    local packages = ReplicatedStorage:WaitForChild('Packages')
    local shared = require(packages:WaitForChild('Shared'))

    local runtime = packages:WaitForChild('Shared'):WaitForChild('Runtime')
    local composer = require(runtime:WaitForChild('MazeFormalWorldComposer'))

    local testRoot = Instance.new('Folder')
    testRoot.Name = 'MazeFormalWorldComposerSpecRoot'
    testRoot.Parent = Workspace

    local world = composer.build(12345, shared.Config.SessionConfig.ProcGen, {
        Parent = testRoot,
        WorldName = 'MazeFormalWorldComposerSpecWorld',
        IncludeRoomMarkers = false,
    })

    assert(
        world.Root ~= nil and world.Root.Parent == testRoot,
        'Formal world should build under the requested parent'
    )
    assert(world.ReturnPrompt == nil, 'Formal world should not expose the debug return prompt')
    assert(
        world.ReturnHoldPad ~= nil,
        'Formal world should create a return hold pad for post-run staging'
    )
    assert(next(world.LootNodes or {}) ~= nil, 'Formal world should create loot nodes')
    assert(next(world.ExtractionNodes or {}) ~= nil, 'Formal world should create extraction nodes')
    assert(
        world.Root:FindFirstChild('ExpeditionConsole', true) == nil,
        'Formal world should not recreate the expedition console'
    )
    assert(
        world.Root:FindFirstChild('SettlementPad', true) == nil,
        'Formal world should not recreate settlement pads inside the maze'
    )

    local extractionCount = 0
    for _, extractionNode in pairs(world.ExtractionNodes) do
        extractionCount += 1
        assert(extractionNode.Prompt ~= nil, 'Extraction nodes should expose a prompt')
        assert(
            extractionNode.Prompt.ObjectText == 'Maze Exit',
            'Formal extraction prompt should use maze exit wording'
        )
    end

    assert(extractionCount >= 1, 'Formal world should include at least one extraction node')

    local ok, err = pcall(function()
        composer.build(12345, shared.Config.SessionConfig.ProcGen, {
            Parent = testRoot,
            WorldName = 'MazeFormalWorldComposerMissingAssets',
            RequireModuleAssets = true,
        })
    end)
    assert(
        ok == false,
        'Formal world should fail loudly when module assets are required but missing'
    )
    assert(
        string.find(tostring(err), 'no asset root was supplied', 1, true) ~= nil,
        'Formal world should explain the missing module asset root'
    )

    testRoot:Destroy()
end
