return function()
    local Lighting = game:GetService('Lighting')
    local ReplicatedStorage = game:GetService('ReplicatedStorage')
    local shared = require(ReplicatedStorage:WaitForChild('Packages'):WaitForChild('Shared'))
    local profile = shared.Runtime.MazeLightingProfile

    local original = {
        Technology = Lighting.Technology,
        GlobalShadows = Lighting.GlobalShadows,
        Brightness = Lighting.Brightness,
        ClockTime = Lighting.ClockTime,
        ExposureCompensation = Lighting.ExposureCompensation,
        ShadowSoftness = Lighting.ShadowSoftness,
        Ambient = Lighting.Ambient,
        OutdoorAmbient = Lighting.OutdoorAmbient,
        EnvironmentDiffuseScale = Lighting.EnvironmentDiffuseScale,
        EnvironmentSpecularScale = Lighting.EnvironmentSpecularScale,
    }

    local created = profile.apply(Lighting)

    assert(
        Lighting.Technology == Enum.Technology.Future,
        'Maze lighting should use Future technology'
    )
    assert(Lighting.GlobalShadows == true, 'Maze lighting should keep global shadows enabled')
    assert(Lighting.ExposureCompensation < 0, 'Maze lighting should darken exposure for atmosphere')
    assert(
        created.Atmosphere ~= nil and created.Atmosphere.Parent == Lighting,
        'Maze lighting should create an atmosphere effect'
    )
    assert(
        created.ColorCorrection ~= nil and created.ColorCorrection.Parent == Lighting,
        'Maze lighting should create a color correction effect'
    )
    assert(
        created.Bloom ~= nil and created.Bloom.Parent == Lighting,
        'Maze lighting should create a bloom effect'
    )
    assert(
        created.DepthOfField ~= nil and created.DepthOfField.Parent == Lighting,
        'Maze lighting should create a depth of field effect'
    )
    assert(
        profile.SurfacePalette.WallMaterial == Enum.Material.Slate,
        'Maze lighting profile should provide a darker wall palette for the maze renderer'
    )

    created.Atmosphere:Destroy()
    created.ColorCorrection:Destroy()
    created.Bloom:Destroy()
    created.DepthOfField:Destroy()

    Lighting.Technology = original.Technology
    Lighting.GlobalShadows = original.GlobalShadows
    Lighting.Brightness = original.Brightness
    Lighting.ClockTime = original.ClockTime
    Lighting.ExposureCompensation = original.ExposureCompensation
    Lighting.ShadowSoftness = original.ShadowSoftness
    Lighting.Ambient = original.Ambient
    Lighting.OutdoorAmbient = original.OutdoorAmbient
    Lighting.EnvironmentDiffuseScale = original.EnvironmentDiffuseScale
    Lighting.EnvironmentSpecularScale = original.EnvironmentSpecularScale
end
