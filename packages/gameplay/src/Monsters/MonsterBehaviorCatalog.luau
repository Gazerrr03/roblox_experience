local BEHAVIOR = table.freeze({
    Patrol = 'Patrol',
    SenseNearestTarget = 'SenseNearestTarget',
    Chase = 'Chase',
    LoseTarget = 'LoseTarget',
    Attack = 'Attack',
    Suppressed = 'Suppressed',
})

local knownBehaviorIds = {}
for _, behaviorId in pairs(BEHAVIOR) do
    knownBehaviorIds[behaviorId] = true
end

local MonsterBehaviorCatalog = table.freeze({
    Behavior = BEHAVIOR,
    Known = table.freeze(knownBehaviorIds),
    MazeExecutable = table.freeze({
        [BEHAVIOR.Patrol] = true,
        [BEHAVIOR.SenseNearestTarget] = true,
        [BEHAVIOR.Chase] = true,
        [BEHAVIOR.Attack] = true,
    }),
})

return MonsterBehaviorCatalog
