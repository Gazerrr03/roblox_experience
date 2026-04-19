--!strict
-- Shared server path for RequestUseTool (maze + run): consume held state, apply category effects, status line.
-- Lazy-require Shared inside apply() to avoid Gameplay <-> Shared circular init (Runtime.InventoryService loads Gameplay).

export type HeldToolUseDependencies = {
    canManageInventory: (Player) -> boolean,
    inventoryService: any,
    monsterService: any?,
    playerService: any,
    setStatus: (string) -> (),
    -- When false for Crowbar, skip consumeHeldItemState entirely (no durability step, no LastUsedAt cooldown).
    shouldConsumeCrowbarOnUse: ((Player) -> boolean)?,
}

local HeldToolUseRequest = {}

local function crowbarMeleeMissText(reason: unknown): string
    local code = if type(reason) == 'string' then reason else nil
    if code == 'ExpeditionInactive' then
        return 'No hunt is active yet — open the ship door / start the round before swinging at monsters.'
    elseif code == 'NoMonster' then
        return 'Nothing dangerous is in the field to hit right now.'
    elseif code == 'MissingMonsterPosition' then
        return 'The threat has no position yet — try again in a moment.'
    elseif code == 'OutOfRange' then
        return 'That swing was too short — move closer and try again.'
    elseif code == 'OutOfSwingArc' then
        return 'You need to face the threat to connect.'
    elseif code == 'PathBlocked' then
        return 'Something solid blocks your swing.'
    elseif code == 'BlockedLineOfSight' then
        return 'You need a clear view of the threat.'
    elseif code == 'InvalidFacing' then
        return 'You need a clear facing direction to swing.'
    elseif code == 'NoCharacter' or code == 'MissingHumanoidRoot' then
        return 'You cannot swing without a ready character.'
    elseif code == 'MonsterCombatStateMissing' then
        return 'The threat is not ready to take damage yet.'
    elseif code == 'InvalidPlayer' then
        return 'That swing could not be applied.'
    end

    return string.format('The crowbar whiffs (%s).', tostring(reason))
end

function HeldToolUseRequest.apply(player: Player, deps: HeldToolUseDependencies)
    if not deps.canManageInventory(player) then
        return
    end

    local summary = deps.playerService:getSummary(player)
    local playerState = summary and summary.PlayerState
    if playerState and playerState.IsDead == true then
        deps.setStatus(string.format('%s cannot use tools while dead.', player.DisplayName))
        return
    end

    local inventorySummary = deps.inventoryService:getSummary(player)
    local heldItem = inventorySummary and inventorySummary.HeldItem

    if not heldItem then
        deps.setStatus(
            string.format('%s tried to use a tool, but hands are empty.', player.DisplayName)
        )
        return
    end

    if type(heldItem.CurrentState) ~= 'number' or type(heldItem.ConsumePerUse) ~= 'number' then
        deps.setStatus(
            string.format(
                '%s cannot actively "use" %s (it is not a tool).',
                player.DisplayName,
                heldItem.Name
            )
        )
        return
    end

    if heldItem.ConsumePerUse > 0 and heldItem.CurrentState < heldItem.ConsumePerUse then
        deps.setStatus(
            string.format(
                '%s tried to use %s, but it has no %s left.',
                player.DisplayName,
                heldItem.Name,
                heldItem.StateModel or 'power'
            )
        )
        return
    end

    if heldItem.ToolCategory == 'Crowbar' and deps.shouldConsumeCrowbarOnUse ~= nil then
        if not deps.shouldConsumeCrowbarOnUse(player) then
            deps.setStatus(
                string.format(
                    '%s hefted the %s, but the hunt is not live yet — no swing was committed (no use or cooldown).',
                    player.DisplayName,
                    heldItem.Name
                )
            )
            return
        end
    end

    local consumeSuccess, consumeResult, cooldownRemaining =
        deps.inventoryService:consumeHeldItemState(player, os.clock())
    if not consumeSuccess then
        if consumeResult == 'Cooldown' then
            deps.setStatus(
                string.format(
                    '%s cannot use %s yet (cooldown %.1fs remaining).',
                    player.DisplayName,
                    heldItem.Name,
                    math.max(cooldownRemaining or 0, 0)
                )
            )
        else
            deps.setStatus(
                string.format(
                    '%s could not use %s (%s).',
                    player.DisplayName,
                    heldItem.Name,
                    tostring(consumeResult)
                )
            )
        end
        return
    end

    local updatedHeldItem = consumeResult

    local actionWord = 'used'
    local effectText = 'It worked!'

    if updatedHeldItem.ToolCategory == 'Flashlight' then
        actionWord = 'flashed'
        local Shared = require(
            game:GetService('ReplicatedStorage'):WaitForChild('Packages'):WaitForChild('Shared')
        )
        local enabled = Shared.Runtime.HeldFlashlightHeadlight.toggle(player)
        if enabled == nil then
            effectText = 'Head lamp could not be toggled (no head).'
        elseif enabled then
            effectText = 'Headlamp on.'
        else
            effectText = 'Headlamp off.'
        end
    elseif updatedHeldItem.ToolCategory == 'Crowbar' then
        actionWord = 'swung'
        effectText = 'A satisfying swoosh cuts the air!'

        local damagePips = 1
        if type(updatedHeldItem.MeleeDamage) == 'number' and updatedHeldItem.MeleeDamage >= 1 then
            damagePips = math.floor(updatedHeldItem.MeleeDamage)
        end

        local monsterService = deps.monsterService
        if not monsterService then
            effectText = 'Monsters are not loaded yet — try again in a moment.'
        else
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
            else
                effectText = crowbarMeleeMissText(meleeResult)
            end
        end
    elseif updatedHeldItem.ToolCategory == 'Potion' then
        actionWord = 'drank'
        local healPips = 1
        if
            type(updatedHeldItem.HealHealthPips) == 'number'
            and updatedHeldItem.HealHealthPips >= 1
        then
            healPips = math.floor(updatedHeldItem.HealHealthPips)
        end
        local healOk, healResult = deps.playerService:healHealthPips(player, healPips)
        if healOk then
            effectText = string.format('The brew steadies you — health pips: %d.', healResult)
        else
            effectText = string.format('The brew has no effect (%s).', tostring(healResult))
        end
    end

    deps.setStatus(
        string.format(
            '%s %s the %s. %s (%s remaining: %d)',
            player.DisplayName,
            actionWord,
            updatedHeldItem.Name,
            effectText,
            updatedHeldItem.StateModel or 'state',
            updatedHeldItem.CurrentState
        )
    )
end

return HeldToolUseRequest
