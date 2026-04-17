return function()
    local ReplicatedStorage = game:GetService('ReplicatedStorage')
    local shared = require(ReplicatedStorage:WaitForChild('Packages'):WaitForChild('Shared'))
    local runModules = ReplicatedStorage:WaitForChild('PlaceModules'):WaitForChild('Run')
    local RunSessionService = require(runModules:WaitForChild('RunSessionService'))

    local existingContainer = ReplicatedStorage:FindFirstChild('Remotes')
    if existingContainer then
        existingContainer:Destroy()
    end

    local runRemotes = shared.Network.Remotes.ensureScope(shared.Network.Remotes.Scope.Run)
    local service = RunSessionService.new()

    local ok, bindError = pcall(function()
        service:_bindItemRemotes()
    end)

    assert(
        ok,
        string.format(
            'RunSessionService should tolerate the contract-v2 run remote scope without legacy item remotes: %s',
            tostring(bindError)
        )
    )
    assert(
        service.Remotes.RunAction == runRemotes.RunAction,
        'RunAction should remain the active run action surface'
    )
    assert(
        service.Remotes.GetInventory == nil and service.Remotes.GetItemData == nil,
        'RunSessionService should not require legacy item RemoteFunctions when using the current shared contract'
    )
end
