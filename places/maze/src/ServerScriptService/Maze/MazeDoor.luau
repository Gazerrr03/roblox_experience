local MazeDoor = {}
MazeDoor.__index = MazeDoor

function MazeDoor.new(rawDoorway)
    return setmetatable(rawDoorway, MazeDoor)
end

function MazeDoor:toggle()
    self.IsOpen = not self.IsOpen
    self.Part.CanCollide = not self.IsOpen
    self.Part.Transparency = self.IsOpen and 0.65 or self.ClosedTransparency

    if self.Prompt ~= nil then
        self.Prompt.ActionText = self.IsOpen and 'Close' or 'Open'
    end

    return true
end

function MazeDoor:bind(callback)
    if self.Prompt == nil then
        return nil
    end

    return self.Prompt.Triggered:Connect(callback)
end

return MazeDoor
