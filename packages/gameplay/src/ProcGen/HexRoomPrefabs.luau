local HexRoomPrefabs = {}

HexRoomPrefabs.Directions = table.freeze({
    A = 1,
    B = 2,
    C = 3,
    D = 4,
    E = 5,
    F = 6,
})

HexRoomPrefabs.DirectionBitmasks = table.freeze({ 1, 2, 4, 8, 16, 32 })

local ORDERED_DEFINITIONS = {
    {
        TypeId = 'T1',
        PrefabId = 'Hex_T1_DeadEnd',
        OpenDirections = { HexRoomPrefabs.Directions.B },
        RotationSteps = { 0, 1, 2, 3, 4, 5 },
    },
    {
        TypeId = 'T2',
        PrefabId = 'Hex_T2_Straight',
        OpenDirections = { HexRoomPrefabs.Directions.B, HexRoomPrefabs.Directions.E },
        RotationSteps = { 0, 1, 2 },
    },
    {
        TypeId = 'T3',
        PrefabId = 'Hex_T3_ObtuseTurn',
        OpenDirections = { HexRoomPrefabs.Directions.B, HexRoomPrefabs.Directions.C },
        RotationSteps = { 0, 2, 4 },
    },
    {
        TypeId = 'T4',
        PrefabId = 'Hex_T4_AcuteTurn',
        OpenDirections = { HexRoomPrefabs.Directions.A, HexRoomPrefabs.Directions.B },
        RotationSteps = { 0, 2, 4 },
    },
    {
        TypeId = 'T5',
        PrefabId = 'Hex_T5_SymmetricY',
        OpenDirections = {
            HexRoomPrefabs.Directions.B,
            HexRoomPrefabs.Directions.D,
            HexRoomPrefabs.Directions.F,
        },
        RotationSteps = { 0, 1 },
    },
    {
        TypeId = 'T6',
        PrefabId = 'Hex_T6_T',
        OpenDirections = {
            HexRoomPrefabs.Directions.B,
            HexRoomPrefabs.Directions.C,
            HexRoomPrefabs.Directions.E,
        },
        RotationSteps = { 0, 1, 2, 3, 4, 5 },
    },
    {
        TypeId = 'T7',
        PrefabId = 'Hex_T7_Cross4',
        OpenDirections = {
            HexRoomPrefabs.Directions.A,
            HexRoomPrefabs.Directions.B,
            HexRoomPrefabs.Directions.D,
            HexRoomPrefabs.Directions.E,
        },
        RotationSteps = { 0, 1, 2 },
    },
    {
        TypeId = 'T8',
        PrefabId = 'Hex_T8_OpenHub',
        OpenDirections = {
            HexRoomPrefabs.Directions.A,
            HexRoomPrefabs.Directions.B,
            HexRoomPrefabs.Directions.C,
            HexRoomPrefabs.Directions.D,
            HexRoomPrefabs.Directions.E,
            HexRoomPrefabs.Directions.F,
        },
        RotationSteps = { 0 },
    },
}

local function sortDirections(directions)
    local copy = table.clone(directions)
    table.sort(copy)
    return copy
end

local function directionToMaskBit(directionIndex)
    return bit32.lshift(1, directionIndex - 1)
end

function HexRoomPrefabs.computeDoorMask(directions)
    local mask = 0
    for _, directionIndex in ipairs(directions) do
        mask = bit32.bor(mask, directionToMaskBit(directionIndex))
    end
    return mask
end

function HexRoomPrefabs.maskToDirections(mask)
    local directions = {}
    for directionIndex = 1, 6 do
        if bit32.band(mask, directionToMaskBit(directionIndex)) ~= 0 then
            table.insert(directions, directionIndex)
        end
    end
    return directions
end

local function rotateDirection(directionIndex, steps)
    return ((directionIndex - 1 + steps) % 6) + 1
end

local function rotateDirections(directions, steps)
    local rotated = table.create(#directions)
    for index, directionIndex in ipairs(directions) do
        rotated[index] = rotateDirection(directionIndex, steps)
    end
    table.sort(rotated)
    return rotated
end

local PREFAB_VARIANTS_BY_MASK = {}
local PREFAB_DEFINITIONS_BY_TYPE = {}

for _, definition in ipairs(ORDERED_DEFINITIONS) do
    PREFAB_DEFINITIONS_BY_TYPE[definition.TypeId] = definition

    for _, rotationSteps in ipairs(definition.RotationSteps) do
        local rotatedDirections = rotateDirections(definition.OpenDirections, rotationSteps)
        local doorMask = HexRoomPrefabs.computeDoorMask(rotatedDirections)
        local existing = PREFAB_VARIANTS_BY_MASK[doorMask]
        if not existing then
            PREFAB_VARIANTS_BY_MASK[doorMask] = table.freeze({
                TypeId = definition.TypeId,
                PrefabId = definition.PrefabId,
                RotationSteps = rotationSteps,
                DoorMask = doorMask,
                OpenDirections = table.freeze(rotatedDirections),
            })
        elseif existing.TypeId ~= definition.TypeId then
            error(
                string.format(
                    'Hex prefab mask collision between %s and %s',
                    existing.TypeId,
                    definition.TypeId
                ),
                0
            )
        end
    end
end

function HexRoomPrefabs.classifyDoorMask(doorMask)
    return PREFAB_VARIANTS_BY_MASK[doorMask]
end

function HexRoomPrefabs.classifyDoorDirections(directions)
    local doorMask = HexRoomPrefabs.computeDoorMask(directions)
    return HexRoomPrefabs.classifyDoorMask(doorMask)
end

function HexRoomPrefabs.getDefinition(typeId)
    local definition = PREFAB_DEFINITIONS_BY_TYPE[typeId]
    if not definition then
        return nil
    end

    return table.freeze({
        TypeId = typeId,
        PrefabId = definition.PrefabId,
        OpenDirections = table.freeze(sortDirections(definition.OpenDirections)),
    })
end

return HexRoomPrefabs
