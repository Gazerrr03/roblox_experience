local MonsterPresentationCatalog = {}

MonsterPresentationCatalog.RigType = table.freeze({
    R6 = 'R6',
})

MonsterPresentationCatalog.AnimationMode = table.freeze({
    DefaultR6 = 'defaultR6',
})

MonsterPresentationCatalog.KnownRigType = table.freeze({
    [MonsterPresentationCatalog.RigType.R6] = true,
})

MonsterPresentationCatalog.KnownAnimationMode = table.freeze({
    [MonsterPresentationCatalog.AnimationMode.DefaultR6] = true,
})

return MonsterPresentationCatalog
