local MazeLightingProfile = {}

local EFFECT_NAMES = table.freeze({
    Atmosphere = 'MazeAtmosphere',
    ColorCorrection = 'MazeColorCorrection',
    Bloom = 'MazeBloom',
    DepthOfField = 'MazeDepthOfField',
})

local FUTURE_SURFACE_PALETTE = table.freeze({
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

local FALLBACK_SURFACE_PALETTE = table.freeze({
    WallColor = Color3.fromRGB(106, 112, 120),
    WallMaterial = Enum.Material.Slate,
    FloorColor = Color3.fromRGB(82, 88, 96),
    FloorMaterial = Enum.Material.Basalt,
    CeilingColor = Color3.fromRGB(68, 74, 82),
    CeilingMaterial = Enum.Material.Basalt,
    DoorColor = Color3.fromRGB(92, 98, 106),
    DoorMaterial = Enum.Material.Metal,
    ExitFloorColor = Color3.fromRGB(112, 92, 74),
    ExitFloorMaterial = Enum.Material.Slate,
})

MazeLightingProfile.SurfacePalette = FUTURE_SURFACE_PALETTE
MazeLightingProfile.FallbackSurfacePalette = FALLBACK_SURFACE_PALETTE
MazeLightingProfile.ProfileName = table.freeze({
    Future = 'Future',
    FallbackReadable = 'FallbackReadable',
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

local function defaultPropertySetter(target, propertyName, value)
    target[propertyName] = value
end

local function applyProperty(
    target,
    propertyPath,
    propertyName,
    value,
    skippedProperties,
    propertySetter
)
    local ok, err = pcall(function()
        propertySetter(target, propertyName, value)
    end)

    if ok then
        return true
    end

    skippedProperties[propertyPath] = tostring(err)
    return false
end

local function applyLightingProperties(lighting, properties, skippedProperties, propertySetter)
    for _, propertyConfig in ipairs(properties) do
        applyProperty(
            lighting,
            propertyConfig.Path,
            propertyConfig.Name,
            propertyConfig.Value,
            skippedProperties,
            propertySetter
        )
    end
end

local function applyEffectProperties(effect, properties, skippedProperties, propertySetter)
    for _, propertyConfig in ipairs(properties) do
        applyProperty(
            effect,
            propertyConfig.Path,
            propertyConfig.Name,
            propertyConfig.Value,
            skippedProperties,
            propertySetter
        )
    end
end

local LIGHTING_PROPERTIES_BY_PROFILE = table.freeze({
    Future = table.freeze({
        { Path = 'Lighting.GlobalShadows', Name = 'GlobalShadows', Value = true },
        { Path = 'Lighting.Brightness', Name = 'Brightness', Value = 2 },
        { Path = 'Lighting.ClockTime', Name = 'ClockTime', Value = 1.25 },
        {
            Path = 'Lighting.ExposureCompensation',
            Name = 'ExposureCompensation',
            Value = -0.4,
        },
        { Path = 'Lighting.ShadowSoftness', Name = 'ShadowSoftness', Value = 0.35 },
        { Path = 'Lighting.Ambient', Name = 'Ambient', Value = Color3.fromRGB(8, 10, 14) },
        {
            Path = 'Lighting.OutdoorAmbient',
            Name = 'OutdoorAmbient',
            Value = Color3.fromRGB(30, 34, 40),
        },
        {
            Path = 'Lighting.EnvironmentDiffuseScale',
            Name = 'EnvironmentDiffuseScale',
            Value = 0.3,
        },
        {
            Path = 'Lighting.EnvironmentSpecularScale',
            Name = 'EnvironmentSpecularScale',
            Value = 0.2,
        },
    }),
    FallbackReadable = table.freeze({
        { Path = 'Lighting.GlobalShadows', Name = 'GlobalShadows', Value = true },
        { Path = 'Lighting.Brightness', Name = 'Brightness', Value = 3.1 },
        { Path = 'Lighting.ClockTime', Name = 'ClockTime', Value = 2.4 },
        {
            Path = 'Lighting.ExposureCompensation',
            Name = 'ExposureCompensation',
            Value = 0.1,
        },
        { Path = 'Lighting.ShadowSoftness', Name = 'ShadowSoftness', Value = 0.2 },
        { Path = 'Lighting.Ambient', Name = 'Ambient', Value = Color3.fromRGB(22, 26, 32) },
        {
            Path = 'Lighting.OutdoorAmbient',
            Name = 'OutdoorAmbient',
            Value = Color3.fromRGB(62, 68, 78),
        },
        {
            Path = 'Lighting.EnvironmentDiffuseScale',
            Name = 'EnvironmentDiffuseScale',
            Value = 0.5,
        },
        {
            Path = 'Lighting.EnvironmentSpecularScale',
            Name = 'EnvironmentSpecularScale',
            Value = 0.15,
        },
    }),
})

local ATMOSPHERE_PROPERTIES_BY_PROFILE = table.freeze({
    Future = table.freeze({
        {
            Path = 'MazeAtmosphere.Color',
            Name = 'Color',
            Value = Color3.fromRGB(92, 100, 112),
        },
        {
            Path = 'MazeAtmosphere.Decay',
            Name = 'Decay',
            Value = Color3.fromRGB(14, 16, 20),
        },
        { Path = 'MazeAtmosphere.Density', Name = 'Density', Value = 0.38 },
        { Path = 'MazeAtmosphere.Glare', Name = 'Glare', Value = 0.05 },
        { Path = 'MazeAtmosphere.Haze', Name = 'Haze', Value = 1.75 },
        { Path = 'MazeAtmosphere.Offset', Name = 'Offset', Value = -0.2 },
    }),
    FallbackReadable = table.freeze({
        {
            Path = 'MazeAtmosphere.Color',
            Name = 'Color',
            Value = Color3.fromRGB(108, 118, 132),
        },
        {
            Path = 'MazeAtmosphere.Decay',
            Name = 'Decay',
            Value = Color3.fromRGB(30, 34, 40),
        },
        { Path = 'MazeAtmosphere.Density', Name = 'Density', Value = 0.18 },
        { Path = 'MazeAtmosphere.Glare', Name = 'Glare', Value = 0.03 },
        { Path = 'MazeAtmosphere.Haze', Name = 'Haze', Value = 0.8 },
        { Path = 'MazeAtmosphere.Offset', Name = 'Offset', Value = -0.05 },
    }),
})

local COLOR_CORRECTION_PROPERTIES_BY_PROFILE = table.freeze({
    Future = table.freeze({
        {
            Path = 'MazeColorCorrection.Brightness',
            Name = 'Brightness',
            Value = -0.03,
        },
        { Path = 'MazeColorCorrection.Contrast', Name = 'Contrast', Value = 0.16 },
        { Path = 'MazeColorCorrection.Saturation', Name = 'Saturation', Value = -0.12 },
        {
            Path = 'MazeColorCorrection.TintColor',
            Name = 'TintColor',
            Value = Color3.fromRGB(214, 223, 255),
        },
    }),
    FallbackReadable = table.freeze({
        {
            Path = 'MazeColorCorrection.Brightness',
            Name = 'Brightness',
            Value = 0.03,
        },
        { Path = 'MazeColorCorrection.Contrast', Name = 'Contrast', Value = 0.08 },
        { Path = 'MazeColorCorrection.Saturation', Name = 'Saturation', Value = -0.08 },
        {
            Path = 'MazeColorCorrection.TintColor',
            Name = 'TintColor',
            Value = Color3.fromRGB(220, 228, 255),
        },
    }),
})

local BLOOM_PROPERTIES = table.freeze({
    { Path = 'MazeBloom.Intensity', Name = 'Intensity', Value = 0.18 },
    { Path = 'MazeBloom.Size', Name = 'Size', Value = 28 },
    { Path = 'MazeBloom.Threshold', Name = 'Threshold', Value = 1.35 },
})

local DEPTH_OF_FIELD_PROPERTIES = table.freeze({
    { Path = 'MazeDepthOfField.FarIntensity', Name = 'FarIntensity', Value = 0.08 },
    { Path = 'MazeDepthOfField.FocusDistance', Name = 'FocusDistance', Value = 30 },
    { Path = 'MazeDepthOfField.InFocusRadius', Name = 'InFocusRadius', Value = 18 },
    { Path = 'MazeDepthOfField.NearIntensity', Name = 'NearIntensity', Value = 0.12 },
})

function MazeLightingProfile.apply(lighting, options)
    local runtimeOptions = options or {}
    local skippedProperties = {}
    local propertySetter = runtimeOptions.PropertySetter or defaultPropertySetter
    local technologyApplied = applyProperty(
        lighting,
        'Lighting.Technology',
        'Technology',
        Enum.Technology.Future,
        skippedProperties,
        propertySetter
    )
    local appliedProfile = (
        if technologyApplied
            then MazeLightingProfile.ProfileName.Future
            else MazeLightingProfile.ProfileName.FallbackReadable
    )

    applyLightingProperties(
        lighting,
        LIGHTING_PROPERTIES_BY_PROFILE[appliedProfile],
        skippedProperties,
        propertySetter
    )

    local atmosphere = ensureEffect(lighting, 'Atmosphere', EFFECT_NAMES.Atmosphere)
    applyEffectProperties(
        atmosphere,
        ATMOSPHERE_PROPERTIES_BY_PROFILE[appliedProfile],
        skippedProperties,
        propertySetter
    )

    local colorCorrection =
        ensureEffect(lighting, 'ColorCorrectionEffect', EFFECT_NAMES.ColorCorrection)
    applyEffectProperties(
        colorCorrection,
        COLOR_CORRECTION_PROPERTIES_BY_PROFILE[appliedProfile],
        skippedProperties,
        propertySetter
    )

    local bloom = ensureEffect(lighting, 'BloomEffect', EFFECT_NAMES.Bloom)
    applyEffectProperties(bloom, BLOOM_PROPERTIES, skippedProperties, propertySetter)

    local depthOfField = ensureEffect(lighting, 'DepthOfFieldEffect', EFFECT_NAMES.DepthOfField)
    applyEffectProperties(
        depthOfField,
        DEPTH_OF_FIELD_PROPERTIES,
        skippedProperties,
        propertySetter
    )

    return {
        Atmosphere = atmosphere,
        ColorCorrection = colorCorrection,
        Bloom = bloom,
        DepthOfField = depthOfField,
        TechnologyApplied = technologyApplied,
        TechnologyError = skippedProperties['Lighting.Technology'],
        AppliedProfile = appliedProfile,
        SurfacePalette = (
            if technologyApplied
                then MazeLightingProfile.SurfacePalette
                else MazeLightingProfile.FallbackSurfacePalette
        ),
        SkippedProperties = skippedProperties,
    }
end

return MazeLightingProfile
