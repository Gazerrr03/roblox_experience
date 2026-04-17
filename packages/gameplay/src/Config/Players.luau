local Players = {}

Players.DefaultPlayer = table.freeze({
    Id = 'default-player',
    Name = 'Player',
    Components = table.freeze({
        Health = table.freeze({
            MaxHealthPips = 2,
        }),
        Stamina = table.freeze({
            MaxStamina = 100,
            DrainPerSecond = 35,
            RecoveryPerSecond = 20,
            RecoveryDelaySeconds = 1.5,
            ResumeThreshold = 20,
        }),
        Movement = table.freeze({
            MaxWalkSpeed = 16,
            MaxSprintSpeed = 24,
            JumpVelocity = 50,
        }),
        Inventory = table.freeze({
            SlotCount = 8,
            InteractionRange = 5,
        }),
    }),
})

return Players
