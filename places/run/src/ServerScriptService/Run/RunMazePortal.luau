local RunToMazeTransition = require(script.Parent.RunToMazeTransition)

local transition = RunToMazeTransition.new()

local RunMazePortal = {}

RunMazePortal.FailureCode = RunToMazeTransition.FailureCode

function RunMazePortal.enter(params)
    return transition:enter(params)
end

return RunMazePortal
