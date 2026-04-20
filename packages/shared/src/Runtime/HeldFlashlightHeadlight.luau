--!strict
-- Server-side head-mounted spotlight for tool flashlight use (replicates on character).
local LIGHT_NAME = 'FlashlightLight'

local HeldFlashlightHeadlight = {}

-- Returns nil if the character has no Head; otherwise the new Enabled state after toggle.
function HeldFlashlightHeadlight.toggle(player: Player): boolean?
    local character = player.Character
    if not character then
        return nil
    end

    local head = character:FindFirstChild('Head')
    if not head or not head:IsA('BasePart') then
        return nil
    end

    local existing = head:FindFirstChild(LIGHT_NAME)
    local flashlightLight: SpotLight
    local isNewLight = false

    if existing and existing:IsA('SpotLight') then
        flashlightLight = existing
        flashlightLight.Enabled = not flashlightLight.Enabled
    else
        if existing then
            existing:Destroy()
        end
        flashlightLight = Instance.new('SpotLight')
        flashlightLight.Name = LIGHT_NAME
        flashlightLight.Color = Color3.fromRGB(255, 255, 240)
        flashlightLight.Brightness = 2
        flashlightLight.Range = 50
        flashlightLight.Angle = 45
        flashlightLight.Face = Enum.NormalId.Front
        flashlightLight.Parent = head
        isNewLight = true
    end

    if isNewLight then
        flashlightLight.Enabled = true
    end

    return flashlightLight.Enabled
end

function HeldFlashlightHeadlight.clear(player: Player)
    local character = player.Character
    if not character then
        return
    end

    local head = character:FindFirstChild('Head')
    if not head then
        return
    end

    local inst = head:FindFirstChild(LIGHT_NAME)
    if inst then
        inst:Destroy()
    end
end

-- Destroy head spotlight when the player is no longer holding a flashlight.
function HeldFlashlightHeadlight.syncHeldItem(player: Player, heldItem: any?)
    if type(heldItem) ~= 'table' or heldItem.ToolCategory ~= 'Flashlight' then
        HeldFlashlightHeadlight.clear(player)
    end
end

return HeldFlashlightHeadlight
