local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService('RunService')

local Packages = ReplicatedStorage:WaitForChild('Packages')
local Gameplay = require(Packages:WaitForChild('Gameplay'))
local ItemPresentation = Gameplay.Config.ItemPresentation

local CLONE_NAME = 'HeldToolVisualClone'

-- PR #289 (gemini-code-assist high): one in-flight cosmetic swing cleanup per character — a single module-level
-- slot would let two characters overwrite each other's restore callbacks.
local swingCleanupByCharacter: { [Model]: () -> () } = {}

local HeldToolVisual = {}
HeldToolVisual.CLONE_NAME = CLONE_NAME

local function cancelSwingCleanupForCharacter(character: Model)
    local cleanup = swingCleanupByCharacter[character]
    if cleanup then
        cleanup()
        swingCleanupByCharacter[character] = nil
    end
end

local function getHandPart(character: Model): BasePart?
    local hand = character:FindFirstChild('RightHand') or character:FindFirstChild('Right Arm')
    return hand and hand:IsA('BasePart') and hand or nil
end

function HeldToolVisual.clear(character: Model?)
    if character then
        cancelSwingCleanupForCharacter(character)
    end

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

local function addRigidEdge(adj: { [BasePart]: { BasePart } }, partA: BasePart, partB: BasePart)
    adj[partA] = adj[partA] or {}
    adj[partB] = adj[partB] or {}
    table.insert(adj[partA], partB)
    table.insert(adj[partB], partA)
end

-- Parts already rigidly linked to `handle` through WeldConstraint / Motor6D inside `root`.
local function partsRigidlyConnectedToHandle(
    root: Instance,
    handle: BasePart
): { [BasePart]: boolean }
    local adj: { [BasePart]: { BasePart } } = {}
    for _, inst in root:GetDescendants() do
        if inst:IsA('WeldConstraint') or inst:IsA('Motor6D') then
            local p0, p1 = inst.Part0, inst.Part1
            if p0 and p1 and p0:IsA('BasePart') and p1:IsA('BasePart') then
                addRigidEdge(adj, p0, p1)
            end
        end
    end

    local seen: { [BasePart]: boolean } = { [handle] = true }
    local queue = { handle }
    local index = 1
    while index <= #queue do
        local current = queue[index]
        index += 1
        for _, neighbor in adj[current] or {} do
            if not seen[neighbor] then
                seen[neighbor] = true
                table.insert(queue, neighbor)
            end
        end
    end

    return seen
end

local function tryWeldToHand(hand: BasePart, root: Instance)
    local handle = root:FindFirstChild('Handle', true)
    if not (handle and handle:IsA('BasePart')) then
        return
    end

    for _, inst in root:GetDescendants() do
        if inst:IsA('BasePart') then
            inst.Anchored = false
            inst.CanCollide = false
            inst.Massless = true
        end
    end

    if root:IsA('Model') then
        local model = root :: Model
        if model.PrimaryPart ~= nil then
            model:PivotTo(hand.CFrame)
        else
            handle.CFrame = hand.CFrame
        end
    else
        handle.CFrame = hand.CFrame
    end

    local connected = partsRigidlyConnectedToHandle(root, handle)
    for _, inst in root:GetDescendants() do
        if inst:IsA('BasePart') and inst ~= handle and not connected[inst] then
            local w = Instance.new('WeldConstraint')
            w.Part0 = handle
            w.Part1 = inst
            w.Parent = inst
            connected[inst] = true
        end
    end

    local handWeld = Instance.new('WeldConstraint')
    handWeld.Part0 = hand
    handWeld.Part1 = handle
    handWeld.Parent = handle
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
            local h = clone:FindFirstChild('Handle')
            if h and h:IsA('BasePart') then
                clone.PrimaryPart = h
            end
        end
        tryWeldToHand(hand, clone)
    elseif clone:IsA('Tool') then
        tryWeldToHand(hand, clone)
    end
end

local function hasHandHandleWeld(hand: BasePart, handle: BasePart): boolean
    for _, inst in handle:GetChildren() do
        if inst:IsA('WeldConstraint') then
            local w = inst :: WeldConstraint
            if
                (w.Part0 == hand and w.Part1 == handle) or (w.Part1 == hand and w.Part0 == handle)
            then
                return true
            end
        end
    end

    return false
end

-- Cosmetic only: breaks the hand↔handle weld briefly, rotates the handle, then re-welds.
-- Server hit detection stays on RequestUseTool; do not use this for gameplay authority.
function HeldToolVisual.playCrowbarSwingFeedback(character: Model?)
    if not character then
        return
    end

    cancelSwingCleanupForCharacter(character)

    local hand = getHandPart(character)
    if not hand then
        return
    end

    local clone = hand:FindFirstChild(CLONE_NAME)
    if not clone then
        return
    end

    local handle = clone:FindFirstChild('Handle', true)
    if not (handle and handle:IsA('BasePart')) then
        return
    end

    local handWeld: WeldConstraint? = nil
    for _, inst in handle:GetChildren() do
        if inst:IsA('WeldConstraint') then
            local w = inst :: WeldConstraint
            if
                (w.Part0 == hand and w.Part1 == handle) or (w.Part1 == hand and w.Part0 == handle)
            then
                handWeld = w
                break
            end
        end
    end
    if not handWeld then
        return
    end

    handWeld:Destroy()
    local offset = hand.CFrame:ToObjectSpace(handle.CFrame)
    local duration = 0.22
    local elapsed = 0.0

    local connection: RBXScriptConnection?
    local finished = false

    local function restoreWeld()
        if finished then
            return
        end
        finished = true
        swingCleanupByCharacter[character] = nil
        if connection then
            connection:Disconnect()
            connection = nil
        end
        if handle.Parent and hand.Parent then
            handle.CFrame = hand.CFrame * offset
            if not hasHandHandleWeld(hand, handle) then
                local restored = Instance.new('WeldConstraint')
                restored.Part0 = hand
                restored.Part1 = handle
                restored.Parent = handle
            end
        end
    end

    swingCleanupByCharacter[character] = restoreWeld

    connection = RunService.Heartbeat:Connect(function(dt)
        if not handle.Parent or not hand.Parent then
            restoreWeld()
            return
        end

        elapsed += dt
        if elapsed >= duration then
            restoreWeld()
            return
        end

        local alpha = elapsed / duration
        local swing = math.sin(alpha * math.pi)
        local extra = CFrame.Angles(math.rad(58) * swing, math.rad(14) * swing, 0)
        handle.CFrame = hand.CFrame * offset * extra
    end)
end

return HeldToolVisual
