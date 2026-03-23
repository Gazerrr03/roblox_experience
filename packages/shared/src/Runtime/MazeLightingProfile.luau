local MazeLightingProfile = {}

local EFFECT_NAMES = table.freeze({
    Atmosphere = 'MazeAtmosphere',
    ColorCorrection = 'MazeColorCorrection',
    Bloom = 'MazeBloom',
    DepthOfField = 'MazeDepthOfField',
})

local FUTURE_SETTINGS = table.freeze({
    Brightness = 2,
    ClockTime = 1.25,
    ExposureCompensation = -0.4,
    ShadowSoftness = 0.35,
    Ambient = Color3.fromRGB(8, 10, 14),
    OutdoorAmbient = Color3.fromRGB(30, 34, 40),
    EnvironmentDiffuseScale = 0.3,
    EnvironmentSpecularScale = 0.2,
    AtmosphereColor = Color3.fromRGB(92, 100, 112),
    AtmosphereDecay = Color3.fromRGB(14, 16, 20),
    AtmosphereDensity = 0.38,
    AtmosphereGlare = 0.05,
    AtmosphereHaze = 1.75,
    AtmosphereOffset = -0.2,
    ColorCorrectionBrightness = -0.03,
    ColorCorrectionContrast = 0.16,
    ColorCorrectionSaturation = -0.12,
    ColorCorrectionTintColor = Color3.fromRGB(214, 223, 255),
    BloomIntensity = 0.18,
    BloomSize = 28,
    BloomThreshold = 1.35,
    DepthOfFieldFarIntensity = 0.08,
    DepthOfFieldFocusDistance = 30,
    DepthOfFieldInFocusRadius = 18,
    DepthOfFieldNearIntensity = 0.12,
})

local FALLBACK_SETTINGS = table.freeze({
    Brightness = 2.6,
    ClockTime = 1.75,
    ExposureCompensation = 0.1,
    ShadowSoftness = 0.2,
    Ambient = Color3.fromRGB(52, 58, 68),
    OutdoorAmbient = Color3.fromRGB(76, 82, 92),
    EnvironmentDiffuseScale = 0.5,
    EnvironmentSpecularScale = 0.25,
    AtmosphereColor = Color3.fromRGB(110, 118, 130),
    AtmosphereDecay = Color3.fromRGB(42, 46, 54),
    AtmosphereDensity = 0.12,
    AtmosphereGlare = 0,
    AtmosphereHaze = 0.85,
    AtmosphereOffset = 0,
    ColorCorrectionBrightness = 0.03,
    ColorCorrectionContrast = 0.06,
    ColorCorrectionSaturation = -0.05,
    ColorCorrectionTintColor = Color3.fromRGB(226, 232, 244),
    BloomIntensity = 0.1,
    BloomSize = 24,
    BloomThreshold = 1.55,
    DepthOfFieldFarIntensity = 0,
    DepthOfFieldFocusDistance = 60,
    DepthOfFieldInFocusRadius = 80,
    DepthOfFieldNearIntensity = 0,
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

local function applyTechnology(lighting, options)
    local writer = options and options.ApplyTechnology
    if writer == nil then
        writer = function(targetLighting, technology)
            targetLighting.Technology = technology
        end
    end

    local ok, err = pcall(writer, lighting, Enum.Technology.Future)
    if ok then
        return true, nil
    end

    return false, tostring(err)
end

function MazeLightingProfile.apply(lighting, options)
    local technologyApplied, technologyError = applyTechnology(lighting, options)
    local settings = if technologyApplied then FUTURE_SETTINGS else FALLBACK_SETTINGS

    lighting.GlobalShadows = true
    lighting.Brightness = settings.Brightness
    lighting.ClockTime = settings.ClockTime
    lighting.ExposureCompensation = settings.ExposureCompensation
    lighting.ShadowSoftness = settings.ShadowSoftness
    lighting.Ambient = settings.Ambient
    lighting.OutdoorAmbient = settings.OutdoorAmbient
    lighting.EnvironmentDiffuseScale = settings.EnvironmentDiffuseScale
    lighting.EnvironmentSpecularScale = settings.EnvironmentSpecularScale

    local atmosphere = ensureEffect(lighting, 'Atmosphere', EFFECT_NAMES.Atmosphere)
    atmosphere.Color = settings.AtmosphereColor
    atmosphere.Decay = settings.AtmosphereDecay
    atmosphere.Density = settings.AtmosphereDensity
    atmosphere.Glare = settings.AtmosphereGlare
    atmosphere.Haze = settings.AtmosphereHaze
    atmosphere.Offset = settings.AtmosphereOffset

    local colorCorrection =
        ensureEffect(lighting, 'ColorCorrectionEffect', EFFECT_NAMES.ColorCorrection)
    colorCorrection.Brightness = settings.ColorCorrectionBrightness
    colorCorrection.Contrast = settings.ColorCorrectionContrast
    colorCorrection.Saturation = settings.ColorCorrectionSaturation
    colorCorrection.TintColor = settings.ColorCorrectionTintColor

    local bloom = ensureEffect(lighting, 'BloomEffect', EFFECT_NAMES.Bloom)
    bloom.Intensity = settings.BloomIntensity
    bloom.Size = settings.BloomSize
    bloom.Threshold = settings.BloomThreshold

    local depthOfField = ensureEffect(lighting, 'DepthOfFieldEffect', EFFECT_NAMES.DepthOfField)
    depthOfField.FarIntensity = settings.DepthOfFieldFarIntensity
    depthOfField.FocusDistance = settings.DepthOfFieldFocusDistance
    depthOfField.InFocusRadius = settings.DepthOfFieldInFocusRadius
    depthOfField.NearIntensity = settings.DepthOfFieldNearIntensity

    return {
        TechnologyApplied = technologyApplied,
        TechnologyError = technologyError,
        Atmosphere = atmosphere,
        ColorCorrection = colorCorrection,
        Bloom = bloom,
        DepthOfField = depthOfField,
    }
end

return MazeLightingProfile
