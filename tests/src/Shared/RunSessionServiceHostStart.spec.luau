return function()
    local Players = game:GetService('Players')
    local ReplicatedStorage = game:GetService('ReplicatedStorage')
    local runModules = ReplicatedStorage:WaitForChild('PlaceModules'):WaitForChild('Run')
    local RunSessionService = require(runModules:WaitForChild('RunSessionService'))

    local service = RunSessionService.new()
    local fakePlayer = {
        Character = nil,
    }

    local originalCharacterAutoLoads = Players.CharacterAutoLoads

    Players.CharacterAutoLoads = false
    assert(
        service:_shouldLoadCharacterOnJoin(fakePlayer) == true,
        'Waiting-phase joins should only load manually while CharacterAutoLoads is disabled'
    )

    Players.CharacterAutoLoads = true
    assert(
        service:_shouldLoadCharacterOnJoin(fakePlayer) == false,
        'Waiting-phase joins should not load manually once CharacterAutoLoads is enabled'
    )

    fakePlayer.Character = {}
    Players.CharacterAutoLoads = false
    assert(
        service:_shouldLoadCharacterOnJoin(fakePlayer) == false,
        'Joins should not force another load when the player already has a character'
    )

    Players.CharacterAutoLoads = originalCharacterAutoLoads
end
