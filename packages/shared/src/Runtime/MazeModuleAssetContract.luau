local MazeModuleAssetContract = {}

MazeModuleAssetContract.RequiredModuleNames = table.freeze({
    'WallSegment',
    'DoorFrame',
    'DoorLeaf',
    'FloorPanel',
    'ExtractionMarker',
})

MazeModuleAssetContract.OptionalAuthoringFolderName = 'RoomArchetypes'
MazeModuleAssetContract.OptionalConnectorAuthoringFolderName = 'ConnectorArchetypes'
MazeModuleAssetContract.OptionalShellModelName = 'ShellModel'

local function isContainer(instance)
    return instance:IsA('Folder') or instance:IsA('Model')
end

local function validateShellModel(shellModel, label)
    if shellModel ~= nil and not (shellModel:IsA('Model') or shellModel:IsA('BasePart')) then
        error(string.format('%s must be a Model or BasePart.', label), 0)
    end
end

local function validateOptionalAuthoringChildren(root, label)
    if root == nil then
        return
    end

    if not isContainer(root) then
        error(string.format('%s must be a Folder or Model.', label), 0)
    end

    for _, archetypeFolder in ipairs(root:GetChildren()) do
        if not isContainer(archetypeFolder) then
            error(
                string.format('%s asset %s must be a Folder or Model.', label, archetypeFolder.Name),
                0
            )
        end

        local shellModel =
            archetypeFolder:FindFirstChild(MazeModuleAssetContract.OptionalShellModelName)
        validateShellModel(
            shellModel,
            string.format(
                '%s shell asset %s/%s',
                label,
                archetypeFolder.Name,
                MazeModuleAssetContract.OptionalShellModelName
            )
        )
    end
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
    validateOptionalAuthoringChildren(roomArchetypesRoot, 'RoomArchetypes')

    local connectorArchetypesRoot =
        root:FindFirstChild(MazeModuleAssetContract.OptionalConnectorAuthoringFolderName)
    validateOptionalAuthoringChildren(connectorArchetypesRoot, 'ConnectorArchetypes')

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

function MazeModuleAssetContract.getConnectorShellModel(root, connectorArchetypeId)
    if typeof(root) ~= 'Instance' then
        return nil
    end

    local connectorArchetypesRoot =
        root:FindFirstChild(MazeModuleAssetContract.OptionalConnectorAuthoringFolderName)
    local archetypeFolder = connectorArchetypesRoot
        and connectorArchetypesRoot:FindFirstChild(connectorArchetypeId)
    return archetypeFolder
        and archetypeFolder:FindFirstChild(MazeModuleAssetContract.OptionalShellModelName)
end

return MazeModuleAssetContract
