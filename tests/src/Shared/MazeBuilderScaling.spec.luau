local BASE_RATIO_COUNTS = {
    T1 = 4,
    T2 = 5,
    T3 = 2,
    T4 = 2,
    T5 = 3,
    T6 = 2,
    T7 = 1,
    T8 = 1,
}
local RATIO_TYPE_ORDER = { 'T1', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'T8' }

local function computeScaledCounts(roomCount)
    local baseTotal = 0
    for _, typeId in ipairs(RATIO_TYPE_ORDER) do
        baseTotal += BASE_RATIO_COUNTS[typeId]
    end

    local counts = {}
    local remainders = {}
    local assigned = 0

    for _, typeId in ipairs(RATIO_TYPE_ORDER) do
        local scaled = (roomCount * BASE_RATIO_COUNTS[typeId]) / baseTotal
        local baseCount = math.floor(scaled)
        counts[typeId] = baseCount
        assigned += baseCount

        table.insert(remainders, {
            TypeId = typeId,
            Value = scaled - baseCount,
            Weight = BASE_RATIO_COUNTS[typeId],
        })
    end

    table.sort(remainders, function(left, right)
        if left.Value ~= right.Value then
            return left.Value > right.Value
        end
        if left.Weight ~= right.Weight then
            return left.Weight > right.Weight
        end
        return left.TypeId < right.TypeId
    end)

    local remaining = roomCount - assigned
    local remainderIndex = 1
    while remaining > 0 do
        local remainder = remainders[remainderIndex]
        counts[remainder.TypeId] += 1
        remaining -= 1

        remainderIndex += 1
        if remainderIndex > #remainders then
            remainderIndex = 1
        end
    end

    return counts
end

return function()
    local ReplicatedStorage = game:GetService('ReplicatedStorage')
    local gameplay = require(ReplicatedStorage:WaitForChild('Packages'):WaitForChild('Gameplay'))

    local config = {
        RoomCount = 24,
        ExitMin = 2,
        ExitMax = 4,
        RoomSpacing = 40,
        DoorLeafChance = 0.6,
    }
    local maze = gameplay.ProcGen.MazeBuilder.build(54321, config)
    local expectedCounts = computeScaledCounts(config.RoomCount)

    local actualCounts = {}
    local roomCount = 0
    for _, room in pairs(maze.Rooms) do
        roomCount += 1
        actualCounts[room.PrefabTypeId] = (actualCounts[room.PrefabTypeId] or 0) + 1
    end

    assert(roomCount == config.RoomCount, 'Scaled generation should honor custom room count')

    local typeIds = {}
    for typeId in pairs(expectedCounts) do
        table.insert(typeIds, typeId)
    end
    table.sort(typeIds)

    for _, typeId in ipairs(typeIds) do
        local expectedCount = expectedCounts[typeId]
        local actualCount = actualCounts[typeId] or 0
        assert(
            actualCount == expectedCount,
            string.format(
                'Scaled count mismatch for %s: expected %d, got %d',
                typeId,
                expectedCount,
                actualCount
            )
        )
    end

    assert(
        #(maze.ExternalDoorways or {}) == 0,
        'Scaled generation should remain fully indoor and avoid exterior doorways'
    )
    assert(
        maze.MacroGraph.LoopCount >= 1,
        'Scaled generation should still preserve a looping facility skeleton'
    )
    assert(
        #maze.PlacedRooms == config.RoomCount,
        'Scaled generation should keep placed-room metadata in sync with room count'
    )
end
