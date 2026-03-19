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
