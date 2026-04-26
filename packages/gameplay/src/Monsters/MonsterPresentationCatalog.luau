local MonsterPresentationCatalog = {}

MonsterPresentationCatalog.RigType = table.freeze({
    R6 = 'R6',
    CustomHumanoid = 'CustomHumanoid',
})

MonsterPresentationCatalog.AnimationMode = table.freeze({
    DefaultR6 = 'defaultR6',
    CustomHumanoid = 'customHumanoid',
})

MonsterPresentationCatalog.AnimationSlot = table.freeze({
    Idle = 'Idle',
    Walk = 'Walk',
    Run = 'Run',
    Attack = 'Attack',
})

MonsterPresentationCatalog.RequiredCustomAnimationSlots = table.freeze({
    MonsterPresentationCatalog.AnimationSlot.Idle,
    MonsterPresentationCatalog.AnimationSlot.Walk,
    MonsterPresentationCatalog.AnimationSlot.Run,
    MonsterPresentationCatalog.AnimationSlot.Attack,
})

MonsterPresentationCatalog.KnownRigType = table.freeze({
    [MonsterPresentationCatalog.RigType.R6] = true,
    [MonsterPresentationCatalog.RigType.CustomHumanoid] = true,
})

MonsterPresentationCatalog.KnownAnimationMode = table.freeze({
    [MonsterPresentationCatalog.AnimationMode.DefaultR6] = true,
    [MonsterPresentationCatalog.AnimationMode.CustomHumanoid] = true,
})

return MonsterPresentationCatalog
