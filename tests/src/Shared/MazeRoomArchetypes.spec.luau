return function()
    local ReplicatedStorage = game:GetService('ReplicatedStorage')
    local gameplay = require(ReplicatedStorage:WaitForChild('Packages'):WaitForChild('Gameplay'))
    local archetypes = gameplay.ProcGen.MazeRoomArchetypes

    local landmark = archetypes.getDefinition('LandmarkFacility')
    assert(landmark ~= nil, 'Room archetype catalog should expose a landmark facility definition')
    assert(
        landmark.SupportsExternalShellModel == true,
        'Landmark facility archetype should allow authored external shell models'
    )
    assert(
        landmark.VisualLanguage == 'NavigationAnchor',
        'Landmark facility archetype should advertise a navigation-anchor visual language'
    )

    local classifiedCamp = archetypes.classifyRoom({
        Kind = 'Camp',
        DoorCount = 3,
    })
    assert(
        classifiedCamp.Id == 'EntrySafe',
        'Camp rooms should classify into the entry-safe archetype'
    )

    local classifiedHighRisk = archetypes.classifyRoom({
        RoomTemplateId = 'HighValueRisk',
        Kind = 'Loot',
        DoorCount = 1,
    })
    assert(
        classifiedHighRisk.Id == 'HighValueRisk',
        'Template-driven rooms should keep their matching archetype id'
    )
end
