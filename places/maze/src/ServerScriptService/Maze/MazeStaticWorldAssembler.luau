local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Workspace = game:GetService('Workspace')

local MazeChunkManifest = require(script.Parent.MazeChunkManifest)
local MazeStaticWorldContract = require(script.Parent.MazeStaticWorldContract)
local MazeStaticWorldOverlayManifest = require(script.Parent.MazeStaticWorldOverlayManifest)

local MazeStaticWorldAssembler = {}

local SCENERY_LIGHT_PROFILE_ATTRIBUTE = 'MazeSceneryLightProfile'
local SCENERY_LIGHT_PROFILES = table.freeze({
    Fire = table.freeze({
        Brightness = 5.5,
        Range = 40,
        Shadows = false,
        NameTokens = table.freeze({ 'fire', 'flame' }),
    }),
    Torch = table.freeze({
        Brightness = 4.5,
        Range = 32,
        Shadows = false,
        NameTokens = table.freeze({ 'torch' }),
    }),
})
local SCENERY_LIGHT_PROFILE_ORDER = table.freeze({ 'Fire', 'Torch' })

MazeStaticWorldAssembler.SceneryLightProfiles = SCENERY_LIGHT_PROFILES

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
    local existing = Workspace:FindFirstChild(MazeStaticWorldContract.RootName)
    if existing ~= nil then
        existing:Destroy()
    end

    local root = Instance.new('Folder')
    root.Name = MazeStaticWorldContract.RootName
    root.Parent = Workspace
    root:SetAttribute('BuildFingerprint', MazeStaticWorldContract.BuildFingerprint)

    local sceneryRoot = Instance.new('Folder')
    sceneryRoot.Name = MazeStaticWorldContract.SceneryFolderName
    sceneryRoot.Parent = root

    return root, sceneryRoot
end

local function isAuthoredSceneryLight(instance)
    return instance:IsA('PointLight') or instance:IsA('SpotLight') or instance:IsA('SurfaceLight')
end

local function findProfileFromAttribute(instance)
    local profileName = instance:GetAttribute(SCENERY_LIGHT_PROFILE_ATTRIBUTE)
    if type(profileName) ~= 'string' then
        return nil
    end

    local normalizedProfileName = string.lower(profileName)
    for _, profileKey in ipairs(SCENERY_LIGHT_PROFILE_ORDER) do
        if normalizedProfileName == string.lower(profileKey) then
            return SCENERY_LIGHT_PROFILES[profileKey]
        end
    end

    return nil
end

local function findProfileFromName(instance)
    local lowerName = string.lower(instance.Name)
    for _, profileName in ipairs(SCENERY_LIGHT_PROFILE_ORDER) do
        local profile = SCENERY_LIGHT_PROFILES[profileName]
        for _, token in ipairs(profile.NameTokens) do
            if string.find(lowerName, token, 1, true) ~= nil then
                return profile
            end
        end
    end

    return nil
end

local function findSceneryLightProfile(light, sceneryRoot)
    local current = light
    while current ~= nil and current ~= sceneryRoot do
        local profile = findProfileFromAttribute(current) or findProfileFromName(current)
        if profile ~= nil then
            return profile
        end

        current = current.Parent
    end

    return nil
end

local function applySceneryLightProfile(light, profile)
    light.Brightness = profile.Brightness
    light.Range = profile.Range
    light.Shadows = profile.Shadows
end

local function applySceneryLightingProfiles(sceneryRoot)
    for _, descendant in ipairs(sceneryRoot:GetDescendants()) do
        if isAuthoredSceneryLight(descendant) then
            local profile = findSceneryLightProfile(descendant, sceneryRoot)
            if profile ~= nil then
                applySceneryLightProfile(descendant, profile)
            end
        end
    end
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

local function applyRoomAttributes(room, definition)
    for attributeName, attributeValue in pairs(definition) do
        room:SetAttribute(attributeName, attributeValue)
    end
end

local function cloneOverlayAsset(overlayAsset, root)
    for _, child in ipairs(overlayAsset:GetChildren()) do
        local clone = child:Clone()
        clone.Parent = root
    end

    for _, partName in ipairs(MazeStaticWorldOverlayManifest.RootParts) do
        requireBasePart(root, partName, 'Maze static world overlay')
    end

    requirePrompt(
        requireBasePart(root, 'ReturnHoldPad', 'Maze static world overlay'),
        'Maze static world overlay'
    )

    for roomName, definition in pairs(MazeStaticWorldOverlayManifest.Rooms) do
        local room = root:FindFirstChild(roomName)
        if room == nil or not room:IsA('Model') then
            error(
                string.format(
                    'Maze static world overlay is missing required room model "%s".',
                    roomName
                ),
                0
            )
        end

        applyRoomAttributes(room, definition)
    end

    local lootRoom = root:FindFirstChild('Room_Loot')
    if lootRoom == nil then
        error('Maze static world overlay must define Room_Loot.', 0)
    end

    for _, nodeName in ipairs(MazeStaticWorldOverlayManifest.RequiredInteractionNodes) do
        local node = root:FindFirstChild(nodeName, true)
        if node == nil then
            error(
                string.format(
                    'Maze static world overlay is missing required interaction node "%s".',
                    nodeName
                ),
                0
            )
        end
    end

    -- MazeWorldScanner only binds gameplay nodes that are direct room children,
    -- so the overlay authoring contract keeps these prompt parts at that level.
    requirePrompt(
        requireBasePart(lootRoom, 'LootPrompt', 'Maze static world overlay'),
        'Maze static world overlay'
    )
    requirePrompt(
        requireBasePart(lootRoom, 'Doorway_East', 'Maze static world overlay'),
        'Maze static world overlay'
    )
end

function MazeStaticWorldAssembler.assemble()
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

    applySceneryLightingProfiles(sceneryRoot)

    return root
end

return MazeStaticWorldAssembler
