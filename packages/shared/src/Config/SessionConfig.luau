local SessionConfig = {
    PlaceIds = {
        Lobby = 0,
        Maze = 0,
        Run = 0,
    },
    MinPlayers = 1,
    MaxPlayers = 4,
    DefaultSeed = 12345,
    DefaultQuota = 120,
    DefaultRunDurationSeconds = 180,
    SettlementDurationSeconds = 8,
    InventoryCapacity = 5,
    ProcGen = {
        MainPathRooms = 4,
        MaxBranches = 2,
        RoomSpacing = 40,
        RoomSize = Vector3.new(28, 16, 28),
    },
}

return SessionConfig
