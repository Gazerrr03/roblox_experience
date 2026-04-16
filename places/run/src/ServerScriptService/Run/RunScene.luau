local RunAreaResolver = require(script.Parent.RunAreaResolver)
local RunInteractionRegistry = require(script.Parent.RunInteractionRegistry)
local RunOceanTrigger = require(script.Parent.RunOceanTrigger)
local RunPortal = require(script.Parent.RunPortal)
local RunSpawnPoint = require(script.Parent.RunSpawnPoint)
local RunStaticWorldContract = require(script.Parent.RunStaticWorldContract)
local RunTerminal = require(script.Parent.RunTerminal)
local ShipDoors = require(script.Parent.ShipDoors)

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

local function requireContainer(parent, name, contextLabel)
    local child = parent:FindFirstChild(name)
    if child == nil or not (child:IsA('Folder') or child:IsA('Model')) then
        error(string.format('%s is missing required container "%s".', contextLabel, name), 0)
    end

    return child
end

local function findOptionalContainer(parent, name, contextLabel)
    local child = parent:FindFirstChild(name)
    if child == nil then
        return nil
    end

    if not (child:IsA('Folder') or child:IsA('Model')) then
        error(
            string.format(
                '%s optional container "%s" must be a Folder or Model.',
                contextLabel,
                name
            ),
            0
        )
    end

    return child
end

local function collectBaseParts(root)
    local parts = {}

    for _, descendant in ipairs(root:GetDescendants()) do
        if descendant:IsA('BasePart') then
            table.insert(parts, descendant)
        end
    end

    return parts
end

local function buildSpawnGroundParams(sceneCollisionRoot, shipCollisionRoot, terrainMesh)
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Include
    local instances = { sceneCollisionRoot, shipCollisionRoot }
    if terrainMesh and terrainMesh:IsA('BasePart') then
        table.insert(instances, terrainMesh)
    end
    raycastParams.FilterDescendantsInstances = instances
    return raycastParams
end

local function groundedSpawnCFrame(part, raycastParams)
    local origin = part.Position + Vector3.new(0, (part.Size.Y * 0.5) + 2, 0)
    local result = workspace:Raycast(
        origin,
        Vector3.new(0, -RunStaticWorldContract.SpawnGroundCheckDepth, 0),
        raycastParams
    )

    if result and result.Instance and result.Instance.CanCollide and result.Normal.Y > 0.5 then
        local groundedPosition = Vector3.new(
            part.Position.X,
            result.Position.Y + RunStaticWorldContract.SpawnLiftStuds,
            part.Position.Z
        )
        return CFrame.fromMatrix(
            groundedPosition,
            part.CFrame.XVector,
            part.CFrame.YVector,
            part.CFrame.ZVector
        )
    end

    return part.CFrame
end

function RunScene.new(root)
    if not (root:IsA('Folder') or root:IsA('Model')) then
        error('RunStaticWorld must be a Folder or Model.', 0)
    end

    local outdoorThresholdZ = root:GetAttribute('OutdoorThresholdZ')
    if type(outdoorThresholdZ) ~= 'number' then
        error('RunStaticWorld is missing required attribute "OutdoorThresholdZ".', 0)
    end

    local collisionRoot =
        requireContainer(root, RunStaticWorldContract.CollisionRootName, 'RunStaticWorld')
    local sceneCollisionRoot = requireContainer(
        collisionRoot,
        RunStaticWorldContract.SceneCollisionName,
        'RunStaticWorld Collision'
    )
    local shipCollisionRoot = findOptionalContainer(
        collisionRoot,
        RunStaticWorldContract.ShipCollisionName,
        'RunStaticWorld Collision'
    )
    local triggersRoot =
        requireContainer(root, RunStaticWorldContract.TriggersRootName, 'RunStaticWorld')
    local oceanTriggerRoot = requireContainer(
        triggersRoot,
        RunStaticWorldContract.OceanTriggerName,
        'RunStaticWorld Triggers'
    )
    -- Find terrain mesh for spawn raycast: RunTerrain_Main.Scene.RunTerrain_OriginalHigh.RunTerrain_OriginalHighMesh
    local terrainRoot = root:FindFirstChild('RunTerrain_Main')
    local terrainMesh = nil
    if terrainRoot and terrainRoot:IsA('Model') then
        local sceneFolder = terrainRoot:FindFirstChild('Scene')
        if sceneFolder then
            local terrainGroup = sceneFolder:FindFirstChild('RunTerrain_OriginalHigh')
            if terrainGroup then
                terrainMesh = terrainGroup:FindFirstChild('RunTerrain_OriginalHighMesh')
            end
        end
    end
    -- Initialize ship doors: find the Sci-Fi Space Ship model under terrainRoot
    local allDoors = {}
    local shipModel = terrainRoot and terrainRoot:FindFirstChild('Sci-Fi Space Ship')
    if shipModel then
        allDoors = ShipDoors.init(shipModel) or {}
    end
    local spawnGroundParams =
        buildSpawnGroundParams(sceneCollisionRoot, shipCollisionRoot, terrainMesh)
    local spawnPoints = {}
    local spawnCFramesByKind = {}
    for markerName, kind in pairs(REQUIRED_MARKERS) do
        local markerPart = requirePart(root, markerName)
        spawnPoints[kind] = RunSpawnPoint.new(kind, markerPart)
        spawnCFramesByKind[kind] = groundedSpawnCFrame(markerPart, spawnGroundParams)
    end

    local terminals = {}
    for partName, kind in pairs(REQUIRED_PROMPT_PARTS) do
        terminals[kind] = RunTerminal.new(kind, requirePart(root, partName))
    end
    local startGamePromptPart = root:FindFirstChild('StartGamePrompt')
    if startGamePromptPart and startGamePromptPart:IsA('BasePart') then
        terminals.StartGame = RunTerminal.new('StartGame', startGamePromptPart)
    end

    -- StartGamePrompt is optional; only create if the part exists in the static world
    local startGamePart = root:FindFirstChild('StartGamePrompt')
    if startGamePart and startGamePart:IsA('BasePart') then
        terminals.StartGame = RunTerminal.new('StartGame', startGamePart)
    end

    local mazePortal = RunPortal.new(RunPortal.Kind.MazeGate, requirePart(root, 'MazeGateMarker'))
    local oceanTriggers = {}

    for _, part in ipairs(collectBaseParts(oceanTriggerRoot)) do
        table.insert(oceanTriggers, RunOceanTrigger.new(part))
    end

    local self = setmetatable({
        Root = root,
        SpawnPoints = spawnPoints,
        Terminals = terminals,
        MazePortal = mazePortal,
        Collision = {
            Scene = sceneCollisionRoot,
            Ship = shipCollisionRoot,
        },
        OceanTriggers = oceanTriggers,
        OutdoorThresholdZ = outdoorThresholdZ,
        AreaResolver = nil,
        ShipDoors = allDoors,
        SpawnCFramesByKind = spawnCFramesByKind,

        SpawnCFrame = spawnCFramesByKind[RunSpawnPoint.Kind.Spawn],
        ReturnCFrame = spawnCFramesByKind[RunSpawnPoint.Kind.Return],
        MazeReturnCFrame = spawnCFramesByKind[RunSpawnPoint.Kind.MazeReturn],
        ShopPrompt = terminals.Shop.Prompt,
        SellPrompt = terminals.Sell.Prompt,
        ObjectivePrompt = terminals.Objective.Prompt,
        BookPrompt = terminals.Objective.Prompt,
        LoadoutPrompt = terminals.Loadout.Prompt,
        UgcLabPrompt = terminals.UgcLab.Prompt,
        GatePrompt = terminals.Gate.Prompt,
        StartGamePrompt = terminals.StartGame and terminals.StartGame.Prompt or nil,
        MazePrompt = mazePortal.Prompt,
    }, RunScene)

    self.AreaResolver = RunAreaResolver.new(self)

    return self
end

function RunScene:getSpawnCFrame(kind)
    local spawnCFrame = self.SpawnCFramesByKind[kind]
    if spawnCFrame == nil then
        error(string.format('Unknown run spawn point kind %q.', tostring(kind)), 0)
    end

    return spawnCFrame
end

function RunScene:getAreaForPosition(position)
    return self.AreaResolver:getAreaForPosition(position)
end

function RunScene:openGate()
    self.Terminals.Gate.Prompt.ActionText = 'Gate Open'
end

function RunScene:lockAllShipDoors()
    for _, door in ipairs(self.ShipDoors or {}) do
        door:lock()
    end
end

function RunScene:unlockAllShipDoors()
    for _, door in ipairs(self.ShipDoors or {}) do
        door:unlock()
    end
end

function RunScene:bindInteractions(handlers)
    local registry = RunInteractionRegistry.new()
    registry:bindScene(self, handlers)
    return registry
end

RunScene.OpenGate = RunScene.openGate

return RunScene
