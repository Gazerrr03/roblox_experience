return function()
    local ReplicatedStorage = game:GetService('ReplicatedStorage')
    local gameplay = require(ReplicatedStorage:WaitForChild('Packages'):WaitForChild('Gameplay'))

    local runtimeProfileModule = gameplay.Monsters.MonsterRuntimeProfile
    local presentationCatalog = gameplay.Monsters.MonsterPresentationCatalog

    local componentOnlyProfile = {
        Id = 'component-only-spec',
        Name = 'Component Only Spec',
        Presentation = {
            ModelAssetId = 4446576906,
            RigType = presentationCatalog.RigType.R6,
            AnimationMode = presentationCatalog.AnimationMode.DefaultR6,
            ChaseLoopSoundAssetId = 9118823108,
        },
        Behaviors = {
            SenseNearestTarget = true,
            Chase = true,
        },
        Effects = {},
        Components = {
            Perception = {
                SightRange = 28,
            },
            Movement = {
                Speed = 12,
                PatrolSpeedMultiplier = 0.4,
                PatrolReachDistance = 2,
                SpawnOffset = Vector3.new(0, 4, 0),
            },
            Attack = {
                Range = 4,
                CooldownSeconds = 1,
                DamagePips = 1,
            },
        },
    }

    local validComponentOnly, componentOnlyReason =
        runtimeProfileModule.validate(componentOnlyProfile)
    assert(
        validComponentOnly == true,
        string.format(
            'Component-only runtime payload should stay valid, got %s',
            tostring(componentOnlyReason)
        )
    )

    local invalidMovementProfile = table.clone(componentOnlyProfile)
    invalidMovementProfile.Components = table.clone(componentOnlyProfile.Components)
    invalidMovementProfile.Components.Movement =
        table.clone(componentOnlyProfile.Components.Movement)
    invalidMovementProfile.Components.Movement.Speed = 0

    local invalidMovementOk, invalidMovementReason =
        runtimeProfileModule.validate(invalidMovementProfile)
    assert(invalidMovementOk == false, 'Invalid movement component speed should fail validation')
    assert(
        invalidMovementReason == 'InvalidRuntimeComponentMovementSpeed',
        'Invalid movement component speed should surface a dedicated reason'
    )

    local invalidAttackDamageProfile = table.clone(componentOnlyProfile)
    invalidAttackDamageProfile.Components = table.clone(componentOnlyProfile.Components)
    invalidAttackDamageProfile.Components.Attack =
        table.clone(componentOnlyProfile.Components.Attack)
    invalidAttackDamageProfile.Components.Attack.DamagePips = 3

    local invalidDamageOk, invalidDamageReason =
        runtimeProfileModule.validate(invalidAttackDamageProfile)
    assert(invalidDamageOk == false, 'Attack damage pips outside 1/2 should fail validation')
    assert(
        invalidDamageReason == 'InvalidRuntimeComponentAttackDamagePips',
        'Invalid attack damage pips should expose a dedicated reason'
    )
end
