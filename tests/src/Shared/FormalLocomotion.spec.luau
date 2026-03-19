return function()
    local ReplicatedStorage = game:GetService('ReplicatedStorage')
    local shared = require(ReplicatedStorage:WaitForChild('Packages'):WaitForChild('Shared'))

    local locomotion = shared.Runtime.FormalLocomotion

    local walkSummary = locomotion.summarize({
        IsDead = false,
        CanSprint = true,
    }, {
        Mode = locomotion.Mode.Walk,
    })
    assert(walkSummary.Mode == locomotion.Mode.Walk, 'Walk summary should stay in walk mode')
    assert(
        walkSummary.WalkSpeed == locomotion.WalkSpeed,
        'Walk summary should use the formal walk speed'
    )
    assert(walkSummary.CanSprint == true, 'Healthy players should be able to sprint')

    local sprintSummary = locomotion.summarize({
        IsDead = false,
        CanSprint = true,
    }, {
        Mode = locomotion.Mode.Sprint,
    })
    assert(
        sprintSummary.Mode == locomotion.Mode.Sprint,
        'Sprint summary should stay in sprint mode'
    )
    assert(
        sprintSummary.WalkSpeed == locomotion.SprintWalkSpeed,
        'Sprint summary should use the formal sprint speed'
    )

    local recoveringSummary = locomotion.summarize({
        IsDead = false,
        CanSprint = false,
    }, {
        Mode = locomotion.Mode.Walk,
    })
    assert(
        recoveringSummary.Mode == locomotion.Mode.Walk,
        'Recovering players should stay in walk mode'
    )
    assert(
        recoveringSummary.CanSprint == false,
        'Recovering players should expose that sprint is unavailable'
    )

    local deadSummary = locomotion.summarize({
        IsDead = true,
        CanSprint = false,
    }, {
        Mode = locomotion.Mode.Sprint,
    })
    assert(
        deadSummary.Mode == locomotion.Mode.Walk,
        'Dead players should be forced back to walk mode'
    )
    assert(deadSummary.WalkSpeed == 0, 'Dead players should not be able to move')
    assert(deadSummary.CanSprint == false, 'Dead players should not be able to sprint')

    local humanoid = Instance.new('Humanoid')
    locomotion.applyToHumanoid(humanoid, walkSummary)
    assert(
        humanoid.WalkSpeed == locomotion.WalkSpeed,
        'Walk movement should apply the formal walk speed to the humanoid'
    )

    locomotion.applyToHumanoid(humanoid, sprintSummary)
    assert(
        humanoid.WalkSpeed == locomotion.SprintWalkSpeed,
        'Sprint movement should apply the formal sprint speed to the humanoid'
    )

    locomotion.applyToHumanoid(humanoid, deadSummary)
    assert(humanoid.WalkSpeed == 0, 'Dead movement should stop humanoid movement')

    humanoid.WalkSpeed = 123
    locomotion.applyToHumanoid(humanoid, nil)
    assert(
        humanoid.WalkSpeed == locomotion.WalkSpeed,
        'Missing movement summaries should fall back to the formal walk speed'
    )

    locomotion.applyToHumanoid(nil, sprintSummary)
    humanoid:Destroy()
end
