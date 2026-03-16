return function()
    local ReplicatedStorage = game:GetService('ReplicatedStorage')
    local shared = require(ReplicatedStorage:WaitForChild('Packages'):WaitForChild('Shared'))
    local config = shared.Config.SessionConfig

    assert(type(config.PlaceIds.Lobby) == 'number', 'Lobby place id should always be numeric')
    assert(type(config.PlaceIds.Maze) == 'number', 'Maze place id should always be numeric')
    assert(type(config.PlaceIds.Run) == 'number', 'Run place id should always be numeric')
    assert(
        type(config.DebugLocalMazeHandoff) == 'boolean',
        'DebugLocalMazeHandoff should always be boolean'
    )

    assert(config.MinPlayers >= 1, 'MinPlayers should never drop below one')
    assert(config.MaxPlayers >= config.MinPlayers, 'MaxPlayers should stay above MinPlayers')
    assert(config.DefaultRunDurationSeconds > 0, 'Run duration should stay positive')
    assert(config.SettlementDurationSeconds > 0, 'Settlement duration should stay positive')
    assert(config.InventoryCapacity > 0, 'Inventory capacity should stay positive')

    assert(config.ProcGen.MainPathRooms > 0, 'ProcGen should require at least one main-path room')
    assert(config.ProcGen.MaxBranches >= 0, 'ProcGen max branches should not be negative')
    assert(config.ProcGen.RoomSpacing > 0, 'ProcGen room spacing should stay positive')
    assert(typeof(config.ProcGen.RoomSize) == 'Vector3', 'ProcGen room size should stay a Vector3')
    assert(config.ProcGen.RoomSize.X > 0, 'ProcGen room size X should stay positive')
    assert(config.ProcGen.RoomSize.Y > 0, 'ProcGen room size Y should stay positive')
    assert(config.ProcGen.RoomSize.Z > 0, 'ProcGen room size Z should stay positive')
end
