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

function MazeLightingProfile.apply(lighting)
    lighting.Technology = Enum.Technology.Future
    lighting.GlobalShadows = true
    lighting.Brightness = 2
    lighting.ClockTime = 1.25
    lighting.ExposureCompensation = -0.4
    lighting.ShadowSoftness = 0.35
    lighting.Ambient = Color3.fromRGB(8, 10, 14)
    lighting.OutdoorAmbient = Color3.fromRGB(30, 34, 40)
    lighting.EnvironmentDiffuseScale = 0.3
    lighting.EnvironmentSpecularScale = 0.2

    local atmosphere = ensureEffect(lighting, 'Atmosphere', EFFECT_NAMES.Atmosphere)
    atmosphere.Color = Color3.fromRGB(92, 100, 112)
    atmosphere.Decay = Color3.fromRGB(14, 16, 20)
    atmosphere.Density = 0.38
    atmosphere.Glare = 0.05
    atmosphere.Haze = 1.75
    atmosphere.Offset = -0.2

    local colorCorrection =
        ensureEffect(lighting, 'ColorCorrectionEffect', EFFECT_NAMES.ColorCorrection)
    colorCorrection.Brightness = -0.03
    colorCorrection.Contrast = 0.16
    colorCorrection.Saturation = -0.12
    colorCorrection.TintColor = Color3.fromRGB(214, 223, 255)

    local bloom = ensureEffect(lighting, 'BloomEffect', EFFECT_NAMES.Bloom)
    bloom.Intensity = 0.18
    bloom.Size = 28
    bloom.Threshold = 1.35

    local depthOfField = ensureEffect(lighting, 'DepthOfFieldEffect', EFFECT_NAMES.DepthOfField)
    depthOfField.FarIntensity = 0.08
    depthOfField.FocusDistance = 30
    depthOfField.InFocusRadius = 18
    depthOfField.NearIntensity = 0.12

    return {
        Atmosphere = atmosphere,
        ColorCorrection = colorCorrection,
        Bloom = bloom,
        DepthOfField = depthOfField,
    }
end

return MazeLightingProfile
