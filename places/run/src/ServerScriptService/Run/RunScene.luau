local RunAreaResolver = require(script.Parent.RunAreaResolver)
local RunDoor = require(script.Parent.RunDoor)
local RunInteractionRegistry = require(script.Parent.RunInteractionRegistry)
local RunPortal = require(script.Parent.RunPortal)
local RunSpawnPoint = require(script.Parent.RunSpawnPoint)
local RunTerminal = require(script.Parent.RunTerminal)

local RunScene = {}
RunScene.__index = RunScene

local REQUIRED_PROMPT_PARTS = table.freeze({
    ShopTerminal = 'Shop',
    SalvageTerminal = 'Sell',
    ObjectiveBoard = 'Objective',
    LoadoutBench = 'Loadout',
    UgcLabConsole = 'UgcLab',
    GateSwitch = 'Gate',
})

local REQUIRED_MARKERS = table.freeze({
    SpawnMarker = RunSpawnPoint.Kind.Spawn,
    ReturnMarker = RunSpawnPoint.Kind.Return,
    MazeReturnMarker = RunSpawnPoint.Kind.MazeReturn,
})

local function findNamedDescendant(root, name)
    for _, descendant in ipairs(root:GetDescendants()) do
        if descendant.Name == name then
            return descendant
        end
    end

    return nil
end

local function requirePart(root, name)
    local part = findNamedDescendant(root, name)
    if part == nil or not part:IsA('BasePart') then
        error(string.format('RunStaticWorld is missing required part "%s".', name), 0)
    end

    return part
end

function RunScene.new(root)
    if not (root:IsA('Folder') or root:IsA('Model')) then
        error('RunStaticWorld must be a Folder or Model.', 0)
    end

    local outdoorThresholdZ = root:GetAttribute('OutdoorThresholdZ')
    if type(outdoorThresholdZ) ~= 'number' then
        error('RunStaticWorld is missing required attribute "OutdoorThresholdZ".', 0)
    end

    local spawnPoints = {}
    for markerName, kind in pairs(REQUIRED_MARKERS) do
        spawnPoints[kind] = RunSpawnPoint.new(kind, requirePart(root, markerName))
    end

    local terminals = {}
    for partName, kind in pairs(REQUIRED_PROMPT_PARTS) do
        terminals[kind] = RunTerminal.new(kind, requirePart(root, partName))
    end

    local mazePortal = RunPortal.new(RunPortal.Kind.MazeGate, requirePart(root, 'MazeGateMarker'))
    local gateDoor = RunDoor.new('TempleGate', {
        requirePart(root, 'DoorLeft'),
        requirePart(root, 'DoorRight'),
    })

    local self = setmetatable({
        Root = root,
        SpawnPoints = spawnPoints,
        Terminals = terminals,
        MazePortal = mazePortal,
        GateDoor = gateDoor,
        OutdoorThresholdZ = outdoorThresholdZ,
        AreaResolver = nil,

        SpawnCFrame = spawnPoints[RunSpawnPoint.Kind.Spawn]:getCFrame(),
        ReturnCFrame = spawnPoints[RunSpawnPoint.Kind.Return]:getCFrame(),
        MazeReturnCFrame = spawnPoints[RunSpawnPoint.Kind.MazeReturn]:getCFrame(),
        ShopPrompt = terminals.Shop.Prompt,
        SellPrompt = terminals.Sell.Prompt,
        ObjectivePrompt = terminals.Objective.Prompt,
        LoadoutPrompt = terminals.Loadout.Prompt,
        UgcLabPrompt = terminals.UgcLab.Prompt,
        GatePrompt = terminals.Gate.Prompt,
        MazePrompt = mazePortal.Prompt,
    }, RunScene)

    self.AreaResolver = RunAreaResolver.new(self)

    return self
end

function RunScene:getSpawnCFrame(kind)
    local spawnPoint = self.SpawnPoints[kind]
    if spawnPoint == nil then
        error(string.format('Unknown run spawn point kind %q.', tostring(kind)), 0)
    end

    return spawnPoint:getCFrame()
end

function RunScene:getAreaForPosition(position)
    return self.AreaResolver:getAreaForPosition(position)
end

function RunScene:openGate()
    self.GateDoor:open()
    self.Terminals.Gate.Prompt.ActionText = 'Gate Open'
end

function RunScene:bindInteractions(handlers)
    local registry = RunInteractionRegistry.new()
    registry:bindScene(self, handlers)
    return registry
end

RunScene.OpenGate = RunScene.openGate

return RunScene
