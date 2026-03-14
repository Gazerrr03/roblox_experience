return function()
    local ReplicatedStorage = game:GetService('ReplicatedStorage')
    local shared = require(ReplicatedStorage:WaitForChild('Packages'):WaitForChild('Shared'))
    local gameplay = require(ReplicatedStorage:WaitForChild('Packages'):WaitForChild('Gameplay'))
    local machine = gameplay.Session.SessionStateMachine.new(shared.Enums.RunState.Camp)

    assert(
        machine:canTransition(shared.Enums.RunState.Expedition),
        'Camp should move to expedition'
    )
    machine:transition(shared.Enums.RunState.Expedition)
    assert(machine.Current == shared.Enums.RunState.Expedition, 'State should move to expedition')
    assert(
        machine:canTransition(shared.Enums.RunState.Settlement),
        'Expedition should allow direct settlement'
    )
end
