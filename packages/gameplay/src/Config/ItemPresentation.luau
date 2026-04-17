-- Shared presentation hints for items (2D icons, 3D template names).
-- Icon PNGs are recommended square; upload to Roblox, then paste the numeric id into IconAssetId.

local ItemPresentation = {}

ItemPresentation.ICON_RECOMMENDED_PIXELS = 256

ItemPresentation.REPLICATED_STORAGE_ASSETS_FOLDER = 'Assets'
ItemPresentation.TOOL_TEMPLATES_FOLDER = 'ToolTemplates'

function ItemPresentation.formatIconContentId(contentId: string?): string
    if contentId == nil or contentId == '' then
        return ''
    end
    if string.sub(contentId, 1, 13) == 'rbxassetid://' then
        return contentId
    end
    if string.sub(contentId, 1, 11) == 'rbxasset://' then
        return contentId
    end
    return 'rbxassetid://' .. contentId
end

return ItemPresentation
