local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Packages = ReplicatedStorage:WaitForChild('Packages')
local Gameplay = require(Packages:WaitForChild('Gameplay'))
local ItemPresentation = Gameplay.Config.ItemPresentation

local CLONE_NAME = 'HeldToolVisualClone'

local HeldToolVisual = {}

local function getHandPart(character: Model): BasePart?
    local hand = character:FindFirstChild('RightHand') or character:FindFirstChild('Right Arm')
    return hand and hand:IsA('BasePart') and hand or nil
end

function HeldToolVisual.clear(character: Model?)
    if not character then
        return
    end

    local hand = getHandPart(character)
    if hand then
        local existing = hand:FindFirstChild(CLONE_NAME)
        if existing then
            existing:Destroy()
        end
    end
end

local function tryWeldToHand(hand: BasePart, root: Instance)
    local handle = root:FindFirstChild('Handle', true)
    if handle and handle:IsA('BasePart') then
        for _, inst in root:GetDescendants() do
            if inst:IsA('BasePart') then
                inst.Anchored = false
                inst.CanCollide = false
                inst.Massless = true
            end
        end

        handle.CFrame = hand.CFrame
        local weld = Instance.new('WeldConstraint')
        weld.Part0 = hand
        weld.Part1 = handle
        weld.Parent = handle
    end
end

function HeldToolVisual.sync(character: Model?, heldItem: any?)
    if not character then
        return
    end

    HeldToolVisual.clear(character)

    if type(heldItem) ~= 'table' then
        return
    end

    local templateName = heldItem.ToolTemplateName
    if type(templateName) ~= 'string' or templateName == '' then
        return
    end

    local assetsFolder =
        ReplicatedStorage:FindFirstChild(ItemPresentation.REPLICATED_STORAGE_ASSETS_FOLDER)
    if not assetsFolder then
        return
    end

    local templatesFolder = assetsFolder:FindFirstChild(ItemPresentation.TOOL_TEMPLATES_FOLDER)
    if not templatesFolder then
        return
    end

    local template = templatesFolder:FindFirstChild(templateName)
    if not template or (not template:IsA('Model') and not template:IsA('Tool')) then
        return
    end

    local hand = getHandPart(character)
    if not hand then
        return
    end

    local clone = template:Clone()
    clone.Name = CLONE_NAME
    clone.Parent = hand

    if clone:IsA('Model') then
        if clone.PrimaryPart == nil then
            local handle = clone:FindFirstChild('Handle')
            if handle and handle:IsA('BasePart') then
                clone.PrimaryPart = handle
            end
        end
        tryWeldToHand(hand, clone)
    elseif clone:IsA('Tool') then
        tryWeldToHand(hand, clone)
    end
end

return HeldToolVisual
