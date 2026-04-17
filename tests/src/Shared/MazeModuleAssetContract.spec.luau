return function()
    local ReplicatedStorage = game:GetService('ReplicatedStorage')
    local runtime =
        ReplicatedStorage:WaitForChild('Packages'):WaitForChild('Shared'):WaitForChild('Runtime')
    local contract = require(runtime:WaitForChild('MazeModuleAssetContract'))

    local assetRoot = Instance.new('Folder')
    assetRoot.Name = 'MazeModuleAssets'

    for _, moduleName in ipairs(contract.RequiredModuleNames) do
        local child = Instance.new('Folder')
        child.Name = moduleName
        child.Parent = assetRoot
    end

    assert(
        contract.validateRoot(assetRoot) == assetRoot,
        'Valid module asset root should pass unchanged'
    )

    local roomArchetypes = Instance.new('Folder')
    roomArchetypes.Name = contract.OptionalAuthoringFolderName
    roomArchetypes.Parent = assetRoot

    local entrySafe = Instance.new('Folder')
    entrySafe.Name = 'EntrySafe'
    entrySafe.Parent = roomArchetypes

    local shellModel = Instance.new('Model')
    shellModel.Name = contract.OptionalShellModelName
    local shellPart = Instance.new('Part')
    shellPart.Name = 'ShellPart'
    shellPart.Parent = shellModel
    shellModel.Parent = entrySafe

    assert(
        contract.getRoomArchetypeShellModel(assetRoot, 'EntrySafe') == shellModel,
        'Authoring contract should expose optional room shell assets'
    )
    assert(
        contract.validateRoot(assetRoot) == assetRoot,
        'Optional archetype asset folders should validate when present'
    )

    local connectorArchetypes = Instance.new('Folder')
    connectorArchetypes.Name = contract.OptionalConnectorAuthoringFolderName
    connectorArchetypes.Parent = assetRoot

    local industrialHall = Instance.new('Folder')
    industrialHall.Name = 'IndustrialHall'
    industrialHall.Parent = connectorArchetypes

    local connectorShell = Instance.new('Model')
    connectorShell.Name = contract.OptionalShellModelName
    local connectorShellPart = Instance.new('Part')
    connectorShellPart.Name = 'ConnectorShellPart'
    connectorShellPart.Parent = connectorShell
    connectorShell.Parent = industrialHall

    assert(
        contract.getConnectorShellModel(assetRoot, 'IndustrialHall') == connectorShell,
        'Authoring contract should expose optional connector shell assets'
    )
    assert(
        contract.validateRoot(assetRoot) == assetRoot,
        'Optional connector asset folders should validate when present'
    )

    shellModel:Destroy()
    local invalidShell = Instance.new('Folder')
    invalidShell.Name = contract.OptionalShellModelName
    invalidShell.Parent = entrySafe

    local invalidOk, invalidErr = pcall(function()
        contract.validateRoot(assetRoot)
    end)
    assert(invalidOk == false, 'Invalid optional shell asset types should raise an error')
    assert(
        string.find(tostring(invalidErr), 'must be a Model or BasePart', 1, true) ~= nil,
        'Invalid optional shell asset errors should explain the expected type'
    )

    invalidShell:Destroy()
    connectorShell:Destroy()
    local invalidConnectorShell = Instance.new('Folder')
    invalidConnectorShell.Name = contract.OptionalShellModelName
    invalidConnectorShell.Parent = industrialHall

    local invalidConnectorOk, invalidConnectorErr = pcall(function()
        contract.validateRoot(assetRoot)
    end)
    assert(
        invalidConnectorOk == false,
        'Invalid optional connector shell asset types should raise an error'
    )
    assert(
        string.find(tostring(invalidConnectorErr), 'must be a Model or BasePart', 1, true) ~= nil,
        'Invalid connector shell asset errors should explain the expected type'
    )

    invalidConnectorShell:Destroy()
    assetRoot:FindFirstChild('DoorLeaf'):Destroy()
    local ok, err = pcall(function()
        contract.validateRoot(assetRoot)
    end)
    assert(ok == false, 'Missing module assets should raise an error')
    assert(
        string.find(tostring(err), 'Missing maze module asset: DoorLeaf', 1, true) ~= nil,
        'Missing module asset errors should identify the missing module by name'
    )

    assetRoot:Destroy()
end
