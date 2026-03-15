return function()
    local ReplicatedStorage = game:GetService('ReplicatedStorage')
    local gameplay = require(ReplicatedStorage:WaitForChild('Packages'):WaitForChild('Gameplay'))
    local logic = gameplay.Monsters.MonsterLogic

    local nearestTarget = logic.pickNearestTarget(Vector3.new(0, 0, 0), {
        Alpha = Vector3.new(3, 0, 4),
        Bravo = Vector3.new(2, 0, 0),
        Charlie = Vector3.new(25, 0, 0),
    }, 10)

    assert(nearestTarget == 'Bravo', 'Nearest in-range target should be selected')

    local missingTarget = logic.pickNearestTarget(Vector3.new(0, 0, 0), {
        FarAway = Vector3.new(30, 0, 0),
    }, 10)

    assert(missingTarget == nil, 'Targets outside sight range should be ignored')

    local equidistantTarget = logic.pickNearestTarget(Vector3.new(0, 0, 0), {
        Alpha = Vector3.new(5, 0, 0),
        Bravo = Vector3.new(-5, 0, 0),
    }, 10)

    assert(
        equidistantTarget == 'Alpha' or equidistantTarget == 'Bravo',
        'Equidistant targets should still resolve to one valid in-range target'
    )

    local partialStep = logic.stepToward(Vector3.new(0, 0, 0), Vector3.new(10, 0, 0), 4, 1)
    assert(partialStep == Vector3.new(4, 0, 0), 'Step movement should advance by speed * dt')

    local clampedStep = logic.stepToward(Vector3.new(0, 0, 0), Vector3.new(5, 0, 0), 12, 1)
    assert(clampedStep == Vector3.new(5, 0, 0), 'Movement should clamp at the target')

    local stationary = logic.stepToward(Vector3.new(2, 0, 0), Vector3.new(2, 0, 0), 12, 1)
    assert(stationary == Vector3.new(2, 0, 0), 'Zero-distance movement should keep position')
end
