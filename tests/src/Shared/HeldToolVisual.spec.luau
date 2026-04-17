return function()
    local ReplicatedStorage = game:GetService('ReplicatedStorage')
    local gameplay = require(ReplicatedStorage:WaitForChild('Packages'):WaitForChild('Gameplay'))
    local shared = require(ReplicatedStorage:WaitForChild('Packages'):WaitForChild('Shared'))
    local ToolItems = gameplay.Config.ToolItems
    local HeldToolVisual = shared.Client.HeldToolVisual

    local function makeMinimalCharacter()
        local char = Instance.new('Model')
        char.Name = 'SpecCharacter'
        local hand = Instance.new('Part')
        hand.Name = 'RightHand'
        hand.Size = Vector3.new(1, 1, 1)
        hand.Anchored = true
        hand.Parent = char
        return char
    end

    for _, itemId in ipairs({ 'tool-potion', 'tool-flashlight', 'tool-crowbar' }) do
        local entry = ToolItems[itemId]
        assert(entry ~= nil, string.format('ToolItems should define %q', itemId))
        assert(
            type(entry.ToolTemplateName) == 'string' and entry.ToolTemplateName ~= '',
            string.format('%q should have ToolTemplateName for visual spec', itemId)
        )

        local char = makeMinimalCharacter()
        char.Parent = workspace

        HeldToolVisual.sync(char, entry)
        local hand = char:FindFirstChild('RightHand')
        assert(hand ~= nil, 'Spec character should have RightHand')
        local clone = hand:FindFirstChild('HeldToolVisualClone')
        assert(clone ~= nil, string.format('sync should parent clone for %q', itemId))

        HeldToolVisual.clear(char)
        assert(
            hand:FindFirstChild('HeldToolVisualClone') == nil,
            string.format('clear should remove clone for %q', itemId)
        )

        char:Destroy()
    end
end
