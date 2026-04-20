--!strict
-- Shared server-side effects after a held tool successfully consumes use (cooldown / charges).
-- Used by Maze and Run so flashlight / crowbar / potion behave the same.

local ToolUseEffects = {}

local FLASHLIGHT_COLOR = Color3.fromRGB(255, 255, 240)

export type ToolUseDeps = {
    MonsterService: any?,
    PlayerService: any?,
}

local function toggleHeadFlashlight(player: Player): (boolean, string)
    local character = player.Character
    if not character then
        return false, 'No character.'
    end

    local head = character:FindFirstChild('Head')
    if not head or not head:IsA('BasePart') then
        return false, 'No head.'
    end

    local existing = head:FindFirstChild('FlashlightLight')
    if existing then
        if existing:IsA('Light') then
            existing.Enabled = not existing.Enabled
            return existing.Enabled, ''
        end
        existing:Destroy()
    end

    local spot = Instance.new('SpotLight')
    spot.Name = 'FlashlightLight'
    spot.Color = FLASHLIGHT_COLOR
    spot.Brightness = 2
    spot.Range = 50
    spot.Angle = 45
    spot.Face = Enum.NormalId.Front
    spot.Enabled = true
    spot.Parent = head

    return true, ''
end

function ToolUseEffects.applyHeldToolUse(
    player: Player,
    updatedHeldItem: { [string]: any },
    deps: ToolUseDeps
): (string, string)
    local category = updatedHeldItem.ToolCategory

    if category == 'Flashlight' then
        local enabled, err = toggleHeadFlashlight(player)
        if not enabled and err ~= '' then
            return 'flashed', err
        end
        if enabled then
            return 'flashed', 'The area is illuminated.'
        end
        return 'flashed', 'You switch the beam off.'
    end

    if category == 'Crowbar' then
        local actionWord = 'swung'
        local effectText = 'A satisfying swoosh cuts the air!'

        local damagePips = 1
        if type(updatedHeldItem.MeleeDamage) == 'number' and updatedHeldItem.MeleeDamage >= 1 then
            damagePips = math.floor(updatedHeldItem.MeleeDamage)
        end

        local monsterService = deps.MonsterService
        if monsterService and type(monsterService.tryApplyPlayerMeleeHit) == 'function' then
            local meleeOk, meleeResult = monsterService:tryApplyPlayerMeleeHit(player, {
                DamagePips = damagePips,
                SwingArcDegrees = updatedHeldItem.SwingArcDegrees,
                SwingRange = updatedHeldItem.SwingRange,
            })
            if meleeOk then
                if meleeResult and meleeResult.Killed then
                    effectText = 'The crowbar connects — the threat goes down!'
                elseif meleeResult and type(meleeResult.RemainingHitPoints) == 'number' then
                    effectText = string.format(
                        'The crowbar connects! Foe stamina: ~%d.',
                        meleeResult.RemainingHitPoints
                    )
                end
            end
        end

        return actionWord, effectText
    end

    if category == 'Potion' then
        local actionWord = 'drank'
        local healPips = 1
        if
            type(updatedHeldItem.HealHealthPips) == 'number'
            and updatedHeldItem.HealHealthPips >= 1
        then
            healPips = math.floor(updatedHeldItem.HealHealthPips)
        end

        local playerService = deps.PlayerService
        if not playerService or type(playerService.healHealthPips) ~= 'function' then
            return actionWord, 'The brew has no effect (no player service).'
        end

        local healOk, healResult = playerService:healHealthPips(player, healPips)
        if healOk then
            return actionWord,
                string.format('The brew steadies you — health pips: %d.', healResult)
        end
        return actionWord, string.format('The brew has no effect (%s).', tostring(healResult))
    end

    return 'used', 'It worked!'
end

return ToolUseEffects
