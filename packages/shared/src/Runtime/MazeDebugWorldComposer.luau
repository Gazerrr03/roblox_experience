local MazeWorldShellBuilder = require(script.Parent.MazeWorldShellBuilder)

local MazeDebugWorldComposer = {}

local function createPart(config, parent)
    local part = Instance.new('Part')
    part.Name = config.Name
    part.Anchored = true
    part.Size = config.Size
    part.CFrame = config.CFrame
    part.Color = config.Color
    part.Material = config.Material or Enum.Material.SmoothPlastic
    part.Transparency = config.Transparency or 0
    part.CanCollide = config.CanCollide ~= false
    if config.Shape then
        part.Shape = config.Shape
    end
    part.Parent = parent
    return part
end

local function createPromptPart(config, parent)
    local part = createPart({
        Name = config.Name,
        Size = config.Size or Vector3.new(4, 4, 4),
        CFrame = config.CFrame,
        Color = config.Color,
        Material = config.Material or Enum.Material.Metal,
        Transparency = config.Transparency or 0,
        CanCollide = config.CanCollide,
        Shape = config.Shape,
    }, parent)

    local prompt = Instance.new('ProximityPrompt')
    prompt.ActionText = config.ActionText
    prompt.ObjectText = config.ObjectText
    prompt.HoldDuration = 0
    prompt.MaxActivationDistance = config.MaxActivationDistance or 10
    prompt.RequiresLineOfSight = false
    prompt.Parent = part

    return part, prompt
end

function MazeDebugWorldComposer.build(seed, config, options)
    local resolvedOptions = options or {}
    local shell = MazeWorldShellBuilder.build(seed, config, {
        WorldName = resolvedOptions.WorldName or 'LocalDebugMazeWorld',
        Parent = resolvedOptions.Parent,
        OriginOffset = resolvedOptions.OriginOffset or Vector3.zero,
        IncludeRoomMarkers = resolvedOptions.IncludeRoomMarkers ~= false,
        RoomMarkerTransparency = resolvedOptions.RoomMarkerTransparency or 0.55,
        RoomKindColors = resolvedOptions.RoomKindColors,
        DetectionBuffer = resolvedOptions.DetectionBuffer,
    })

    local _, returnPrompt = createPromptPart({
        Name = 'ReturnToCampMarker',
        CFrame = CFrame.new(shell.CampCenter + Vector3.new(6, 0.5, 0)),
        Color = Color3.fromRGB(77, 147, 196),
        ActionText = 'Return',
        ObjectText = resolvedOptions.ReturnObjectText or 'Return To Camp (Local Debug)',
        MaxActivationDistance = resolvedOptions.ReturnMaxActivationDistance or 14,
        CanCollide = false,
    }, shell.Root)

    shell.ReturnPrompt = returnPrompt

    return shell
end

return MazeDebugWorldComposer
