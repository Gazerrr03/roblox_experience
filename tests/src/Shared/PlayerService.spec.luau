return function()
    local ReplicatedStorage = game:GetService('ReplicatedStorage')
    local packages = ReplicatedStorage:WaitForChild('Packages')
    local shared = require(packages:WaitForChild('Shared'))

    local PlayerService = shared.Runtime.PlayerService
    local ControlStateService = shared.Runtime.ControlStateService
    local FormalLocomotion = shared.Runtime.FormalLocomotion

    local player = {
        UserId = 77,
        DisplayName = 'Runner',
    }

    local playerService = PlayerService.new()
    local controlStateService = ControlStateService.new()

    playerService:addPlayer(player)
    controlStateService:addPlayer(player)

    local summary = playerService:getSummary(player)
    assert(summary ~= nil, 'Player summary should exist after addPlayer')
    assert(summary.IsDead == false, 'Player summary should expose flat IsDead state')
    assert(summary.CanSprint == true, 'Player summary should expose flat CanSprint state')
    assert(
        summary.CurrentStamina == summary.Stamina.CurrentStamina,
        'Flat stamina fields should mirror component stamina'
    )
    assert(
        summary.PlayerState.CanSprint == summary.CanSprint,
        'Nested PlayerState should stay aligned with the flat summary'
    )

    local started, controlSummary = controlStateService:requestSprintStart(player, summary)
    assert(started == true, 'Control state should accept PlayerService summaries for sprint start')

    local movementSummary = FormalLocomotion.summarize(summary, controlSummary)
    assert(
        movementSummary.Mode == FormalLocomotion.Mode.Sprint,
        'Flat PlayerService summaries should drive sprint locomotion correctly'
    )
    assert(
        movementSummary.WalkSpeed == FormalLocomotion.SprintWalkSpeed,
        'Sprint locomotion should switch to sprint walk speed'
    )

    controlStateService:removePlayer(player)
    playerService:removePlayer(player)
end
