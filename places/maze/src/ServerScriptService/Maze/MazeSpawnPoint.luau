local MazeSpawnPoint = {}
MazeSpawnPoint.__index = MazeSpawnPoint

MazeSpawnPoint.Kind = table.freeze({
    Spawn = 'Spawn',
    ReturnHold = 'ReturnHold',
})

function MazeSpawnPoint.new(kind, cframe)
    return setmetatable({
        Kind = kind,
        CFrame = cframe,
    }, MazeSpawnPoint)
end

function MazeSpawnPoint:getCFrame()
    return self.CFrame
end

return MazeSpawnPoint
