local MazePassageTemplates = {}

MazePassageTemplates.EndpointType = table.freeze({
    Hall = 'hall',
    Service = 'service',
    Bulkhead = 'bulkhead',
    Exit = 'exit',
})

local function freezeList(values)
    return table.freeze(values)
end

local DEFINITIONS_BY_ID = {
    IndustrialHall = table.freeze({
        Id = 'IndustrialHall',
        EndpointType = MazePassageTemplates.EndpointType.Hall,
        Width = 6,
        Height = 14,
        WallThicknessMultiplier = 1,
        AccentColor = Color3.fromRGB(118, 124, 132),
    }),
    ServiceSpine = table.freeze({
        Id = 'ServiceSpine',
        EndpointType = MazePassageTemplates.EndpointType.Service,
        Width = 5,
        Height = 13,
        WallThicknessMultiplier = 0.9,
        AccentColor = Color3.fromRGB(96, 134, 158),
    }),
    BulkheadConnector = table.freeze({
        Id = 'BulkheadConnector',
        EndpointType = MazePassageTemplates.EndpointType.Bulkhead,
        Width = 7,
        Height = 14,
        WallThicknessMultiplier = 1.35,
        AccentColor = Color3.fromRGB(154, 120, 84),
    }),
    ExitSpur = table.freeze({
        Id = 'ExitSpur',
        EndpointType = MazePassageTemplates.EndpointType.Exit,
        Width = 6,
        Height = 14,
        WallThicknessMultiplier = 1.05,
        AccentColor = Color3.fromRGB(112, 136, 154),
    }),
}

local ALLOWED_ENDPOINT_TYPES = table.freeze({
    [MazePassageTemplates.EndpointType.Hall] = freezeList({
        MazePassageTemplates.EndpointType.Hall,
        MazePassageTemplates.EndpointType.Service,
        MazePassageTemplates.EndpointType.Bulkhead,
        MazePassageTemplates.EndpointType.Exit,
    }),
    [MazePassageTemplates.EndpointType.Service] = freezeList({
        MazePassageTemplates.EndpointType.Hall,
        MazePassageTemplates.EndpointType.Service,
        MazePassageTemplates.EndpointType.Bulkhead,
    }),
    [MazePassageTemplates.EndpointType.Bulkhead] = freezeList({
        MazePassageTemplates.EndpointType.Hall,
        MazePassageTemplates.EndpointType.Service,
        MazePassageTemplates.EndpointType.Bulkhead,
    }),
    [MazePassageTemplates.EndpointType.Exit] = freezeList({
        MazePassageTemplates.EndpointType.Hall,
        MazePassageTemplates.EndpointType.Service,
        MazePassageTemplates.EndpointType.Bulkhead,
    }),
})

function MazePassageTemplates.getDefinition(archetypeId)
    return DEFINITIONS_BY_ID[archetypeId]
end

function MazePassageTemplates.getAllowedEndpointTypes(endpointType)
    return ALLOWED_ENDPOINT_TYPES[endpointType] or ALLOWED_ENDPOINT_TYPES.hall
end

function MazePassageTemplates.resolveDoorwayArchetype(roomA, roomB, isLoopDoorway)
    if roomA.RoomCategory == 'BulkheadGate' or roomB.RoomCategory == 'BulkheadGate' then
        return DEFINITIONS_BY_ID.BulkheadConnector
    end

    if
        roomA.RoomCategory == 'LandmarkFacility'
        or roomB.RoomCategory == 'LandmarkFacility'
        or roomA.RoomCategory == 'ShortcutLoop'
        or roomB.RoomCategory == 'ShortcutLoop'
        or isLoopDoorway == true
    then
        return DEFINITIONS_BY_ID.ServiceSpine
    end

    return DEFINITIONS_BY_ID.IndustrialHall
end

function MazePassageTemplates.resolveExternalArchetype(_room)
    return DEFINITIONS_BY_ID.ExitSpur
end

return MazePassageTemplates
