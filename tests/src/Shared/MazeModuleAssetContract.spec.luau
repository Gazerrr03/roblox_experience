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

    local cavePocket = Instance.new('Folder')
    cavePocket.Name = 'CavePocket'
    cavePocket.Parent = roomArchetypes

    local shellModel = Instance.new('Model')
    shellModel.Name = contract.OptionalShellModelName
    local shellPart = Instance.new('Part')
    shellPart.Name = 'ShellPart'
    shellPart.Parent = shellModel
    shellModel.Parent = cavePocket

    assert(
        contract.getRoomArchetypeShellModel(assetRoot, 'CavePocket') == shellModel,
        'Authoring contract should expose optional archetype shell assets'
    )
    assert(
        contract.validateRoot(assetRoot) == assetRoot,
        'Optional archetype asset folders should validate when present'
    )

    shellModel:Destroy()
    local invalidShell = Instance.new('Folder')
    invalidShell.Name = contract.OptionalShellModelName
    invalidShell.Parent = cavePocket

    local invalidOk, invalidErr = pcall(function()
        contract.validateRoot(assetRoot)
    end)
    assert(invalidOk == false, 'Invalid optional shell asset types should raise an error')
    assert(
        string.find(tostring(invalidErr), 'must be a Model or BasePart', 1, true) ~= nil,
        'Invalid optional shell asset errors should explain the expected type'
    )

    invalidShell:Destroy()
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
