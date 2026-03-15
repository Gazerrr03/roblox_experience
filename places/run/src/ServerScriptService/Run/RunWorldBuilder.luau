local Workspace = game:GetService('Workspace')

local CampHouseBuilder = require(script.Parent.CampHouseBuilder)
local OutdoorAreaBuilder = require(script.Parent.OutdoorAreaBuilder)

local RunWorldBuilder = {}

local OUTDOOR_THRESHOLD_Z = 20

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
    }, parent)

    local prompt = Instance.new('ProximityPrompt')
    prompt.ActionText = config.ActionText
    prompt.ObjectText = config.ObjectText
    prompt.HoldDuration = 0
    prompt.MaxActivationDistance = config.MaxActivationDistance or 10
    prompt.Parent = part

    return part, prompt
end

function RunWorldBuilder.build(_seed)
    local existing = Workspace:FindFirstChild('GeneratedWorld')
    if existing then
        existing:Destroy()
    end

    local worldFolder = Instance.new('Folder')
    worldFolder.Name = 'GeneratedWorld'
    worldFolder.Parent = Workspace

    local house = CampHouseBuilder.build(worldFolder, createPart, createPromptPart)
    local outdoors = OutdoorAreaBuilder.build(worldFolder, createPart, createPromptPart)

    return {
        Root = worldFolder,
        SpawnCFrame = CFrame.new(0, 4, -6),
        OutdoorThresholdZ = OUTDOOR_THRESHOLD_Z,
        ShopPrompt = house.ShopPrompt,
        LoadoutPrompt = house.LoadoutPrompt,
        GatePrompt = house.GatePrompt,
        MazePrompt = outdoors.MazePrompt,
        OpenGate = house.OpenGate,
    }
end

return RunWorldBuilder
