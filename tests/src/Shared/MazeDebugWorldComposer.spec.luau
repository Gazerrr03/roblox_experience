return function()
    local Workspace = game:GetService('Workspace')
    local ReplicatedStorage = game:GetService('ReplicatedStorage')
    local packages = ReplicatedStorage:WaitForChild('Packages')
    local shared = require(packages:WaitForChild('Shared'))

    local runtime = packages:WaitForChild('Shared'):WaitForChild('Runtime')
    local composer = require(runtime:WaitForChild('MazeDebugWorldComposer'))

    local testRoot = Instance.new('Folder')
    testRoot.Name = 'MazeDebugWorldComposerSpecRoot'
    testRoot.Parent = Workspace

    local world = composer.build(12345, shared.Config.SessionConfig.ProcGen, {
        Parent = testRoot,
        WorldName = 'MazeDebugWorldComposerSpecWorld',
        IncludeRoomMarkers = false,
    })

    assert(
        world.Root ~= nil and world.Root.Parent == testRoot,
        'Debug world should build under the requested parent'
    )
    assert(world.ReturnPrompt ~= nil, 'Debug world should expose a local return prompt')
    assert(
        world.ReturnPrompt.ObjectText == 'Return To Camp (Local Debug)',
        'Debug world should keep local debug prompt wording'
    )
    assert(world.LootNodes == nil, 'Debug world should not expose the formal loot contract')
    assert(
        world.ExtractionNodes == nil,
        'Debug world should not expose the formal extraction contract'
    )
    assert(
        world.Root:FindFirstChild('ExtractionMarker', true) == nil,
        'Debug world should not build formal extraction markers'
    )

    testRoot:Destroy()
end
