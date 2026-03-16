local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Packages = ReplicatedStorage:WaitForChild('Packages')
local SharedPackage = Packages:WaitForChild('Shared')
local Gameplay = require(Packages:WaitForChild('Gameplay'))

local MazeBuilder = Gameplay.ProcGen.MazeBuilder
local HexMazeWorldRenderer =
    require(SharedPackage:WaitForChild('Runtime'):WaitForChild('HexMazeWorldRenderer'))

local LocalDebugMazeWorldBuilder = {}

local LOCAL_DEBUG_MAZE_WORLD_NAME = 'LocalDebugMazeWorld'
local DEFAULT_ORIGIN_OFFSET = Vector3.new(0, 0, 420)

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
    part.Shape = config.Shape or Enum.PartType.Block
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

function LocalDebugMazeWorldBuilder.build(seed, config, originOffset)
    local origin = originOffset or DEFAULT_ORIGIN_OFFSET
    local layout = MazeBuilder.build(seed, config)

    local rendered = HexMazeWorldRenderer.build({
        WorldName = LOCAL_DEBUG_MAZE_WORLD_NAME,
        Layout = layout,
        OriginOffset = origin,
        RoomApothem = config.RoomApothem,
        IncludeRoomMarker = true,
        RoomMarkerTransparency = 0.55,
    })

    for doorwayId, doorway in pairs(rendered.Doorways) do
        if doorway.Prompt then
            doorway.Prompt.Triggered:Connect(function()
                rendered.ToggleDoor(doorwayId)
            end)
        end
    end

    local campCenter = rendered.RoomCenters[layout.CampRoomId]
    local _, returnPrompt = createPromptPart({
        Name = 'ReturnToCampMarker',
        CFrame = CFrame.new(campCenter + Vector3.new(6, 0.5, 0)),
        Color = Color3.fromRGB(77, 147, 196),
        ActionText = 'Return',
        ObjectText = 'Return To Camp (Local Debug)',
        MaxActivationDistance = 14,
        CanCollide = false,
    }, rendered.Root)

    return {
        Root = rendered.Root,
        Layout = layout,
        Doorways = rendered.Doorways,
        ToggleDoor = rendered.ToggleDoor,
        SpawnCFrame = CFrame.new(campCenter + Vector3.new(0, 4, 0)),
        ReturnPrompt = returnPrompt,
        FindRoomByPosition = rendered.FindRoomByPosition,
        CanTraverseBetweenPositions = rendered.CanTraverseBetweenPositions,
    }
end

return LocalDebugMazeWorldBuilder
