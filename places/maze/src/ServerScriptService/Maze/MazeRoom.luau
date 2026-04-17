local MazeRoom = {}
MazeRoom.__index = MazeRoom

function MazeRoom.new(roomData, affordance, instance)
    local room = table.clone(roomData)
    room.Affordance = affordance
    room.Instance = instance
    return setmetatable(room, MazeRoom)
end

return MazeRoom
