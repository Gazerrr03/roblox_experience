local ReplicatedStorage = game:GetService('ReplicatedStorage')

local MazeBootstrapStatus = {}

MazeBootstrapStatus.PhaseAttribute = 'MazeBootstrapPhase'
MazeBootstrapStatus.ErrorAttribute = 'MazeBootstrapError'
MazeBootstrapStatus.FailedAttribute = 'MazeBootstrapFailed'

function MazeBootstrapStatus.set(phase, err)
    ReplicatedStorage:SetAttribute(MazeBootstrapStatus.PhaseAttribute, phase)
    ReplicatedStorage:SetAttribute(MazeBootstrapStatus.FailedAttribute, err ~= nil)
    ReplicatedStorage:SetAttribute(MazeBootstrapStatus.ErrorAttribute, err)
end

return table.freeze(MazeBootstrapStatus)
