return function()
    local ReplicatedStorage = game:GetService('ReplicatedStorage')
    local gameplay = require(ReplicatedStorage:WaitForChild('Packages'):WaitForChild('Gameplay'))
    local shared = require(ReplicatedStorage:WaitForChild('Packages'):WaitForChild('Shared'))

    local PlayerState = gameplay.PlayerState
    local PlayerStateService = shared.Runtime.PlayerStateService

    local state = PlayerState.new()
    local defaultSummary = state:getSummary()

    assert(defaultSummary.HealthPips == 2, 'Default health should start with two pips')
    assert(defaultSummary.MaxHealthPips == 2, 'Max health should expose two pips')
    assert(defaultSummary.CurrentStamina == 100, 'Default stamina should start full')
    assert(defaultSummary.MaxStamina == 100, 'Max stamina should expose the full value')
    assert(defaultSummary.IsDead == false, 'Default state should start alive')
    assert(defaultSummary.CorpseActive == false, 'Default state should not have a corpse')

    local lightDamageApplied, lightDamageResult = state:applyDamage(PlayerState.DamageKind.Light)
    assert(lightDamageApplied == true, 'Light damage should be accepted')
    assert(lightDamageResult.HealthPips == 1, 'Light damage should remove one pip')
    assert(lightDamageResult.IsDead == false, 'One remaining pip should keep the player alive')

    local heavyDamageApplied, heavyDamageResult = state:applyDamage(PlayerState.DamageKind.Heavy)
    assert(heavyDamageApplied == true, 'Heavy damage should be accepted')
    assert(heavyDamageResult.HealthPips == 0, 'Heavy damage should clamp at zero pips')
    assert(heavyDamageResult.IsDead == true, 'Zero health should mark the player dead')
    assert(heavyDamageResult.CorpseActive == true, 'Death should activate corpse state')

    local overkillApplied, overkillResult = state:applyDamage(PlayerState.DamageKind.Heavy)
    assert(overkillApplied == true, 'Additional damage should stay safe after death')
    assert(overkillResult.HealthPips == 0, 'Health should not drop below zero')

    local sprintState = PlayerState.new()
    local sprintStarted, sprintStartSummary = sprintState:setSprinting(true)
    assert(sprintStarted == true, 'Fresh players should be allowed to sprint')
    assert(sprintStartSummary.CanSprint == true, 'Fresh sprint state should stay sprintable')

    local sprintDrainSummary = sprintState:step(1)
    assert(sprintDrainSummary.CurrentStamina == 65, 'Sprint should drain stamina over time')

    local sprintExhaustionSummary = sprintState:step(2)
    assert(sprintExhaustionSummary.CurrentStamina == 0, 'Sprint drain should clamp at zero stamina')
    assert(sprintExhaustionSummary.CanSprint == false, 'Zero stamina should disable sprinting')

    local depletedSprintStart, depletedSprintReason = sprintState:setSprinting(true)
    assert(
        depletedSprintStart == false,
        'Depleted players should not restart sprinting immediately'
    )
    assert(
        depletedSprintReason == 'StaminaDepleted',
        'Depleted sprint attempts should expose a concrete reason'
    )

    local partialRecoverySummary = sprintState:step(0.5)
    assert(
        partialRecoverySummary.CurrentStamina == 10,
        'Recovery should refill stamina when resting'
    )
    assert(
        partialRecoverySummary.CanSprint == false,
        'Recovery below threshold should keep sprint locked'
    )

    local thresholdRecoverySummary = sprintState:step(0.5)
    assert(
        thresholdRecoverySummary.CurrentStamina == 20,
        'Recovery should reach the sprint threshold'
    )
    assert(
        thresholdRecoverySummary.CanSprint == true,
        'Threshold recovery should re-enable sprinting'
    )

    local fakePlayer = {
        UserId = 501,
    }
    local service = PlayerStateService.new()

    service:addPlayer(fakePlayer)
    local serviceSummary = service:getSummary(fakePlayer)
    assert(serviceSummary.HealthPips == 2, 'Service summary should expose default health')
    assert(serviceSummary.CurrentStamina == 100, 'Service summary should expose default stamina')

    local serviceSprintStarted = service:setSprinting(fakePlayer, true)
    assert(serviceSprintStarted == true, 'Service should allow sprint state changes')
    service:step(1)

    local drainedServiceSummary = service:getSummary(fakePlayer)
    assert(
        drainedServiceSummary.CurrentStamina == 65,
        'Service stepping should drain stamina for sprinting players'
    )

    local serviceDamageApplied, serviceDamageSummary =
        service:applyDamage(fakePlayer, PlayerState.DamageKind.Heavy)
    assert(serviceDamageApplied == true, 'Service should apply supported damage kinds')
    assert(serviceDamageSummary.IsDead == true, 'Service damage should drive the dead state')
    assert(serviceDamageSummary.CorpseActive == true, 'Service damage should expose corpse state')

    service:removePlayer(fakePlayer)
    local removedSummary = service:getSummary(fakePlayer)
    assert(removedSummary.HealthPips == 2, 'Removed players should fall back to default summary')
    assert(removedSummary.IsDead == false, 'Default summary should not stay dead after removal')
end
