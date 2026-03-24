local MazeLightingProfile = {}

local EFFECT_NAMES = table.freeze({
    Atmosphere = 'MazeAtmosphere',
    ColorCorrection = 'MazeColorCorrection',
    Bloom = 'MazeBloom',
    DepthOfField = 'MazeDepthOfField',
})

MazeLightingProfile.SurfacePalette = table.freeze({
    WallColor = Color3.fromRGB(84, 88, 94),
    WallMaterial = Enum.Material.Slate,
    FloorColor = Color3.fromRGB(56, 60, 64),
    FloorMaterial = Enum.Material.Basalt,
    CeilingColor = Color3.fromRGB(42, 45, 50),
    CeilingMaterial = Enum.Material.Basalt,
    DoorColor = Color3.fromRGB(69, 73, 78),
    DoorMaterial = Enum.Material.Metal,
    ExitFloorColor = Color3.fromRGB(92, 74, 58),
    ExitFloorMaterial = Enum.Material.Slate,
})

local function ensureEffect(parent, className, name)
    local existing = parent:FindFirstChild(name)
    if existing and not existing:IsA(className) then
        existing:Destroy()
        existing = nil
    end

    if existing == nil then
        existing = Instance.new(className)
        existing.Name = name
        existing.Parent = parent
    end

    return existing
end

local function applyProperty(target, propertyPath, propertyName, value, skippedProperties)
    local ok, err = pcall(function()
        target[propertyName] = value
    end)

    if ok then
        return true
    end

    skippedProperties[propertyPath] = tostring(err)
    return false
end

function MazeLightingProfile.apply(lighting)
    local skippedProperties = {}

    applyProperty(
        lighting,
        'Lighting.Technology',
        'Technology',
        Enum.Technology.Future,
        skippedProperties
    )
    applyProperty(lighting, 'Lighting.GlobalShadows', 'GlobalShadows', true, skippedProperties)
    applyProperty(lighting, 'Lighting.Brightness', 'Brightness', 2, skippedProperties)
    applyProperty(lighting, 'Lighting.ClockTime', 'ClockTime', 1.25, skippedProperties)
    applyProperty(
        lighting,
        'Lighting.ExposureCompensation',
        'ExposureCompensation',
        -0.4,
        skippedProperties
    )
    applyProperty(lighting, 'Lighting.ShadowSoftness', 'ShadowSoftness', 0.35, skippedProperties)
    applyProperty(
        lighting,
        'Lighting.Ambient',
        'Ambient',
        Color3.fromRGB(8, 10, 14),
        skippedProperties
    )
    applyProperty(
        lighting,
        'Lighting.OutdoorAmbient',
        'OutdoorAmbient',
        Color3.fromRGB(30, 34, 40),
        skippedProperties
    )
    applyProperty(
        lighting,
        'Lighting.EnvironmentDiffuseScale',
        'EnvironmentDiffuseScale',
        0.3,
        skippedProperties
    )
    applyProperty(
        lighting,
        'Lighting.EnvironmentSpecularScale',
        'EnvironmentSpecularScale',
        0.2,
        skippedProperties
    )

    local atmosphere = ensureEffect(lighting, 'Atmosphere', EFFECT_NAMES.Atmosphere)
    applyProperty(
        atmosphere,
        'MazeAtmosphere.Color',
        'Color',
        Color3.fromRGB(92, 100, 112),
        skippedProperties
    )
    applyProperty(
        atmosphere,
        'MazeAtmosphere.Decay',
        'Decay',
        Color3.fromRGB(14, 16, 20),
        skippedProperties
    )
    applyProperty(atmosphere, 'MazeAtmosphere.Density', 'Density', 0.38, skippedProperties)
    applyProperty(atmosphere, 'MazeAtmosphere.Glare', 'Glare', 0.05, skippedProperties)
    applyProperty(atmosphere, 'MazeAtmosphere.Haze', 'Haze', 1.75, skippedProperties)
    applyProperty(atmosphere, 'MazeAtmosphere.Offset', 'Offset', -0.2, skippedProperties)

    local colorCorrection =
        ensureEffect(lighting, 'ColorCorrectionEffect', EFFECT_NAMES.ColorCorrection)
    applyProperty(
        colorCorrection,
        'MazeColorCorrection.Brightness',
        'Brightness',
        -0.03,
        skippedProperties
    )
    applyProperty(
        colorCorrection,
        'MazeColorCorrection.Contrast',
        'Contrast',
        0.16,
        skippedProperties
    )
    applyProperty(
        colorCorrection,
        'MazeColorCorrection.Saturation',
        'Saturation',
        -0.12,
        skippedProperties
    )
    applyProperty(
        colorCorrection,
        'MazeColorCorrection.TintColor',
        'TintColor',
        Color3.fromRGB(214, 223, 255),
        skippedProperties
    )

    local bloom = ensureEffect(lighting, 'BloomEffect', EFFECT_NAMES.Bloom)
    applyProperty(bloom, 'MazeBloom.Intensity', 'Intensity', 0.18, skippedProperties)
    applyProperty(bloom, 'MazeBloom.Size', 'Size', 28, skippedProperties)
    applyProperty(bloom, 'MazeBloom.Threshold', 'Threshold', 1.35, skippedProperties)

    local depthOfField = ensureEffect(lighting, 'DepthOfFieldEffect', EFFECT_NAMES.DepthOfField)
    applyProperty(
        depthOfField,
        'MazeDepthOfField.FarIntensity',
        'FarIntensity',
        0.08,
        skippedProperties
    )
    applyProperty(
        depthOfField,
        'MazeDepthOfField.FocusDistance',
        'FocusDistance',
        30,
        skippedProperties
    )
    applyProperty(
        depthOfField,
        'MazeDepthOfField.InFocusRadius',
        'InFocusRadius',
        18,
        skippedProperties
    )
    applyProperty(
        depthOfField,
        'MazeDepthOfField.NearIntensity',
        'NearIntensity',
        0.12,
        skippedProperties
    )

    return {
        Atmosphere = atmosphere,
        ColorCorrection = colorCorrection,
        Bloom = bloom,
        DepthOfField = depthOfField,
        SkippedProperties = skippedProperties,
    }
end

return MazeLightingProfile
