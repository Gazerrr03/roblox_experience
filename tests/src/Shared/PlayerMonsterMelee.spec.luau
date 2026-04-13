return function()
    local ReplicatedStorage = game:GetService('ReplicatedStorage')
    local gameplay = require(ReplicatedStorage:WaitForChild('Packages'):WaitForChild('Gameplay'))

    local melee = gameplay.Combat.PlayerMonsterMelee

    local playerPos = Vector3.new(0, 0, 0)
    local monsterPos = Vector3.new(0, 0, 5)
    local look = Vector3.new(0, 0, 1)

    local ok, reason = melee.evaluateSwing(playerPos, look, monsterPos, 6, 70)
    assert(
        ok == true and reason == 'HitGeometryOk',
        'Forward swing within range should pass geometry'
    )

    local farPos = Vector3.new(0, 0, 12)
    local farOk, farReason = melee.evaluateSwing(playerPos, look, farPos, 6, 70)
    assert(farOk == false and farReason == 'OutOfRange', 'Distant targets should fail range')

    local sidePos = Vector3.new(8, 0, 0)
    local sideOk, sideReason = melee.evaluateSwing(playerPos, look, sidePos, 12, 45)
    assert(
        sideOk == false and sideReason == 'OutOfSwingArc',
        'Wide off-axis targets should fail arc gate'
    )

    local boundaryRad = math.rad(35)
    local boundaryPos = Vector3.new(math.sin(boundaryRad) * 4, 0, math.cos(boundaryRad) * 4)
    local boundaryOk, boundaryReason = melee.evaluateSwing(playerPos, look, boundaryPos, 8, 70)
    assert(
        boundaryOk == true and boundaryReason == 'HitGeometryOk',
        'Targets near the swing arc boundary should pass'
    )
end
