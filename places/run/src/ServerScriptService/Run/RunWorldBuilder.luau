local Workspace = game:GetService('Workspace')

local CampHouseBuilder = require(script.Parent.CampHouseBuilder)
local OutdoorAreaBuilder = require(script.Parent.OutdoorAreaBuilder)

local RunWorldBuilder = {}

local OUTDOOR_THRESHOLD_Z = 20
local DEFAULT_SPAWN_CFRAME = CFrame.new(0, 4, -6)
local DEFAULT_RETURN_CFRAME = CFrame.new(0, 4, -2)
local MAZE_RETURN_CFRAME = CFrame.new(0, 4, 108)
local GENERATED_WORLD_ROOT_NAME = 'GeneratedWorld'
local STATIC_WORLD_ROOT_NAME = 'RunStaticWorld'

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
    if config.KeyboardKeyCode ~= nil then
        prompt.KeyboardKeyCode = config.KeyboardKeyCode
    end
    if config.RequiresLineOfSight ~= nil then
        prompt.RequiresLineOfSight = config.RequiresLineOfSight
    end
    prompt.Parent = part

    return part, prompt
end

local function findNamedDescendant(root, name)
    for _, descendant in ipairs(root:GetDescendants()) do
        if descendant.Name == name then
            return descendant
        end
    end

    return nil
end

local function findPromptOnPart(root, partName)
    local part = findNamedDescendant(root, partName)
    if not part or not part:IsA('BasePart') then
        return nil
    end

    return part:FindFirstChildOfClass('ProximityPrompt')
end

local function requirePromptOnPart(root, partName)
    local prompt = findPromptOnPart(root, partName)
    if prompt then
        return prompt
    end

    error(
        string.format(
            '%s is missing a ProximityPrompt on part "%s".',
            STATIC_WORLD_ROOT_NAME,
            partName
        )
    )
end

local function resolveMarkerCFrame(root, markerName, fallback)
    local marker = findNamedDescendant(root, markerName)
    if marker and marker:IsA('BasePart') then
        return marker.CFrame
    end

    return fallback
end

local function buildFromStaticWorld(staticWorldRoot)
    local doorLeft = findNamedDescendant(staticWorldRoot, 'DoorLeft')
    local doorRight = findNamedDescendant(staticWorldRoot, 'DoorRight')
    local gatePrompt = requirePromptOnPart(staticWorldRoot, 'GateSwitch')

    local function openGate()
        if doorLeft and doorLeft:IsA('BasePart') then
            doorLeft.CanCollide = false
            doorLeft.Transparency = 1
        end

        if doorRight and doorRight:IsA('BasePart') then
            doorRight.CanCollide = false
            doorRight.Transparency = 1
        end

        gatePrompt.ActionText = 'Gate Open'
    end

    return {
        Root = staticWorldRoot,
        SpawnCFrame = resolveMarkerCFrame(staticWorldRoot, 'SpawnMarker', DEFAULT_SPAWN_CFRAME),
        ReturnCFrame = resolveMarkerCFrame(staticWorldRoot, 'ReturnMarker', DEFAULT_RETURN_CFRAME),
        MazeReturnCFrame = resolveMarkerCFrame(
            staticWorldRoot,
            'MazeReturnMarker',
            MAZE_RETURN_CFRAME
        ),
        OutdoorThresholdZ = tonumber(staticWorldRoot:GetAttribute('OutdoorThresholdZ'))
            or OUTDOOR_THRESHOLD_Z,
        ShopPrompt = requirePromptOnPart(staticWorldRoot, 'ShopTerminal'),
        LoadoutPrompt = requirePromptOnPart(staticWorldRoot, 'LoadoutBench'),
        GatePrompt = gatePrompt,
        MazePrompt = requirePromptOnPart(staticWorldRoot, 'MazeGateMarker'),
        OpenGate = openGate,
    }
end

function RunWorldBuilder.build()
    local staticWorldRoot = Workspace:FindFirstChild(STATIC_WORLD_ROOT_NAME)
    if staticWorldRoot and (staticWorldRoot:IsA('Folder') or staticWorldRoot:IsA('Model')) then
        return buildFromStaticWorld(staticWorldRoot)
    end

    local existing = Workspace:FindFirstChild(GENERATED_WORLD_ROOT_NAME)
    if existing then
        existing:Destroy()
    end

    local worldFolder = Instance.new('Folder')
    worldFolder.Name = GENERATED_WORLD_ROOT_NAME
    worldFolder.Parent = Workspace

    local house = CampHouseBuilder.build(worldFolder, createPart, createPromptPart)
    local outdoors = OutdoorAreaBuilder.build(worldFolder, createPart, createPromptPart)

    return {
        Root = worldFolder,
        SpawnCFrame = DEFAULT_SPAWN_CFRAME,
        ReturnCFrame = DEFAULT_RETURN_CFRAME,
        MazeReturnCFrame = MAZE_RETURN_CFRAME,
        OutdoorThresholdZ = OUTDOOR_THRESHOLD_Z,
        ShopPrompt = house.ShopPrompt,
        LoadoutPrompt = house.LoadoutPrompt,
        GatePrompt = house.GatePrompt,
        MazePrompt = outdoors.MazePrompt,
        OpenGate = house.OpenGate,
    }
end

RunWorldBuilder.SpawnCFrame = DEFAULT_SPAWN_CFRAME
RunWorldBuilder.ReturnCFrame = DEFAULT_RETURN_CFRAME
RunWorldBuilder.MazeReturnCFrame = MAZE_RETURN_CFRAME

return RunWorldBuilder
