local MazeRoomTemplates = require(script.Parent.MazeRoomTemplates)

local MazeRoomArchetypes = {}

local DEFINITIONS_BY_ID = {
    EntrySafe = table.freeze({
        Id = 'EntrySafe',
        DisplayName = 'Entry Safe',
        GeometryMode = 'FacilityBlockout',
        AuthoringAssetId = 'EntrySafe',
        SupportsExternalShellModel = true,
        VisualLanguage = 'SafeEntry',
    }),
    TransitHall = table.freeze({
        Id = 'TransitHall',
        DisplayName = 'Transit Hall',
        GeometryMode = 'FacilityBlockout',
        AuthoringAssetId = 'TransitHall',
        SupportsExternalShellModel = true,
        VisualLanguage = 'IndustrialTransit',
    }),
    SearchCluster = table.freeze({
        Id = 'SearchCluster',
        DisplayName = 'Search Cluster',
        GeometryMode = 'FacilityBlockout',
        AuthoringAssetId = 'SearchCluster',
        SupportsExternalShellModel = true,
        VisualLanguage = 'SearchableIndustrial',
    }),
    HighValueRisk = table.freeze({
        Id = 'HighValueRisk',
        DisplayName = 'High Value Risk',
        GeometryMode = 'FacilityBlockout',
        AuthoringAssetId = 'HighValueRisk',
        SupportsExternalShellModel = true,
        VisualLanguage = 'HighRiskVault',
    }),
    LandmarkFacility = table.freeze({
        Id = 'LandmarkFacility',
        DisplayName = 'Landmark Facility',
        GeometryMode = 'FacilityBlockout',
        AuthoringAssetId = 'LandmarkFacility',
        SupportsExternalShellModel = true,
        VisualLanguage = 'NavigationAnchor',
    }),
    ExtractionReturn = table.freeze({
        Id = 'ExtractionReturn',
        DisplayName = 'Extraction Return',
        GeometryMode = 'FacilityBlockout',
        AuthoringAssetId = 'ExtractionReturn',
        SupportsExternalShellModel = true,
        VisualLanguage = 'Extraction',
    }),
    BulkheadGate = table.freeze({
        Id = 'BulkheadGate',
        DisplayName = 'Bulkhead Gate',
        GeometryMode = 'FacilityBlockout',
        AuthoringAssetId = 'BulkheadGate',
        SupportsExternalShellModel = true,
        VisualLanguage = 'BulkheadThreshold',
    }),
    ShortcutLoop = table.freeze({
        Id = 'ShortcutLoop',
        DisplayName = 'Shortcut Loop',
        GeometryMode = 'FacilityBlockout',
        AuthoringAssetId = 'ShortcutLoop',
        SupportsExternalShellModel = true,
        VisualLanguage = 'LoopUtility',
    }),
}

local LEGACY_FALLBACKS = table.freeze({
    Camp = 'EntrySafe',
    Extraction = 'ExtractionReturn',
})

function MazeRoomArchetypes.getDefinition(archetypeId)
    return DEFINITIONS_BY_ID[archetypeId]
end

function MazeRoomArchetypes.classifyRoom(room)
    local templateId = room.RoomTemplateId
        or LEGACY_FALLBACKS[room.Kind]
        or (room.DoorCount <= 2 and 'SearchCluster' or 'TransitHall')

    local template = MazeRoomTemplates.getDefinition(templateId)
    local archetypeId = template and template.Id or 'SearchCluster'
    return DEFINITIONS_BY_ID[archetypeId]
end

return MazeRoomArchetypes
