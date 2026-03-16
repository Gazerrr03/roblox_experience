local function rotate(directionIndex, steps)
    return ((directionIndex - 1 + steps) % 6) + 1
end

return function()
    local ReplicatedStorage = game:GetService('ReplicatedStorage')
    local gameplay = require(ReplicatedStorage:WaitForChild('Packages'):WaitForChild('Gameplay'))
    local prefabs = gameplay.ProcGen.HexRoomPrefabs

    local expectedDefinitions = {
        T1 = { 2 },
        T2 = { 2, 5 },
        T3 = { 2, 3 },
        T4 = { 1, 2 },
        T5 = { 2, 4, 6 },
        T6 = { 2, 3, 5 },
        T7 = { 1, 2, 4, 5 },
        T8 = { 1, 2, 3, 4, 5, 6 },
    }
    local expectedRotationSteps = {
        T1 = { 0, 1, 2, 3, 4, 5 },
        T2 = { 0, 1, 2, 3, 4, 5 },
        T3 = { 0, 2, 4 },
        T4 = { 0, 2, 4 },
        T5 = { 0, 1, 2, 3, 4, 5 },
        T6 = { 0, 1, 2, 3, 4, 5 },
        T7 = { 0, 1, 2, 3, 4, 5 },
        T8 = { 0 },
    }

    local typeIds = {}
    for typeId in pairs(expectedDefinitions) do
        table.insert(typeIds, typeId)
    end
    table.sort(typeIds)

    for _, typeId in ipairs(typeIds) do
        local openDirections = expectedDefinitions[typeId]
        local definition = prefabs.getDefinition(typeId)
        assert(definition ~= nil, string.format('%s should be a known prefab type', typeId))
        assert(
            #definition.OpenDirections == #openDirections,
            string.format('%s should preserve expected doorway count', typeId)
        )

        local classified = prefabs.classifyDoorDirections(openDirections)
        assert(classified ~= nil, string.format('%s should classify from canonical edges', typeId))
        assert(classified.TypeId == typeId, string.format('%s should classify to itself', typeId))

        for _, steps in ipairs(expectedRotationSteps[typeId]) do
            local rotatedDirections = {}
            for _, directionIndex in ipairs(openDirections) do
                table.insert(rotatedDirections, rotate(directionIndex, steps))
            end
            local rotatedClassified = prefabs.classifyDoorDirections(rotatedDirections)
            assert(
                rotatedClassified and rotatedClassified.TypeId == typeId,
                string.format('%s should classify correctly under rotation step %d', typeId, steps)
            )
        end
    end

    local mask = prefabs.computeDoorMask({ 1, 3, 6 })
    local directions = prefabs.maskToDirections(mask)
    assert(#directions == 3, 'Door mask conversion should preserve direction count')
    assert(
        directions[1] == 1 and directions[2] == 3 and directions[3] == 6,
        'Mask roundtrip should be stable'
    )

    local unsupported = prefabs.classifyDoorDirections({ 1, 2, 3, 4, 5 })
    assert(unsupported == nil, 'Five-door patterns should stay outside T1-T8 prefabs')
end
