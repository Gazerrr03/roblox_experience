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

    assert(created.TechnologyApplied == true, 'Maze lighting should report applied technology')
    assert(created.TechnologyError == nil, 'Maze lighting should not report an error on success')
    assert(
        Lighting.Technology == Enum.Technology.Future,
        'Maze lighting should prefer Future technology'
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

    local simulatedFailureResult = profile.apply(Lighting, {
        ApplyTechnology = function()
            error("The current thread cannot write 'Technology' (lacking capability RobloxScript)")
        end,
    })

    assert(
        simulatedFailureResult.TechnologyApplied == false,
        'Maze lighting should degrade gracefully when Technology cannot be written'
    )
    assert(
        string.find(simulatedFailureResult.TechnologyError or '', 'cannot write') ~= nil,
        'Maze lighting should expose the Technology write failure reason'
    )
    assert(
        simulatedFailureResult.Atmosphere ~= nil
            and simulatedFailureResult.Atmosphere.Parent == Lighting,
        'Maze lighting should still create atmosphere when Technology write fails'
    )
    assert(
        simulatedFailureResult.ColorCorrection ~= nil
            and simulatedFailureResult.ColorCorrection.Parent == Lighting,
        'Maze lighting should still create color correction when Technology write fails'
    )
    assert(
        simulatedFailureResult.Bloom ~= nil and simulatedFailureResult.Bloom.Parent == Lighting,
        'Maze lighting should still create bloom when Technology write fails'
    )
    assert(
        simulatedFailureResult.DepthOfField ~= nil
            and simulatedFailureResult.DepthOfField.Parent == Lighting,
        'Maze lighting should still create depth of field when Technology write fails'
    )

    created.Atmosphere:Destroy()
    created.ColorCorrection:Destroy()
    created.Bloom:Destroy()
    created.DepthOfField:Destroy()

    for property, value in pairs(original) do
        Lighting[property] = value
    end
end
