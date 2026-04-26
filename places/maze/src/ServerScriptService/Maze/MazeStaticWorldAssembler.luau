local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Workspace = game:GetService('Workspace')

local MazeChunkManifest = require(script.Parent.MazeChunkManifest)
local MazeStaticWorldContract = require(script.Parent.MazeStaticWorldContract)
local MazeStaticWorldOverlayManifest = require(script.Parent.MazeStaticWorldOverlayManifest)

local MazeStaticWorldAssembler = {}

local function requireFolder(parent, name, contextLabel)
    local child = parent:FindFirstChild(name)
    if child == nil or not child:IsA('Folder') then
        error(string.format('%s is missing required Folder "%s".', contextLabel, name), 0)
    end

    return child
end

local function requireAsset(parent, name, contextLabel)
    local child = parent:FindFirstChild(name)
    if child == nil or not (child:IsA('Folder') or child:IsA('Model')) then
        error(string.format('%s is missing required asset "%s".', contextLabel, name), 0)
    end

    return child
end

local function requireBasePart(parent, name, contextLabel)
    local child = parent:FindFirstChild(name)
    if child == nil or not child:IsA('BasePart') then
        error(string.format('%s is missing required part "%s".', contextLabel, name), 0)
    end

    return child
end

local function requirePrompt(part, contextLabel)
    local prompt = part:FindFirstChildOfClass('ProximityPrompt')
    if prompt == nil then
        error(
            string.format('%s part "%s" is missing a ProximityPrompt.', contextLabel, part.Name),
            0
        )
    end

    return prompt
end

local function getMazeAssets()
    local assetsRoot = requireFolder(
        ReplicatedStorage,
        MazeStaticWorldContract.AssetsRootName,
        'ReplicatedStorage'
    )
    local mazeAssets = requireFolder(
        assetsRoot,
        MazeStaticWorldContract.MazeAssetsFolderName,
        'ReplicatedStorage.Assets'
    )
    local chunkAssets = requireFolder(
        mazeAssets,
        MazeStaticWorldContract.ChunksFolderName,
        'ReplicatedStorage.Assets.Maze'
    )
    local overlayAssets = requireFolder(
        mazeAssets,
        MazeStaticWorldContract.OverlaysFolderName,
        'ReplicatedStorage.Assets.Maze'
    )

    return chunkAssets, overlayAssets
end

local function createRoot()
    local root = Instance.new('Folder')
    root.Name = MazeStaticWorldContract.RootName
    root.Parent = Workspace
    root:SetAttribute('BuildFingerprint', MazeStaticWorldContract.BuildFingerprint)

    local sceneryRoot = Instance.new('Folder')
    sceneryRoot.Name = MazeStaticWorldContract.SceneryFolderName
    sceneryRoot.Parent = root

    return root, sceneryRoot
end

local function requireSceneryRoot(root, contextLabel)
    local sceneryRoot = root:FindFirstChild(MazeStaticWorldContract.SceneryFolderName)
    if sceneryRoot == nil then
        sceneryRoot = Instance.new('Folder')
        sceneryRoot.Name = MazeStaticWorldContract.SceneryFolderName
        sceneryRoot.Parent = root
    elseif not sceneryRoot:IsA('Folder') then
        error(
            string.format(
                '%s must keep "%s" authored as a Folder.',
                contextLabel,
                MazeStaticWorldContract.SceneryFolderName
            ),
            0
        )
    end

    return sceneryRoot
end

local function stabilizeChunkGeometry(chunkModel)
    for _, descendant in ipairs(chunkModel:GetDescendants()) do
        if descendant:IsA('BasePart') then
            descendant.Anchored = true
            descendant.CanTouch = false
            descendant.CanQuery = true
            descendant:SetAttribute('IsScenery', true)
        end
    end
end

local function applyRoomAttributes(room, definition)
    for attributeName, attributeValue in pairs(definition) do
        room:SetAttribute(attributeName, attributeValue)
    end
end

local function validateRoot(root, contextLabel)
    if not (root:IsA('Folder') or root:IsA('Model')) then
        error(string.format('%s must be a Folder or Model.', contextLabel), 0)
    end

    root:SetAttribute('BuildFingerprint', MazeStaticWorldContract.BuildFingerprint)
    requireSceneryRoot(root, contextLabel)

    for _, partName in ipairs(MazeStaticWorldOverlayManifest.RootParts) do
        requireBasePart(root, partName, contextLabel)
    end

    requirePrompt(requireBasePart(root, 'ReturnHoldPad', contextLabel), contextLabel)

    for roomName, definition in pairs(MazeStaticWorldOverlayManifest.Rooms) do
        local room = root:FindFirstChild(roomName)
        if room == nil or not room:IsA('Model') then
            error(
                string.format('%s is missing required room model "%s".', contextLabel, roomName),
                0
            )
        end

        applyRoomAttributes(room, definition)
    end

    local lootRoom = root:FindFirstChild('Room_Loot')
    if lootRoom == nil then
        error(string.format('%s must define Room_Loot.', contextLabel), 0)
    end

    for _, nodeName in ipairs(MazeStaticWorldOverlayManifest.RequiredInteractionNodes) do
        local node = root:FindFirstChild(nodeName, true)
        if node == nil then
            error(
                string.format(
                    '%s is missing required interaction node "%s".',
                    contextLabel,
                    nodeName
                ),
                0
            )
        end
    end

    requirePrompt(requireBasePart(lootRoom, 'LootPrompt', contextLabel), contextLabel)
    requirePrompt(requireBasePart(lootRoom, 'Doorway_East', contextLabel), contextLabel)

    return root
end

local function cloneChunkAsset(chunkAsset, chunkDefinition, sceneryRoot)
    if not chunkAsset:IsA('Model') then
        error(
            string.format(
                'Maze chunk asset "%s" must be authored as a Model.',
                chunkDefinition.AssetName
            ),
            0
        )
    end

    local clone = chunkAsset:Clone()
    clone.Name = chunkDefinition.ChunkId
    clone.Parent = sceneryRoot
    stabilizeChunkGeometry(clone)
    if chunkDefinition.Transform ~= nil then
        clone:PivotTo(chunkDefinition.Transform)
    end
end

local function cloneOverlayAsset(overlayAsset, root)
    for _, child in ipairs(overlayAsset:GetChildren()) do
        local clone = child:Clone()
        clone.Parent = root
    end
end

function MazeStaticWorldAssembler.assemble()
    local existing = Workspace:FindFirstChild(MazeStaticWorldContract.RootName)
    if existing ~= nil then
        return validateRoot(existing, 'Authored MazeStaticWorld')
    end

    local chunkAssets, overlayAssets = getMazeAssets()
    local root, sceneryRoot = createRoot()

    local overlayAsset = requireAsset(
        overlayAssets,
        MazeStaticWorldContract.OverlayAssetName,
        'ReplicatedStorage.Assets.Maze.Overlays'
    )
    cloneOverlayAsset(overlayAsset, root)

    local enabledChunkCount = 0
    for _, chunkDefinition in ipairs(MazeChunkManifest) do
        if chunkDefinition.Enabled ~= false then
            local chunkAsset = requireAsset(
                chunkAssets,
                chunkDefinition.AssetName,
                'ReplicatedStorage.Assets.Maze.Chunks'
            )
            cloneChunkAsset(chunkAsset, chunkDefinition, sceneryRoot)
            enabledChunkCount += 1
        end
    end

    if enabledChunkCount == 0 then
        error('Maze chunk manifest must enable at least one geometry chunk.', 0)
    end

    return validateRoot(root, 'Maze scaffold static world')
end

return MazeStaticWorldAssembler
