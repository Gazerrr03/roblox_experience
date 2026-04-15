return function()
    local ReplicatedStorage = game:GetService('ReplicatedStorage')
    local gameplay = require(ReplicatedStorage:WaitForChild('Packages'):WaitForChild('Gameplay'))
    local archetypes = gameplay.ProcGen.MazeRoomArchetypes

    local cavePocket = archetypes.getDefinition('CavePocket')
    assert(cavePocket ~= nil, 'Room archetype catalog should expose a cave pocket definition')
    assert(
        cavePocket.SupportsExternalShellModel == true,
        'Cave pocket archetype should allow authored external shell models'
    )
    assert(
        cavePocket.VisualLanguage == 'NaturalCave',
        'Cave pocket archetype should advertise a cave-like visual language'
    )

    local campChamber = archetypes.classifyRoom({
        Kind = 'Camp',
        DoorCount = 3,
    })
    assert(
        campChamber.Id == 'CampChamber',
        'Camp rooms should classify into the dedicated camp chamber archetype'
    )

    local caveClassified = archetypes.classifyRoom({
        Kind = 'Loot',
        DoorCount = 2,
    })
    assert(
        caveClassified.Id == 'CavePocket',
        'Low-door-count loot rooms should classify into the cave archetype'
    )
end
