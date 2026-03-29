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
        created.TechnologyApplied == true,
        'Maze lighting should use the Future profile when technology writes succeed'
    )
    assert(
        created.AppliedProfile == profile.ProfileName.Future,
        'Maze lighting should report the Future profile when technology is applied'
    )
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
        created.SurfacePalette == profile.SurfacePalette,
        'Maze lighting should return the Future surface palette when technology is applied'
    )

    created.Atmosphere:Destroy()
    created.ColorCorrection:Destroy()
    created.Bloom:Destroy()
    created.DepthOfField:Destroy()

    for property, value in pairs(original) do
        Lighting[property] = value
    end

    local fallbackCreated = profile.apply(Lighting, {
        PropertySetter = function(target, propertyName, value)
            if target == Lighting and propertyName == 'Technology' then
                error('technology write blocked for test')
            end

            target[propertyName] = value
        end,
    })

    assert(
        fallbackCreated.TechnologyApplied == false,
        'Maze lighting should degrade gracefully when technology writes fail'
    )
    assert(
        fallbackCreated.AppliedProfile == profile.ProfileName.FallbackReadable,
        'Maze lighting should report the fallback profile when technology writes fail'
    )
    assert(
        fallbackCreated.TechnologyError ~= nil,
        'Maze lighting should expose the technology write failure for diagnostics'
    )
    assert(
        Lighting.Brightness > original.Brightness,
        'Fallback maze lighting should raise the readability baseline'
    )
    assert(
        Lighting.ExposureCompensation >= 0,
        'Fallback maze lighting should avoid the darker Future exposure target'
    )
    assert(
        fallbackCreated.SurfacePalette == profile.FallbackSurfacePalette,
        'Maze lighting should return the fallback surface palette when technology writes fail'
    )
    assert(
        fallbackCreated.Atmosphere ~= nil and fallbackCreated.Atmosphere.Parent == Lighting,
        'Fallback maze lighting should still create an atmosphere effect'
    )
    assert(
        fallbackCreated.ColorCorrection ~= nil
            and fallbackCreated.ColorCorrection.Parent == Lighting,
        'Fallback maze lighting should still create a color correction effect'
    )
    assert(
        fallbackCreated.Bloom ~= nil and fallbackCreated.Bloom.Parent == Lighting,
        'Fallback maze lighting should still create a bloom effect'
    )
    assert(
        fallbackCreated.DepthOfField ~= nil and fallbackCreated.DepthOfField.Parent == Lighting,
        'Fallback maze lighting should still create a depth of field effect'
    )

    fallbackCreated.Atmosphere:Destroy()
    fallbackCreated.ColorCorrection:Destroy()
    fallbackCreated.Bloom:Destroy()
    fallbackCreated.DepthOfField:Destroy()

    for property, value in pairs(original) do
        Lighting[property] = value
    end
end
