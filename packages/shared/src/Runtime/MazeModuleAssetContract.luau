local MazeModuleAssetContract = {}

MazeModuleAssetContract.RequiredModuleNames = table.freeze({
    'WallSegment',
    'DoorFrame',
    'DoorLeaf',
    'FloorPanel',
    'ExtractionMarker',
})

MazeModuleAssetContract.OptionalAuthoringFolderName = 'RoomArchetypes'
MazeModuleAssetContract.OptionalShellModelName = 'ShellModel'

local function isContainer(instance)
    return instance:IsA('Folder') or instance:IsA('Model')
end

function MazeModuleAssetContract.validateRoot(root)
    if typeof(root) ~= 'Instance' then
        error('Maze module asset root must be a Studio instance.', 0)
    end

    if not isContainer(root) then
        error('Maze module asset root must be a Folder or Model.', 0)
    end

    for _, moduleName in ipairs(MazeModuleAssetContract.RequiredModuleNames) do
        if root:FindFirstChild(moduleName) == nil then
            error(string.format('Missing maze module asset: %s', moduleName), 0)
        end
    end

    local roomArchetypesRoot =
        root:FindFirstChild(MazeModuleAssetContract.OptionalAuthoringFolderName)
    if roomArchetypesRoot ~= nil then
        if not isContainer(roomArchetypesRoot) then
            error('RoomArchetypes must be a Folder or Model.', 0)
        end

        for _, archetypeFolder in ipairs(roomArchetypesRoot:GetChildren()) do
            if not isContainer(archetypeFolder) then
                error(
                    string.format(
                        'Room archetype asset %s must be a Folder or Model.',
                        archetypeFolder.Name
                    ),
                    0
                )
            end

            local shellModel =
                archetypeFolder:FindFirstChild(MazeModuleAssetContract.OptionalShellModelName)
            if
                shellModel ~= nil and not (shellModel:IsA('Model') or shellModel:IsA('BasePart'))
            then
                error(
                    string.format(
                        'Room archetype shell asset %s/%s must be a Model or BasePart.',
                        archetypeFolder.Name,
                        MazeModuleAssetContract.OptionalShellModelName
                    ),
                    0
                )
            end
        end
    end

    return root
end

function MazeModuleAssetContract.getRoomArchetypeShellModel(root, archetypeId)
    if typeof(root) ~= 'Instance' then
        return nil
    end

    local roomArchetypesRoot =
        root:FindFirstChild(MazeModuleAssetContract.OptionalAuthoringFolderName)
    local archetypeFolder = roomArchetypesRoot and roomArchetypesRoot:FindFirstChild(archetypeId)
    return archetypeFolder
        and archetypeFolder:FindFirstChild(MazeModuleAssetContract.OptionalShellModelName)
end

return MazeModuleAssetContract
