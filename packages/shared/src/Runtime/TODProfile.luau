-- TODProfile.luau
-- Keyframe-based Time-of-Day profile for global lighting.
-- Drives Lighting.ClockTime + Atmosphere + ColorCorrectionEffect over a 15-hour
-- game-day (7:00 → 22:00) mapped to a configurable real-minute round.

local SessionConfig = require(script.Parent.Parent.Config.SessionConfig)

local EFFECT_NAME_ATMOSPHERE = 'TODAtmosphere'
local EFFECT_NAME_COLOR_CORRECTION = 'TODColorCorrection'

-- Hour → ClockTime is 1:1 (hour 7 → ClockTime 7, hour 12 → ClockTime 12, etc.)
-- Keyframes: hour, brightness, tintColor (RGB), atmosphereColor (RGB), atmosphereDensity
local KEYFRAMES = table.freeze({
    { hour = 7,  clockTime = 7,  brightness = 0.5,  tintColor = Color3.fromRGB(255, 235, 210), atmosphereColor = Color3.fromRGB(200, 175, 130), atmosphereDensity = 0.18 }, -- early morning, warm glow
    { hour = 8,  clockTime = 8,  brightness = 0.7,  tintColor = Color3.fromRGB(255, 240, 220), atmosphereColor = Color3.fromRGB(210, 185, 145), atmosphereDensity = 0.15 }, -- morning
    { hour = 9,  clockTime = 9,  brightness = 0.8,  tintColor = Color3.fromRGB(255, 245, 230), atmosphereColor = Color3.fromRGB(190, 175, 150), atmosphereDensity = 0.12 }, -- late morning
    { hour = 10, clockTime = 10, brightness = 0.9,  tintColor = Color3.fromRGB(255, 250, 240), atmosphereColor = Color3.fromRGB(175, 170, 155), atmosphereDensity = 0.10 }, -- approaching noon
    { hour = 11, clockTime = 11, brightness = 1.0,  tintColor = Color3.fromRGB(255, 255, 245), atmosphereColor = Color3.fromRGB(165, 165, 155), atmosphereDensity = 0.08 }, -- late morning
    { hour = 12, clockTime = 12, brightness = 1.05, tintColor = Color3.fromRGB(255, 255, 250), atmosphereColor = Color3.fromRGB(155, 160, 160), atmosphereDensity = 0.07 }, -- noon, peak brightness
    { hour = 13, clockTime = 13, brightness = 1.0,  tintColor = Color3.fromRGB(255, 252, 240), atmosphereColor = Color3.fromRGB(165, 165, 160), atmosphereDensity = 0.08 }, -- early afternoon
    { hour = 14, clockTime = 14, brightness = 0.9,  tintColor = Color3.fromRGB(255, 248, 230), atmosphereColor = Color3.fromRGB(175, 170, 160), atmosphereDensity = 0.10 }, -- afternoon
    { hour = 15, clockTime = 15, brightness = 0.75, tintColor = Color3.fromRGB(255, 240, 215), atmosphereColor = Color3.fromRGB(185, 170, 150), atmosphereDensity = 0.13 }, -- mid afternoon, warm
    { hour = 16, clockTime = 16, brightness = 0.6,  tintColor = Color3.fromRGB(255, 225, 195), atmosphereColor = Color3.fromRGB(195, 165, 135), atmosphereDensity = 0.16 }, -- late afternoon
    { hour = 17, clockTime = 17, brightness = 0.4,  tintColor = Color3.fromRGB(255, 205, 165), atmosphereColor = Color3.fromRGB(205, 155, 115), atmosphereDensity = 0.22 }, -- golden hour
    { hour = 18, clockTime = 18, brightness = 0.2,  tintColor = Color3.fromRGB(255, 175, 130), atmosphereColor = Color3.fromRGB(215, 140, 100), atmosphereDensity = 0.30 }, -- dusk
    { hour = 19, clockTime = 19, brightness = 0.0,  tintColor = Color3.fromRGB(255, 155, 110), atmosphereColor = Color3.fromRGB(130, 110, 140), atmosphereDensity = 0.35 }, -- sunset
    { hour = 20, clockTime = 20, brightness = -0.2, tintColor = Color3.fromRGB(220, 150, 130), atmosphereColor = Color3.fromRGB(90, 95, 120), atmosphereDensity = 0.38 }, -- near night
    { hour = 21, clockTime = 21, brightness = -0.3, tintColor = Color3.fromRGB(180, 140, 160), atmosphereColor = Color3.fromRGB(60, 70, 100), atmosphereDensity = 0.40 }, -- night
    { hour = 22, clockTime = 22, brightness = -0.4, tintColor = Color3.fromRGB(140, 130, 170), atmosphereColor = Color3.fromRGB(40, 50, 90), atmosphereDensity = 0.45 }, -- deep night
})

local TwilightTone = Color3.fromRGB(100, 80, 120)

local function findKeyframePair(hour)
    local startKF = KEYFRAMES[1]
    local endKF = KEYFRAMES[#KEYFRAMES]

    for i = 1, #KEYFRAMES - 1 do
        if KEYFRAMES[i].hour <= hour and KEYFRAMES[i + 1].hour >= hour then
            startKF = KEYFRAMES[i]
            endKF = KEYFRAMES[i + 1]
            break
        end
    end

    return startKF, endKF
end

local function lerpNumber(a, b, t)
    return a + (b - a) * t
end

local function lerpColor(a, b, t)
    return a:Lerp(b, t)
end

local TODProfile = {}

-- Interpolate a profile for a given game hour (float, 7.0 ~ 22.0)
function TODProfile.interpolateForHour(hour)
    local startKF, endKF = findKeyframePair(hour)
    local span = endKF.hour - startKF.hour
    local t = 0
    if span > 0 then
        t = math.clamp((hour - startKF.hour) / span, 0, 1)
    end

    return {
        clockTime = lerpNumber(startKF.clockTime, endKF.clockTime, t),
        brightness = lerpNumber(startKF.brightness, endKF.brightness, t),
        tintColor = lerpColor(startKF.tintColor, endKF.tintColor, t),
        atmosphereColor = lerpColor(startKF.atmosphereColor, endKF.atmosphereColor, t),
        atmosphereDensity = lerpNumber(startKF.atmosphereDensity, endKF.atmosphereDensity, t),
    }
end

-- Apply interpolated profile to Lighting + Atmosphere + ColorCorrection
function TODProfile.apply(lighting, profile)
    lighting.ClockTime = profile.clockTime

    local atmosphere = lighting:FindFirstChild(EFFECT_NAME_ATMOSPHERE)
    if not atmosphere then
        atmosphere = Instance.new('Atmosphere')
        atmosphere.Name = EFFECT_NAME_ATMOSPHERE
        atmosphere.Parent = lighting
    end
    atmosphere.Color = profile.atmosphereColor
    atmosphere.Density = profile.atmosphereDensity

    local cc = lighting:FindFirstChild(EFFECT_NAME_COLOR_CORRECTION)
    if not cc then
        cc = Instance.new('ColorCorrectionEffect')
        cc.Name = EFFECT_NAME_COLOR_CORRECTION
        cc.Parent = lighting
    end
    cc.Brightness = profile.brightness
    cc.TintColor = profile.tintColor
    cc.Saturation = lerpNumber(-0.15, -0.25, (profile.clockTime - 7) / 15)
    cc.Contrast = lerpNumber(0.1, 0.05, (profile.clockTime - 7) / 15)
end

-- Given elapsed real minutes, return game hour (float, 7.0 ~ 22.0)
function TODProfile.gameHourFromElapsedMinutes(elapsedMinutes)
    local cfg = SessionConfig.TOD
    local totalHours = cfg.EndHour - cfg.StartHour -- 15
    local minuteFraction = elapsedMinutes / 60
    local hour = cfg.StartHour + totalHours * minuteFraction
    return math.clamp(hour, cfg.StartHour, cfg.EndHour)
end

-- Given elapsed real minutes, return remaining real seconds
function TODProfile.remainingSeconds(elapsedSeconds)
    local cfg = SessionConfig.TOD
    local totalSeconds = cfg.RoundMinutes * 60
    return math.max(0, totalSeconds - elapsedSeconds)
end

return TODProfile
