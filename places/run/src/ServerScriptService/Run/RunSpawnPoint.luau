local RunSpawnPoint = {}
RunSpawnPoint.__index = RunSpawnPoint

RunSpawnPoint.Kind = table.freeze({
    Spawn = 'Spawn',
    Return = 'Return',
    MazeReturn = 'MazeReturn',
})

function RunSpawnPoint.new(kind, part)
    return setmetatable({
        Kind = kind,
        Part = part,
        CFrame = part.CFrame,
    }, RunSpawnPoint)
end

function RunSpawnPoint:getCFrame()
    self.CFrame = self.Part.CFrame
    return self.CFrame
end

return RunSpawnPoint
