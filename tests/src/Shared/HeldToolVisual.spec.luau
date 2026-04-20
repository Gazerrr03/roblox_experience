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

    local function withMinimalCharacter(callback)
        local char = makeMinimalCharacter()
        local ok, err = pcall(callback, char)
        char:Destroy()
        assert(ok, err)
    end

    for _, itemId in ipairs({ 'tool-potion', 'tool-flashlight', 'tool-crowbar' }) do
        local entry = ToolItems[itemId]
        assert(entry ~= nil, string.format('ToolItems should define %q', itemId))
        assert(
            type(entry.ToolTemplateName) == 'string' and entry.ToolTemplateName ~= '',
            string.format('%q should have ToolTemplateName for visual spec', itemId)
        )

        withMinimalCharacter(function(char)
            HeldToolVisual.sync(char, entry)
            local hand = char:FindFirstChild('RightHand')
            assert(hand ~= nil, 'Spec character should have RightHand')
            local clone = hand:FindFirstChild(HeldToolVisual.CLONE_NAME)
            assert(clone ~= nil, string.format('sync should parent clone for %q', itemId))

            HeldToolVisual.clear(char)
            assert(
                hand:FindFirstChild(HeldToolVisual.CLONE_NAME) == nil,
                string.format('clear should remove clone for %q', itemId)
            )
        end)
    end
end
