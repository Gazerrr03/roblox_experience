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
    assert(defaultSummary.SneakRequested == false, 'Sneak should not start requested')
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
        syncWhileExhausted.SprintRequested == false,
        'Exhaustion should clear sprint intent until the player presses sprint again'
    )

    local syncAfterRecovery = state:syncPlayerState(healthyPlayerState)
    assert(
        syncAfterRecovery.Mode == ControlState.Mode.Walk,
        'Recovered stamina should stay in walk mode until sprint is requested again'
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

    local exhaustedIntentState = ControlState.new()
    local latchedSprintStart, latchedReason =
        exhaustedIntentState:requestSprintStart(exhaustedPlayerState)
    assert(latchedSprintStart == false, 'Exhausted sprint starts should still fail')
    assert(latchedReason == 'StaminaDepleted', 'Exhausted starts should expose StaminaDepleted')

    local latchedSummary = exhaustedIntentState:getSummary()
    assert(
        latchedSummary.SprintRequested == false,
        'Exhausted sprint starts should not preserve sprint intent'
    )

    local recoveredLatchedSummary = exhaustedIntentState:syncPlayerState(healthyPlayerState)
    assert(
        recoveredLatchedSummary.Mode == ControlState.Mode.Walk,
        'Recovered stamina should remain in walk mode until sprint is requested again'
    )

    local resumedSprintOk, resumedSprintSummary =
        exhaustedIntentState:requestSprintStart(healthyPlayerState)
    assert(resumedSprintOk == true, 'Recovered players should be able to request sprint again')
    assert(
        resumedSprintSummary.Mode == ControlState.Mode.Sprint,
        'Explicit re-press after recovery should re-enter sprint mode'
    )

    local sneakState = ControlState.new()
    local sneakStarted, sneakSummary = sneakState:requestSneakStart(healthyPlayerState)
    assert(sneakStarted == true, 'Healthy players should be able to start sneaking')
    assert(sneakSummary.Mode == ControlState.Mode.Sneak, 'Sneak start should enter sneak mode')
    assert(sneakSummary.SneakRequested == true, 'Sneak start should preserve sneak intent')
    assert(sneakSummary.SprintRequested == false, 'Sneak start should clear sprint intent')

    local sprintFromSneakOk, sprintFromSneakSummary =
        sneakState:requestSprintStart(healthyPlayerState)
    assert(sprintFromSneakOk == true, 'Healthy players should be able to sprint from sneak')
    assert(
        sprintFromSneakSummary.Mode == ControlState.Mode.Sprint,
        'Sprint should override sneak mode'
    )
    assert(sprintFromSneakSummary.SneakRequested == false, 'Sprint start should clear sneak intent')

    local sneakFromSprintOk, sneakFromSprintSummary =
        sneakState:requestSneakStart(healthyPlayerState)
    assert(sneakFromSprintOk == true, 'Healthy players should be able to sneak from sprint')
    assert(
        sneakFromSprintSummary.Mode == ControlState.Mode.Sneak,
        'Sneak should override sprint mode'
    )
    assert(
        sneakFromSprintSummary.SprintRequested == false,
        'Sneak start should clear sprint intent'
    )

    local sneakStopped, sneakStopSummary = sneakState:requestSneakStop()
    assert(sneakStopped == true, 'Sneak stop should always succeed')
    assert(sneakStopSummary.Mode == ControlState.Mode.Walk, 'Sneak stop should return to walk mode')
    assert(sneakStopSummary.SneakRequested == false, 'Sneak stop should clear sneak intent')

    local exhaustedSneakState = ControlState.new()
    local exhaustedSneakOk, exhaustedSneakSummary =
        exhaustedSneakState:requestSneakStart(exhaustedPlayerState)
    assert(exhaustedSneakOk == true, 'Exhausted players should still be able to sneak')
    assert(
        exhaustedSneakSummary.Mode == ControlState.Mode.Sneak,
        'Exhausted sneak should enter sneak mode'
    )

    local deadSprintStart, deadReason = state:requestSprintStart(deadPlayerState)
    assert(deadSprintStart == false, 'Dead players should not start sprinting')
    assert(deadReason == 'Dead', 'Dead sprint requests should expose Dead')

    local deadSneakStart, deadSneakReason = sneakState:requestSneakStart(deadPlayerState)
    assert(deadSneakStart == false, 'Dead players should not start sneaking')
    assert(deadSneakReason == 'Dead', 'Dead sneak requests should expose Dead')

    exhaustedSneakState:syncPlayerState(deadPlayerState)
    assert(
        exhaustedSneakState:getSummary().Mode == ControlState.Mode.Walk,
        'Death should clear sneak mode'
    )
    assert(
        exhaustedSneakState:getSummary().SneakRequested == false,
        'Death should clear sneak intent'
    )

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

    local serviceSneakOk, serviceSneakSummary =
        service:requestSneakStart(fakePlayer, exhaustedPlayerState)
    assert(serviceSneakOk == true, 'Service should allow exhausted players to sneak')
    assert(
        serviceSneakSummary.Mode == ControlState.Mode.Sneak,
        'Service sneak should enter sneak mode'
    )

    local serviceSneakStopOk, serviceSneakStopSummary = service:requestSneakStop(fakePlayer)
    assert(serviceSneakStopOk == true, 'Service should stop sneaking cleanly')
    assert(
        serviceSneakStopSummary.SneakRequested == false,
        'Service sneak stop should clear sneak intent'
    )

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
