return function()
    local ReplicatedStorage = game:GetService('ReplicatedStorage')
    local shared = require(ReplicatedStorage:WaitForChild('Packages'):WaitForChild('Shared'))
    local config = shared.Config.SessionConfig

    assert(type(config.PlaceIds.Lobby) == 'number', 'Lobby place id should always be numeric')
    assert(type(config.PlaceIds.Maze) == 'number', 'Maze place id should always be numeric')
    assert(type(config.PlaceIds.Run) == 'number', 'Run place id should always be numeric')
    assert(config.PlaceIds.Lobby > 0, 'Lobby place id should default to a published place id')
    assert(config.PlaceIds.Maze > 0, 'Maze place id should default to a published place id')
    assert(config.PlaceIds.Run > 0, 'Run place id should default to a published place id')
    assert(
        type(config.DebugLocalMazeHandoff) == 'boolean',
        'DebugLocalMazeHandoff should always be boolean'
    )

    assert(config.MinPlayers >= 1, 'MinPlayers should never drop below one')
    assert(config.MaxPlayers >= config.MinPlayers, 'MaxPlayers should stay above MinPlayers')
    assert(config.DefaultRunDurationSeconds > 0, 'Run duration should stay positive')
    assert(config.SettlementDurationSeconds > 0, 'Settlement duration should stay positive')
    assert(config.InventoryCapacity > 0, 'Inventory capacity should stay positive')

    assert(config.ProcGen.RoomCount > 0, 'ProcGen room count should stay positive')
    assert(config.ProcGen.ExitMin >= 0, 'ProcGen exit minimum should not be negative')
    assert(
        config.ProcGen.ExitMax >= config.ProcGen.ExitMin,
        'ProcGen exit maximum should stay above minimum'
    )
    assert(
        config.ProcGen.MaxGenerationAttempts > 0,
        'ProcGen max generation attempts should stay positive'
    )
    assert(config.ProcGen.RoomSpacing > 0, 'ProcGen room spacing should stay positive')
    assert(config.ProcGen.RoomApothem > 0, 'ProcGen room apothem should stay positive')
    assert(typeof(config.ProcGen.RoomSize) == 'Vector3', 'ProcGen room size should stay a Vector3')
    assert(config.ProcGen.RoomSize.X > 0, 'ProcGen room size X should stay positive')
    assert(config.ProcGen.RoomSize.Y > 0, 'ProcGen room size Y should stay positive')
    assert(config.ProcGen.RoomSize.Z > 0, 'ProcGen room size Z should stay positive')
    assert(config.ProcGen.DoorLeafChance >= 0, 'Door leaf chance should be >= 0')
    assert(config.ProcGen.DoorLeafChance <= 1, 'Door leaf chance should be <= 1')
end
