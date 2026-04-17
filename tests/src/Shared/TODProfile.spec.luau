return function()
    local ReplicatedStorage = game:GetService('ReplicatedStorage')
    local shared = require(ReplicatedStorage:WaitForChild('Packages'):WaitForChild('Shared'))
    local profile = shared.Runtime.TODProfile
    local config = shared.Config.SessionConfig.TOD
    local durationSeconds = profile.getDurationSeconds(config)

    local morning = profile.evaluate(config, 0)
    assert(morning.ClockTime == 7, 'TOD should start at 07:00')
    assert(
        morning.RoundTimeRemainingSeconds == durationSeconds,
        'TOD should start with the full round duration remaining'
    )
    assert(
        morning.Lighting.ClockTime == 7,
        'The lighting payload should expose the same starting clock time'
    )

    local midpoint = profile.evaluate(config, durationSeconds / 2)
    assert(
        math.abs(midpoint.ClockTime - 14.5) < 0.001,
        'TOD midpoint should land halfway between the configured start and end hours'
    )
    assert(
        midpoint.Lighting.Brightness < 2.2 and midpoint.Lighting.Brightness > 2.08,
        'Midpoint lighting should interpolate between the midday and afternoon brightness values'
    )
    assert(
        midpoint.Atmosphere.Haze < 0.95 and midpoint.Atmosphere.Haze > 0.65,
        'Midpoint atmosphere haze should interpolate between adjacent keyframes'
    )
    assert(
        typeof(midpoint.ColorGrading.TintColor) == 'Color3',
        'TOD color grading payload should keep Color3 values stable during interpolation'
    )

    local clamped = profile.evaluate(config, durationSeconds + 120)
    assert(clamped.ClockTime == 22, 'TOD should clamp the final clock time at 22:00')
    assert(
        clamped.RoundTimeRemainingSeconds == 0,
        'TOD should clamp remaining round time at zero after the round finishes'
    )
    assert(
        clamped.Atmosphere.Density >= morning.Atmosphere.Density,
        'The night profile should remain denser than the opening morning profile'
    )
end
