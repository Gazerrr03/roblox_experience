local MazeRoomArchetypes = {}

local DEFINITIONS_BY_ID = {
    HexStandard = table.freeze({
        Id = 'HexStandard',
        DisplayName = 'Hex Standard',
        GeometryMode = 'HexShell',
        AuthoringAssetId = 'HexStandard',
        SupportsExternalShellModel = true,
        VisualLanguage = 'BrutalistMaze',
    }),
    CavePocket = table.freeze({
        Id = 'CavePocket',
        DisplayName = 'Cave Pocket',
        GeometryMode = 'DecoratedHex',
        AuthoringAssetId = 'CavePocket',
        SupportsExternalShellModel = true,
        VisualLanguage = 'NaturalCave',
    }),
    CampChamber = table.freeze({
        Id = 'CampChamber',
        DisplayName = 'Camp Chamber',
        GeometryMode = 'HexShell',
        AuthoringAssetId = 'CampChamber',
        SupportsExternalShellModel = true,
        VisualLanguage = 'SafeEntry',
    }),
    ExtractionChamber = table.freeze({
        Id = 'ExtractionChamber',
        DisplayName = 'Extraction Chamber',
        GeometryMode = 'HexShell',
        AuthoringAssetId = 'ExtractionChamber',
        SupportsExternalShellModel = true,
        VisualLanguage = 'Extraction',
    }),
}

function MazeRoomArchetypes.getDefinition(archetypeId)
    return DEFINITIONS_BY_ID[archetypeId]
end

function MazeRoomArchetypes.classifyRoom(room)
    if room.Kind == 'Camp' then
        return DEFINITIONS_BY_ID.CampChamber
    end

    if room.Kind == 'Extraction' then
        return DEFINITIONS_BY_ID.ExtractionChamber
    end

    if room.DoorCount <= 2 then
        return DEFINITIONS_BY_ID.CavePocket
    end

    return DEFINITIONS_BY_ID.HexStandard
end

return MazeRoomArchetypes
