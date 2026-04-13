local RunDoor = {}
RunDoor.__index = RunDoor

function RunDoor.new(name, parts)
    return setmetatable({
        Name = name,
        Parts = parts or {},
        IsOpen = false,
    }, RunDoor)
end

function RunDoor:open()
    if self.IsOpen then
        return
    end

    self.IsOpen = true
    for _, part in ipairs(self.Parts) do
        part.CanCollide = false
        part.Transparency = 1
    end
end

return RunDoor
