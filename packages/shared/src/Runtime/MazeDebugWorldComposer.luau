local MazeWorldShellBuilder = require(script.Parent.MazeWorldShellBuilder)
local MazeInteractionPartFactory = require(script.Parent.MazeInteractionPartFactory)

local MazeDebugWorldComposer = {}

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

    local _, returnPrompt = MazeInteractionPartFactory.createPromptPart({
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
