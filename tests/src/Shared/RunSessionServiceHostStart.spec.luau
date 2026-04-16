return function()
    local Players = game:GetService('Players')
    local ReplicatedStorage = game:GetService('ReplicatedStorage')
    local runModules = ReplicatedStorage:WaitForChild('PlaceModules'):WaitForChild('Run')
    local RunSessionService = require(runModules:WaitForChild('RunSessionService'))

    local service = RunSessionService.new()
    service.GamePhase = 'Waiting'
    service.HostUserId = 101

    local unlockCalls = 0
    service.World = {
        unlockAllShipDoors = function()
            unlockCalls += 1
        end,
    }
    service._setStatus = function() end
    service._syncStartGamePrompt = function() end

    service:_onHostStartGame({
        UserId = 202,
        DisplayName = 'Crewmate',
    })
    assert(unlockCalls == 0, 'Non-hosts should not unlock the ship doors')
    assert(service.GamePhase == 'Waiting', 'Non-hosts should not advance the run phase')

    service:_onHostStartGame({
        UserId = 101,
        DisplayName = 'Host',
    })
    assert(unlockCalls == 1, 'The host should unlock the ship doors when starting the run')
    assert(service.GamePhase == 'Playing', 'The host should advance the run phase')

    local fakePlayer = {
        Character = nil,
    }
    local originalCharacterAutoLoads = Players.CharacterAutoLoads

    Players.CharacterAutoLoads = false
    assert(
        service:_shouldLoadCharacterOnJoin(fakePlayer) == true,
        'Waiting joins should only load manually while CharacterAutoLoads is disabled'
    )

    Players.CharacterAutoLoads = true
    assert(
        service:_shouldLoadCharacterOnJoin(fakePlayer) == false,
        'Waiting joins should not load manually once CharacterAutoLoads is enabled'
    )

    fakePlayer.Character = {}
    Players.CharacterAutoLoads = false
    assert(
        service:_shouldLoadCharacterOnJoin(fakePlayer) == false,
        'Waiting joins should not force another load when the player already has a character'
    )

    Players.CharacterAutoLoads = originalCharacterAutoLoads
end
