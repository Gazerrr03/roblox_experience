local MazePassageTemplates = require(script.Parent.MazePassageTemplates)

local MazeRoomTemplates = {}

local function freezeRange(minDepth, maxDepth)
    return table.freeze({
        Min = minDepth,
        Max = maxDepth,
    })
end

local function freezeProfile(mode, lootBias, pressure, affordance)
    return table.freeze({
        Mode = mode,
        LootBias = lootBias,
        Pressure = pressure,
        Affordance = affordance,
    })
end

local DEFINITIONS_BY_ID = {
    EntrySafe = table.freeze({
        Id = 'EntrySafe',
        Category = 'EntrySafe',
        DisplayName = 'Entry Safe Room',
        SearchProfile = freezeProfile('staging', 'low', 'low', 'orientation'),
        RiskTier = 0,
        LandmarkWeight = 3,
        AllowedDepthBand = freezeRange(0, 0.15),
        SupportsExternalShellModel = true,
        EndpointType = MazePassageTemplates.EndpointType.Hall,
        WidthClass = 'Wide',
        HeightClass = 'Tall',
        AuthoringAssetId = 'EntrySafe',
    }),
    TransitHall = table.freeze({
        Id = 'TransitHall',
        Category = 'TransitHall',
        DisplayName = 'Transit Hall',
        SearchProfile = freezeProfile('transit', 'low', 'low', 'route_choice'),
        RiskTier = 1,
        LandmarkWeight = 1,
        AllowedDepthBand = freezeRange(0.1, 0.9),
        SupportsExternalShellModel = true,
        EndpointType = MazePassageTemplates.EndpointType.Hall,
        WidthClass = 'Standard',
        HeightClass = 'Standard',
        AuthoringAssetId = 'TransitHall',
    }),
    SearchCluster = table.freeze({
        Id = 'SearchCluster',
        Category = 'SearchCluster',
        DisplayName = 'Search Cluster',
        SearchProfile = freezeProfile('search', 'medium', 'medium', 'room_sweep'),
        RiskTier = 2,
        LandmarkWeight = 1,
        AllowedDepthBand = freezeRange(0.15, 0.95),
        SupportsExternalShellModel = true,
        EndpointType = MazePassageTemplates.EndpointType.Hall,
        WidthClass = 'Standard',
        HeightClass = 'Standard',
        AuthoringAssetId = 'SearchCluster',
    }),
    HighValueRisk = table.freeze({
        Id = 'HighValueRisk',
        Category = 'HighValueRisk',
        DisplayName = 'High Value Risk Room',
        SearchProfile = freezeProfile('high_value', 'high', 'high', 'deep_commit'),
        RiskTier = 4,
        LandmarkWeight = 2,
        AllowedDepthBand = freezeRange(0.55, 1),
        SupportsExternalShellModel = true,
        EndpointType = MazePassageTemplates.EndpointType.Hall,
        WidthClass = 'Narrow',
        HeightClass = 'Standard',
        AuthoringAssetId = 'HighValueRisk',
    }),
    LandmarkFacility = table.freeze({
        Id = 'LandmarkFacility',
        Category = 'LandmarkFacility',
        DisplayName = 'Landmark Facility',
        SearchProfile = freezeProfile('landmark', 'medium', 'medium', 'navigation_anchor'),
        RiskTier = 2,
        LandmarkWeight = 4,
        AllowedDepthBand = freezeRange(0.25, 0.8),
        SupportsExternalShellModel = true,
        EndpointType = MazePassageTemplates.EndpointType.Service,
        WidthClass = 'Wide',
        HeightClass = 'Tall',
        AuthoringAssetId = 'LandmarkFacility',
    }),
    ExtractionReturn = table.freeze({
        Id = 'ExtractionReturn',
        Category = 'ExtractionReturn',
        DisplayName = 'Extraction Return Room',
        SearchProfile = freezeProfile('return', 'low', 'high', 'homeward_decision'),
        RiskTier = 3,
        LandmarkWeight = 3,
        AllowedDepthBand = freezeRange(0.65, 1),
        SupportsExternalShellModel = true,
        EndpointType = MazePassageTemplates.EndpointType.Service,
        WidthClass = 'Wide',
        HeightClass = 'Tall',
        AuthoringAssetId = 'ExtractionReturn',
    }),
    BulkheadGate = table.freeze({
        Id = 'BulkheadGate',
        Category = 'BulkheadGate',
        DisplayName = 'Bulkhead Gate Room',
        SearchProfile = freezeProfile('gate', 'low', 'high', 'threshold_control'),
        RiskTier = 3,
        LandmarkWeight = 2,
        AllowedDepthBand = freezeRange(0.25, 0.75),
        SupportsExternalShellModel = true,
        EndpointType = MazePassageTemplates.EndpointType.Bulkhead,
        WidthClass = 'Wide',
        HeightClass = 'Standard',
        AuthoringAssetId = 'BulkheadGate',
    }),
    ShortcutLoop = table.freeze({
        Id = 'ShortcutLoop',
        Category = 'ShortcutLoop',
        DisplayName = 'Shortcut Loop Room',
        SearchProfile = freezeProfile('shortcut', 'medium', 'medium', 'repathing'),
        RiskTier = 2,
        LandmarkWeight = 2,
        AllowedDepthBand = freezeRange(0.2, 0.85),
        SupportsExternalShellModel = true,
        EndpointType = MazePassageTemplates.EndpointType.Service,
        WidthClass = 'Standard',
        HeightClass = 'Standard',
        AuthoringAssetId = 'ShortcutLoop',
    }),
}

local ORDERED_TEMPLATE_IDS = table.freeze({
    'EntrySafe',
    'TransitHall',
    'SearchCluster',
    'HighValueRisk',
    'LandmarkFacility',
    'ExtractionReturn',
    'BulkheadGate',
    'ShortcutLoop',
})

local function buildEndpointDef(room, definition, directionIndex)
    return {
        Id = string.format('%s_%d', room.Id, directionIndex),
        Direction = directionIndex,
        EndpointType = definition.EndpointType,
        Facing = directionIndex,
        Orientation = 'Outward',
        WidthClass = definition.WidthClass,
        HeightClass = definition.HeightClass,
        IsExternal = false,
        ConnectionRule = {
            AllowedEndpointTypes = MazePassageTemplates.getAllowedEndpointTypes(
                definition.EndpointType
            ),
        },
        PassageArchetypeId = MazePassageTemplates.getDefinition(
            if definition.EndpointType == 'service'
                then 'ServiceSpine'
                else if definition.EndpointType == 'bulkhead'
                    then 'BulkheadConnector'
                    else 'IndustrialHall'
        ).Id,
    }
end

function MazeRoomTemplates.getDefinition(templateId)
    return DEFINITIONS_BY_ID[templateId]
end

function MazeRoomTemplates.getOrderedTemplateIds()
    return ORDERED_TEMPLATE_IDS
end

function MazeRoomTemplates.applyTemplate(room, templateId)
    local definition = DEFINITIONS_BY_ID[templateId]
    if not definition then
        error(string.format('Unknown maze room template: %s', tostring(templateId)), 0)
    end

    room.RoomTemplateId = definition.Id
    room.RoomCategory = definition.Category
    room.SearchProfile = definition.SearchProfile
    room.RiskTier = definition.RiskTier
    room.LandmarkWeight = definition.LandmarkWeight
    room.AllowedDepthBand = definition.AllowedDepthBand
    room.SupportsExternalShellModel = definition.SupportsExternalShellModel == true
    room.AuthoringAssetId = definition.AuthoringAssetId

    return room
end

function MazeRoomTemplates.buildEndpointDefs(room)
    local definition = DEFINITIONS_BY_ID[room.RoomTemplateId]
    if not definition then
        return {}
    end

    local endpointDefs = {}
    local connectedDirections = {}
    for directionIndex in pairs(room.Neighbors or {}) do
        table.insert(connectedDirections, directionIndex)
    end
    table.sort(connectedDirections)

    for _, directionIndex in ipairs(connectedDirections) do
        table.insert(endpointDefs, buildEndpointDef(room, definition, directionIndex))
    end

    table.sort(endpointDefs, function(left, right)
        return left.Direction < right.Direction
    end)

    return endpointDefs
end

return MazeRoomTemplates
