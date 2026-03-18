local MazeModuleAssetContract = {}

MazeModuleAssetContract.RequiredModuleNames = table.freeze({
    'WallSegment',
    'DoorFrame',
    'DoorLeaf',
    'FloorPanel',
    'ExtractionMarker',
})

function MazeModuleAssetContract.validateRoot(root)
    if typeof(root) ~= 'Instance' then
        error('Maze module asset root must be a Studio instance.', 0)
    end

    if not (root:IsA('Folder') or root:IsA('Model')) then
        error('Maze module asset root must be a Folder or Model.', 0)
    end

    for _, moduleName in ipairs(MazeModuleAssetContract.RequiredModuleNames) do
        if root:FindFirstChild(moduleName) == nil then
            error(string.format('Missing maze module asset: %s', moduleName), 0)
        end
    end

    return root
end

return MazeModuleAssetContract
