local MazeToRunTransition = require(script.Parent.MazeToRunTransition)

local transition = MazeToRunTransition.new()

local MazeRunPortal = {}

function MazeRunPortal.returnPlayers(params)
    return transition:returnPlayers(params)
end

return MazeRunPortal
