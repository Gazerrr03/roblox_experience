local MonsterBehaviorCatalog = require(script.Parent.Parent.Monsters.MonsterBehaviorCatalog)
local MonsterEffectCatalog = require(script.Parent.Parent.Monsters.MonsterEffectCatalog)

return {
    {
        Id = 'scrap-wisp',
        Name = 'Scrap Wisp',
        Lore = 'A knot of scavenged metal and spite that circles abandoned loot trails.',
        Atmosphere = 'Dread',
        TriggerIntent = {
            Summary = 'Roams active maze lanes once the expedition starts and closes on nearby explorers.',
            Space = 'Maze expedition rooms',
        },
        CounterplayIntent = {
            Summary = 'Break line of sight around corners and use distance to reset its route.',
            Tool = 'No dedicated suppression tool in v1',
        },
        NumericProfile = {
            Speed = 12,
            SightRange = 60,
            PatrolSpeedMultiplier = 0.45,
            SpawnOffset = Vector3.new(0, 4, 0),
        },
        BehaviorIntents = {
            {
                Id = MonsterBehaviorCatalog.Behavior.Patrol,
            },
            {
                Id = MonsterBehaviorCatalog.Behavior.SenseNearestTarget,
            },
            {
                Id = MonsterBehaviorCatalog.Behavior.Chase,
            },
            {
                Id = MonsterBehaviorCatalog.Behavior.LoseTarget,
            },
        },
        EffectIntents = {
            {
                Id = MonsterEffectCatalog.Effect.SprintSuppressed,
                DurationSeconds = 2.5,
            },
        },
    },
}
