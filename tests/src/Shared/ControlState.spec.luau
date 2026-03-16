return function()
    local ReplicatedStorage = game:GetService('ReplicatedStorage')
    local gameplay = require(ReplicatedStorage:WaitForChild('Packages'):WaitForChild('Gameplay'))
    local shared = require(ReplicatedStorage:WaitForChild('Packages'):WaitForChild('Shared'))

    local ControlState = gameplay.ControlState
    local ControlStateService = shared.Runtime.ControlStateService

    local healthyPlayerState = {
        IsDead = false,
        CanSprint = true,
    }
    local exhaustedPlayerState = {
        IsDead = false,
        CanSprint = false,
    }
    local deadPlayerState = {
        IsDead = true,
        CanSprint = false,
    }

    local state = ControlState.new()
    local defaultSummary = state:getSummary()
    assert(defaultSummary.Mode == ControlState.Mode.Walk, 'Controls should start in walk mode')
    assert(defaultSummary.SprintEnabled == true, 'Sprint should be enabled in v1')
    assert(defaultSummary.CrouchEnabled == false, 'Crouch should stay deferred in v1')

    local sprintStarted, sprintSummary = state:requestSprintStart(healthyPlayerState)
    assert(sprintStarted == true, 'Healthy players should be able to start sprinting')
    assert(sprintSummary.Mode == ControlState.Mode.Sprint, 'Sprint start should enter sprint mode')
    assert(sprintSummary.SprintRequested == true, 'Sprint start should preserve sprint intent')

    local syncWhileExhausted = state:syncPlayerState(exhaustedPlayerState)
    assert(
        syncWhileExhausted.Mode == ControlState.Mode.Walk,
        'Exhaustion should downgrade the mode back to walk'
    )
    assert(
        syncWhileExhausted.SprintRequested == true,
        'Held sprint intent should survive temporary exhaustion'
    )

    local syncAfterRecovery = state:syncPlayerState(healthyPlayerState)
    assert(
        syncAfterRecovery.Mode == ControlState.Mode.Sprint,
        'Recovered stamina should restore sprint while the key is still held'
    )

    local sprintStopped, stopSummary = state:requestSprintStop()
    assert(sprintStopped == true, 'Sprint stop should always succeed')
    assert(stopSummary.Mode == ControlState.Mode.Walk, 'Sprint stop should return to walk mode')
    assert(stopSummary.SprintRequested == false, 'Sprint stop should clear sprint intent')

    local exhaustedSprintStart, exhaustedReason = state:requestSprintStart(exhaustedPlayerState)
    assert(exhaustedSprintStart == false, 'Exhausted players should not start sprinting')
    assert(
        exhaustedReason == 'StaminaDepleted',
        'Exhausted sprint requests should return StaminaDepleted'
    )

    local deadSprintStart, deadReason = state:requestSprintStart(deadPlayerState)
    assert(deadSprintStart == false, 'Dead players should not start sprinting')
    assert(deadReason == 'Dead', 'Dead sprint requests should expose Dead')

    local deadSyncSummary = state:syncPlayerState(deadPlayerState)
    assert(deadSyncSummary.Mode == ControlState.Mode.Walk, 'Dead players should stay in walk mode')
    assert(deadSyncSummary.SprintRequested == false, 'Death should clear sprint intent')

    local service = ControlStateService.new()
    local fakePlayer = { UserId = 902 }
    service:addPlayer(fakePlayer)

    local serviceStart, serviceSummary = service:requestSprintStart(fakePlayer, healthyPlayerState)
    assert(serviceStart == true, 'Service should start sprinting for healthy players')
    assert(
        serviceSummary.Mode == ControlState.Mode.Sprint,
        'Service summary should enter sprint mode'
    )

    local syncOk, serviceWalkSummary = service:syncPlayerState(fakePlayer, exhaustedPlayerState)
    assert(syncOk == true, 'Service sync should succeed for tracked players')
    assert(
        serviceWalkSummary.Mode == ControlState.Mode.Walk,
        'Service sync should downgrade on exhaustion'
    )

    local stopOk, stoppedSummary = service:requestSprintStop(fakePlayer)
    assert(stopOk == true, 'Service should stop sprinting cleanly')
    assert(stoppedSummary.SprintRequested == false, 'Service stop should clear sprint intent')

    service:removePlayer(fakePlayer)
    local fallbackSummary = service:getSummary(fakePlayer)
    assert(
        fallbackSummary.Mode == ControlState.Mode.Walk,
        'Removed players should fall back to walk mode'
    )
    assert(
        fallbackSummary.CrouchEnabled == false,
        'Fallback summary should preserve crouch deferment'
    )
end
