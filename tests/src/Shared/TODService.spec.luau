return function()
    local Lighting = game:GetService('Lighting')
    local ReplicatedStorage = game:GetService('ReplicatedStorage')
    local shared = require(ReplicatedStorage:WaitForChild('Packages'):WaitForChild('Shared'))
    local TODService = shared.Runtime.TODService
    local profile = shared.Runtime.TODProfile

    local originalLighting = {}
    for _, propertyName in ipairs(profile.LightingPropertyNames) do
        originalLighting[propertyName] = Lighting[propertyName]
    end

    local preservedChildren = {}
    for _, child in ipairs(Lighting:GetChildren()) do
        if
            child:IsA('Sky')
            or child:IsA('BloomEffect')
            or child:IsA('Atmosphere')
            or child:IsA('ColorGradingEffect')
            or child:IsA('ColorCorrectionEffect')
        then
            child.Parent = nil
            table.insert(preservedChildren, child)
        end
    end

    local function restoreLighting()
        for _, propertyName in ipairs(profile.LightingPropertyNames) do
            Lighting[propertyName] = originalLighting[propertyName]
        end

        for _, child in ipairs(Lighting:GetChildren()) do
            if
                child:IsA('Sky')
                or child:IsA('BloomEffect')
                or child:IsA('Atmosphere')
                or child:IsA('ColorGradingEffect')
                or child:IsA('ColorCorrectionEffect')
            then
                child:Destroy()
            end
        end

        for _, child in ipairs(preservedChildren) do
            child.Parent = Lighting
        end
    end

    local existingAtmosphere = Instance.new('Atmosphere')
    existingAtmosphere.Name = 'ExistingAtmosphere'
    existingAtmosphere.Density = 0.11
    existingAtmosphere.Parent = Lighting

    local createColorGradingOk, existingColorGrading = pcall(Instance.new, 'ColorGradingEffect')
    if not createColorGradingOk then
        existingColorGrading = Instance.new('ColorCorrectionEffect')
    end
    existingColorGrading.Name = 'ColorGrading'
    existingColorGrading.Brightness = 0.14
    existingColorGrading.Parent = Lighting

    local sky = Instance.new('Sky')
    sky.Name = 'ReferenceSky'
    sky.SkyboxBk = 'rbxassetid://111'
    sky.Parent = Lighting

    local bloom = Instance.new('BloomEffect')
    bloom.Name = 'ReferenceBloom'
    bloom.Intensity = 0.42
    bloom.Parent = Lighting

    local remote = {
        AllPayloads = {},
        PlayerPayloads = {},
    }

    function remote:FireAllClients(payload)
        table.insert(self.AllPayloads, payload)
    end

    function remote:FireClient(player, payload)
        self.PlayerPayloads[player] = payload
    end

    local currentClock = 100
    local service = TODService.new({
        Config = shared.Config.SessionConfig.TOD,
        Lighting = Lighting,
        Remote = remote,
        Clock = function()
            return currentClock
        end,
    })

    local initialPayload = service:prime()
    assert(
        initialPayload.IsRunning == false,
        'Priming TOD should only broadcast a static initial state'
    )
    assert(Lighting.ClockTime == 7, 'Priming TOD should apply the configured opening clock time')
    assert(
        service.Targets.Atmosphere == existingAtmosphere,
        'TOD should reuse an existing Atmosphere effect when one is already authored'
    )
    assert(
        service.Targets.ColorGrading == existingColorGrading,
        'TOD should reuse the authored ColorGrading effect when one is already present'
    )
    assert(
        Lighting:FindFirstChild(TODService.ManagedNames.Atmosphere) == nil,
        'TOD should not create a managed atmosphere while an authored atmosphere already exists'
    )
    assert(
        Lighting:FindFirstChild(TODService.ManagedNames.ColorGrading) == nil,
        'TOD should not create a managed grading effect while an authored grading effect already exists'
    )
    assert(#remote.AllPayloads == 1, 'Priming TOD should broadcast exactly one initial payload')

    local fakePlayer = {}
    service:sendToPlayer(fakePlayer)
    assert(
        remote.PlayerPayloads[fakePlayer] == service.CurrentState,
        'Explicit player sync should forward the current TOD payload'
    )

    service:start()
    assert(
        service.CurrentState.IsRunning == true,
        'Starting TOD should flip the payload into a running state'
    )
    assert(
        sky.SkyboxBk == 'rbxassetid://111',
        'TOD should not mutate the existing skybox asset configuration'
    )
    assert(bloom.Intensity == 0.42, 'TOD should not mutate the authored bloom effect')

    currentClock += profile.getDurationSeconds(shared.Config.SessionConfig.TOD)
    local finishedPayload = service:step(currentClock)
    assert(finishedPayload.IsRunning == false, 'TOD should stop once the round duration expires')
    assert(
        finishedPayload.RoundTimeRemainingSeconds == 0,
        'TOD should finish with zero remaining seconds'
    )
    assert(finishedPayload.ClockTime == 22, 'TOD should finish at the configured final clock time')
    assert(
        service.IsRunning == false,
        'TOD service should stop its running flag after the final step'
    )

    restoreLighting()
end
