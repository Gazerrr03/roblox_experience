local MazeInteractionPartFactory = {}

local DEFAULT_PROMPT_PART_SIZE = Vector3.new(4, 4, 4)
local DEFAULT_PROMPT_PART_MATERIAL = Enum.Material.Metal
local DEFAULT_PROMPT_MAX_ACTIVATION_DISTANCE = 10

function MazeInteractionPartFactory.createPart(config, parent)
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

function MazeInteractionPartFactory.createPromptPart(config, parent)
    local part = MazeInteractionPartFactory.createPart({
        Name = config.Name,
        Size = config.Size or DEFAULT_PROMPT_PART_SIZE,
        CFrame = config.CFrame,
        Color = config.Color,
        Material = config.Material or DEFAULT_PROMPT_PART_MATERIAL,
        Transparency = config.Transparency or 0,
        CanCollide = config.CanCollide,
        Shape = config.Shape,
    }, parent)

    local prompt = Instance.new('ProximityPrompt')
    prompt.ActionText = config.ActionText
    prompt.ObjectText = config.ObjectText
    prompt.HoldDuration = 0
    prompt.MaxActivationDistance = config.MaxActivationDistance
        or DEFAULT_PROMPT_MAX_ACTIVATION_DISTANCE
    prompt.RequiresLineOfSight = false
    prompt.Parent = part

    return part, prompt
end

return MazeInteractionPartFactory
