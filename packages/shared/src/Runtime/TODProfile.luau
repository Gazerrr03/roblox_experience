local TODProfile = {}

TODProfile.LightingPropertyNames = table.freeze({
    'Brightness',
    'ClockTime',
    'ExposureCompensation',
    'ShadowSoftness',
    'Ambient',
    'OutdoorAmbient',
    'EnvironmentDiffuseScale',
    'EnvironmentSpecularScale',
})

TODProfile.AtmospherePropertyNames = table.freeze({
    'Color',
    'Decay',
    'Density',
    'Glare',
    'Haze',
    'Offset',
})

TODProfile.ColorGradingPropertyNames = table.freeze({
    'Brightness',
    'Contrast',
    'Saturation',
    'TintColor',
})

TODProfile.Keyframes = table.freeze({
    {
        Hour = 7,
        Lighting = table.freeze({
            Brightness = 1.9,
            ClockTime = 7,
            ExposureCompensation = -0.15,
            ShadowSoftness = 0.2,
            Ambient = Color3.fromRGB(70, 72, 76),
            OutdoorAmbient = Color3.fromRGB(90, 94, 100),
            EnvironmentDiffuseScale = 0.45,
            EnvironmentSpecularScale = 0.25,
        }),
        Atmosphere = table.freeze({
            Color = Color3.fromRGB(199, 171, 140),
            Decay = Color3.fromRGB(111, 94, 80),
            Density = 0.28,
            Glare = 0.05,
            Haze = 1.8,
            Offset = -0.15,
        }),
        ColorGrading = table.freeze({
            Brightness = -0.02,
            Contrast = 0.06,
            Saturation = -0.08,
            TintColor = Color3.fromRGB(255, 232, 214),
        }),
    },
    {
        Hour = 10,
        Lighting = table.freeze({
            Brightness = 2.05,
            ClockTime = 10,
            ExposureCompensation = -0.02,
            ShadowSoftness = 0.24,
            Ambient = Color3.fromRGB(94, 98, 106),
            OutdoorAmbient = Color3.fromRGB(124, 132, 142),
            EnvironmentDiffuseScale = 0.5,
            EnvironmentSpecularScale = 0.3,
        }),
        Atmosphere = table.freeze({
            Color = Color3.fromRGB(182, 196, 216),
            Decay = Color3.fromRGB(116, 130, 154),
            Density = 0.22,
            Glare = 0.08,
            Haze = 1.1,
            Offset = -0.08,
        }),
        ColorGrading = table.freeze({
            Brightness = 0.01,
            Contrast = 0.1,
            Saturation = -0.02,
            TintColor = Color3.fromRGB(238, 244, 255),
        }),
    },
    {
        Hour = 13,
        Lighting = table.freeze({
            Brightness = 2.2,
            ClockTime = 13,
            ExposureCompensation = 0.08,
            ShadowSoftness = 0.28,
            Ambient = Color3.fromRGB(110, 116, 128),
            OutdoorAmbient = Color3.fromRGB(148, 160, 174),
            EnvironmentDiffuseScale = 0.58,
            EnvironmentSpecularScale = 0.34,
        }),
        Atmosphere = table.freeze({
            Color = Color3.fromRGB(166, 198, 235),
            Decay = Color3.fromRGB(127, 155, 191),
            Density = 0.18,
            Glare = 0.12,
            Haze = 0.65,
            Offset = -0.04,
        }),
        ColorGrading = table.freeze({
            Brightness = 0.03,
            Contrast = 0.14,
            Saturation = 0.02,
            TintColor = Color3.fromRGB(255, 255, 255),
        }),
    },
    {
        Hour = 16,
        Lighting = table.freeze({
            Brightness = 2.08,
            ClockTime = 16,
            ExposureCompensation = 0.02,
            ShadowSoftness = 0.3,
            Ambient = Color3.fromRGB(102, 100, 108),
            OutdoorAmbient = Color3.fromRGB(142, 136, 146),
            EnvironmentDiffuseScale = 0.55,
            EnvironmentSpecularScale = 0.31,
        }),
        Atmosphere = table.freeze({
            Color = Color3.fromRGB(214, 189, 156),
            Decay = Color3.fromRGB(164, 128, 102),
            Density = 0.21,
            Glare = 0.09,
            Haze = 0.95,
            Offset = -0.08,
        }),
        ColorGrading = table.freeze({
            Brightness = 0.01,
            Contrast = 0.12,
            Saturation = -0.02,
            TintColor = Color3.fromRGB(255, 238, 214),
        }),
    },
    {
        Hour = 19,
        Lighting = table.freeze({
            Brightness = 1.72,
            ClockTime = 19,
            ExposureCompensation = -0.22,
            ShadowSoftness = 0.34,
            Ambient = Color3.fromRGB(74, 64, 82),
            OutdoorAmbient = Color3.fromRGB(104, 92, 118),
            EnvironmentDiffuseScale = 0.42,
            EnvironmentSpecularScale = 0.24,
        }),
        Atmosphere = table.freeze({
            Color = Color3.fromRGB(170, 125, 134),
            Decay = Color3.fromRGB(84, 62, 97),
            Density = 0.28,
            Glare = 0.04,
            Haze = 1.45,
            Offset = -0.16,
        }),
        ColorGrading = table.freeze({
            Brightness = -0.03,
            Contrast = 0.16,
            Saturation = -0.08,
            TintColor = Color3.fromRGB(238, 214, 255),
        }),
    },
    {
        Hour = 22,
        Lighting = table.freeze({
            Brightness = 1.34,
            ClockTime = 22,
            ExposureCompensation = -0.45,
            ShadowSoftness = 0.38,
            Ambient = Color3.fromRGB(36, 38, 56),
            OutdoorAmbient = Color3.fromRGB(54, 58, 86),
            EnvironmentDiffuseScale = 0.26,
            EnvironmentSpecularScale = 0.18,
        }),
        Atmosphere = table.freeze({
            Color = Color3.fromRGB(88, 100, 136),
            Decay = Color3.fromRGB(24, 28, 42),
            Density = 0.34,
            Glare = 0.02,
            Haze = 2.1,
            Offset = -0.22,
        }),
        ColorGrading = table.freeze({
            Brightness = -0.08,
            Contrast = 0.18,
            Saturation = -0.14,
            TintColor = Color3.fromRGB(208, 220, 255),
        }),
    },
})

local function lerpValue(leftValue, rightValue, alpha)
    local leftType = typeof(leftValue)
    if leftType == 'Color3' then
        return leftValue:Lerp(rightValue, alpha)
    end

    if leftType == 'number' then
        return leftValue + ((rightValue - leftValue) * alpha)
    end

    if alpha >= 1 then
        return rightValue
    end

    return leftValue
end

local function interpolateTable(leftTable, rightTable, alpha)
    local resolved = {}

    for propertyName, leftValue in pairs(leftTable) do
        resolved[propertyName] = lerpValue(leftValue, rightTable[propertyName], alpha)
    end

    return resolved
end

function TODProfile.getDurationSeconds(config)
    return math.max(0, math.floor((config.RoundMinutes or 0) * 60 + 0.5))
end

function TODProfile.evaluate(config, elapsedRoundSeconds)
    local startHour = config.StartHour or 7
    local endHour = config.EndHour or 22
    local durationSeconds = TODProfile.getDurationSeconds(config)
    local clampedElapsed = math.clamp(elapsedRoundSeconds or 0, 0, durationSeconds)
    local progress = if durationSeconds <= 0 then 1 else clampedElapsed / durationSeconds
    local currentHour = startHour + ((endHour - startHour) * progress)

    local leftKeyframe = TODProfile.Keyframes[1]
    local rightKeyframe = TODProfile.Keyframes[#TODProfile.Keyframes]

    for keyframeIndex = 1, #TODProfile.Keyframes - 1 do
        local candidateLeft = TODProfile.Keyframes[keyframeIndex]
        local candidateRight = TODProfile.Keyframes[keyframeIndex + 1]

        if currentHour <= candidateRight.Hour then
            leftKeyframe = candidateLeft
            rightKeyframe = candidateRight
            break
        end
    end

    local frameSpan = math.max(rightKeyframe.Hour - leftKeyframe.Hour, 0.0001)
    local frameAlpha = math.clamp((currentHour - leftKeyframe.Hour) / frameSpan, 0, 1)
    local lighting = interpolateTable(leftKeyframe.Lighting, rightKeyframe.Lighting, frameAlpha)
    lighting.ClockTime = currentHour

    return {
        ClockTime = currentHour,
        ElapsedRoundSeconds = clampedElapsed,
        RoundTimeRemainingSeconds = math.max(0, durationSeconds - clampedElapsed),
        Progress = progress,
        Lighting = lighting,
        Atmosphere = interpolateTable(
            leftKeyframe.Atmosphere,
            rightKeyframe.Atmosphere,
            frameAlpha
        ),
        ColorGrading = interpolateTable(
            leftKeyframe.ColorGrading,
            rightKeyframe.ColorGrading,
            frameAlpha
        ),
    }
end

return TODProfile
