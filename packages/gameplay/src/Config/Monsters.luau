local MonsterBehaviorCatalog = require(script.Parent.Parent.Monsters.MonsterBehaviorCatalog)
local MonsterEffectCatalog = require(script.Parent.Parent.Monsters.MonsterEffectCatalog)
local MonsterPresentationCatalog = require(script.Parent.Parent.Monsters.MonsterPresentationCatalog)

return {
    {
        Id = 'scrap-wisp',
        Name = 'Scrap Wisp',
        Semantics = {
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
        },
        Tuning = {
            AttackCooldownSeconds = 1,
            AttackDamagePips = 1,
            AttackRange = 4,
            Speed = 14,
            SightRange = 36,
            PatrolSpeedMultiplier = 0.45,
            SpawnOffset = Vector3.new(0, 4, 0),
        },
        Executable = {
            Presentation = {
                ModelAssetId = 9492320977,
                RigType = MonsterPresentationCatalog.RigType.R6,
                AnimationMode = MonsterPresentationCatalog.AnimationMode.DefaultR6,
                ChaseLoopSoundAssetId = 9118823108,
            },
            BehaviorIntents = {
                {
                    Id = MonsterBehaviorCatalog.Behavior.Patrol,
                    Enabled = false,
                },
                {
                    Id = MonsterBehaviorCatalog.Behavior.SenseNearestTarget,
                },
                {
                    Id = MonsterBehaviorCatalog.Behavior.Chase,
                },
                {
                    Id = MonsterBehaviorCatalog.Behavior.Attack,
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
    },
}
