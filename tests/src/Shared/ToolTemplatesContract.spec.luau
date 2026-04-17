return function()
    local ReplicatedStorage = game:GetService('ReplicatedStorage')
    local gameplay = require(ReplicatedStorage:WaitForChild('Packages'):WaitForChild('Gameplay'))
    local ItemPresentation = gameplay.Config.ItemPresentation
    local ToolItems = gameplay.Config.ToolItems

    local assetsFolder =
        ReplicatedStorage:WaitForChild(ItemPresentation.REPLICATED_STORAGE_ASSETS_FOLDER, 10)
    assert(
        assetsFolder ~= nil,
        'ReplicatedStorage should contain Assets folder (check tests/default.project.json)'
    )

    local templatesFolder = assetsFolder:WaitForChild(ItemPresentation.TOOL_TEMPLATES_FOLDER, 10)
    assert(
        templatesFolder ~= nil,
        'Assets should contain ToolTemplates folder (check tests/default.project.json)'
    )

    for itemId, entry in pairs(ToolItems) do
        local templateName = entry.ToolTemplateName
        if type(templateName) == 'string' and templateName ~= '' then
            local inst = templatesFolder:FindFirstChild(templateName)
            assert(
                inst ~= nil,
                string.format(
                    'ToolTemplates must contain model for ToolTemplateName=%q (item %q)',
                    templateName,
                    itemId
                )
            )
            assert(
                inst:IsA('Model') or inst:IsA('Tool'),
                string.format(
                    'Template %q for item %q must be a Model or Tool, got %s',
                    templateName,
                    itemId,
                    inst.ClassName
                )
            )
            local handle = inst:FindFirstChild('Handle', true)
            assert(
                handle ~= nil and handle:IsA('BasePart'),
                string.format(
                    'Template %q for item %q must have a BasePart named Handle (descendant)',
                    templateName,
                    itemId
                )
            )
        end
    end
end
