local HeldToolVisual = require(script.Parent.HeldToolVisual)

local HeldItemController = {}
HeldItemController.__index = HeldItemController

local LIGHT_ATTACHMENT_NAME = 'HeldItemGlowAttachment'
local LIGHT_INSTANCE_NAME = 'HeldItemGlowLight'

local function getLightParent(character)
    if not character then
        return nil
    end

    return character:FindFirstChild('Head') or character:FindFirstChild('HumanoidRootPart')
end

function HeldItemController.new(player)
    local self = setmetatable({
        Player = player,
        Inventory = nil,
        Connections = {},
    }, HeldItemController)

    table.insert(
        self.Connections,
        player.CharacterAdded:Connect(function()
            task.defer(function()
                self:_refresh()
            end)
        end)
    )
    table.insert(
        self.Connections,
        player.CharacterRemoving:Connect(function(character)
            self:_clearLight()
            HeldToolVisual.clear(character)
        end)
    )

    self:_refresh()

    return self
end

function HeldItemController:_clearLight()
    local character = self.Player.Character
    local lightParent = getLightParent(character)
    if not lightParent then
        return
    end

    local attachment = lightParent:FindFirstChild(LIGHT_ATTACHMENT_NAME)
    if attachment then
        attachment:Destroy()
    end
end

function HeldItemController:_refresh()
    local character = self.Player.Character
    local heldItem = self.Inventory and self.Inventory.HeldItem

    if character then
        HeldToolVisual.sync(character, heldItem)
    end

    local lightConfig = heldItem and heldItem.Light
    if type(lightConfig) ~= 'table' then
        self:_clearLight()
        return
    end

    if not character then
        return
    end

    local lightParent = getLightParent(character)
    if not lightParent then
        return
    end

    local attachment = lightParent:FindFirstChild(LIGHT_ATTACHMENT_NAME)
    if not attachment then
        attachment = Instance.new('Attachment')
        attachment.Name = LIGHT_ATTACHMENT_NAME
        attachment.Parent = lightParent
    end

    local light = attachment:FindFirstChild(LIGHT_INSTANCE_NAME)
    if not light then
        light = Instance.new('PointLight')
        light.Name = LIGHT_INSTANCE_NAME
        light.Parent = attachment
    end

    light.Enabled = true
    light.Brightness = lightConfig.Brightness or 2
    light.Range = lightConfig.Range or 16
    light.Color = lightConfig.Color or heldItem.Color or Color3.fromRGB(255, 255, 255)
end

function HeldItemController:applyInventory(inventory)
    self.Inventory = inventory
    self:_refresh()
end

function HeldItemController:destroy()
    for _, connection in ipairs(self.Connections) do
        connection:Disconnect()
    end

    self.Connections = {}
    self:_clearLight()
    HeldToolVisual.clear(self.Player.Character)
end

return HeldItemController
