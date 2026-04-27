local MazeCollisionOverlay = {}

local COLLISION_FOLDER_NAME = 'Collision'
local PRIMARY_MAP_MODEL_NAME = 'maze-roblox'
local LEGACY_MAP_MODEL_NAME = 'maze00'
local COLLISION_BOX_FOLDER_NAME = 'CollisionBoxes'
local GENERATED_ATTRIBUTE = 'GeneratedByMazeCollisionOverlay'
local SOURCE_MESH_ATTRIBUTE = 'SourceMeshName'
local SCENERY_ATTRIBUTE = 'IsScenery'
local MIN_FLOOR_SPAN = 6
local MAX_FLOOR_THICKNESS = 4
local MIN_WALL_HEIGHT = 6
local MIN_WALL_SPAN = 8
local MAX_WALL_THICKNESS = 5
local MIN_COLLIDER_THICKNESS = 1
local SPAWN_LIGHT_NAME = 'SpawnMarkerCyanGuideLight'
local SPAWN_FILL_LIGHT_NAME = 'SpawnMarkerCyanFillLight'
local SPAWN_MARKER_COLOR = Color3.fromRGB(0, 255, 255)
local SPAWN_MARKER_TRANSPARENCY = 0.2
local SPAWN_LIGHT_RANGE = 42
local SPAWN_LIGHT_BRIGHTNESS = 3.2
local SPAWN_FILL_LIGHT_RANGE = 24
local SPAWN_FILL_LIGHT_BRIGHTNESS = 0.85

local function isDoorLikeName(name)
    local lowerName = string.lower(tostring(name or ''))
    return string.find(lowerName, 'door', 1, true) ~= nil
end

local function isSemanticPart(part)
    return part.Name == 'SpawnMarker'
        or part.Name == 'ReturnHoldPad'
        or string.match(part.Name, '^SpawnPoint_') ~= nil
        or string.match(part.Name, '^LootSocket_') ~= nil
        or string.match(part.Name, '^Doorway_') ~= nil
end

local function sanitizeName(name)
    return string.gsub(tostring(name), '[^%w_%-]+', '_')
end

local function getMapModel(staticWorldRoot)
    local collisionRoot = staticWorldRoot:FindFirstChild(COLLISION_FOLDER_NAME)
    if collisionRoot == nil then
        return nil
    end

    return collisionRoot:FindFirstChild(PRIMARY_MAP_MODEL_NAME)
        or collisionRoot:FindFirstChild(LEGACY_MAP_MODEL_NAME)
end

local function ensurePointLight(parent, name, range, brightness)
    local light = parent:FindFirstChild(name)
    if light == nil or not light:IsA('PointLight') then
        if light ~= nil then
            light:Destroy()
        end

        light = Instance.new('PointLight')
        light.Name = name
        light.Parent = parent
    end

    light.Color = SPAWN_MARKER_COLOR
    light.Range = range
    light.Brightness = brightness
    light.Shadows = false
    light.Enabled = true

    return light
end

local function styleSpawnMarker(staticWorldRoot)
    local spawnMarker = staticWorldRoot:FindFirstChild('SpawnMarker', true)
    if spawnMarker == nil or not spawnMarker:IsA('BasePart') then
        return nil
    end

    spawnMarker.Material = Enum.Material.Neon
    spawnMarker.Color = SPAWN_MARKER_COLOR
    spawnMarker.Transparency = SPAWN_MARKER_TRANSPARENCY
    spawnMarker.CanCollide = false
    spawnMarker.CanQuery = true
    spawnMarker.CanTouch = false

    ensurePointLight(spawnMarker, SPAWN_LIGHT_NAME, SPAWN_LIGHT_RANGE, SPAWN_LIGHT_BRIGHTNESS)
    ensurePointLight(
        spawnMarker,
        SPAWN_FILL_LIGHT_NAME,
        SPAWN_FILL_LIGHT_RANGE,
        SPAWN_FILL_LIGHT_BRIGHTNESS
    )

    return spawnMarker
end

local function classifyCollisionPart(part)
    local size = part.Size
    local xzSpan = math.max(size.X, size.Z)
    local horizontalSpan = math.min(size.X, size.Z)
    local thinnestAxis = math.min(size.X, size.Z)

    if size.Y <= MAX_FLOOR_THICKNESS and horizontalSpan >= MIN_FLOOR_SPAN then
        return 'Floor'
    end

    if
        size.Y >= MIN_WALL_HEIGHT
        and xzSpan >= MIN_WALL_SPAN
        and thinnestAxis <= MAX_WALL_THICKNESS
    then
        return 'Wall'
    end

    return nil
end

local function getColliderSize(sourcePart, kind)
    local size = sourcePart.Size
    if kind == 'Floor' then
        return Vector3.new(size.X, math.max(size.Y, MIN_COLLIDER_THICKNESS), size.Z)
    end

    return Vector3.new(
        math.max(size.X, MIN_COLLIDER_THICKNESS),
        math.max(size.Y, MIN_COLLIDER_THICKNESS),
        math.max(size.Z, MIN_COLLIDER_THICKNESS)
    )
end

local function createCollisionBox(folder, sourcePart, kind, index)
    local box = Instance.new('Part')
    box.Name = string.format('%sBox_%03d_%s', kind, index, sanitizeName(sourcePart.Name))
    box.Size = getColliderSize(sourcePart, kind)
    box.CFrame = sourcePart.CFrame
    box.Anchored = true
    box.CanCollide = true
    box.CanQuery = true
    box.CanTouch = false
    box.Transparency = 1
    box.CastShadow = false
    box:SetAttribute(GENERATED_ATTRIBUTE, true)
    box:SetAttribute(SOURCE_MESH_ATTRIBUTE, sourcePart.Name)
    box.Parent = folder
    return box
end

local function resetGeneratedCollisionBoxes(folder)
    for _, child in ipairs(folder:GetChildren()) do
        if child:GetAttribute(GENERATED_ATTRIBUTE) == true then
            child:Destroy()
        end
    end
end

local function prepareMapPart(part)
    part.Anchored = true
    part.CanQuery = true
    part.CanTouch = false

    if isDoorLikeName(part.Name) then
        -- Imported door meshes often have a solid simplified collision hull that fills the doorway.
        part.CanCollide = false
        return false
    end

    part.CanCollide = true
    return true
end

local function ensureCollisionBoxes(mapModel)
    local collisionBoxes = mapModel:FindFirstChild(COLLISION_BOX_FOLDER_NAME)
    if collisionBoxes == nil then
        collisionBoxes = Instance.new('Folder')
        collisionBoxes.Name = COLLISION_BOX_FOLDER_NAME
        collisionBoxes.Parent = mapModel
    end

    collisionBoxes:SetAttribute(SCENERY_ATTRIBUTE, true)
    resetGeneratedCollisionBoxes(collisionBoxes)

    local created = 0
    local floorCount = 0
    local wallCount = 0

    for _, descendant in ipairs(mapModel:GetDescendants()) do
        if descendant:IsA('BasePart') and not descendant:IsDescendantOf(collisionBoxes) then
            local usableForGeneratedCollision = prepareMapPart(descendant)
            if usableForGeneratedCollision and not isSemanticPart(descendant) then
                local kind = classifyCollisionPart(descendant)
                if kind ~= nil then
                    created += 1
                    createCollisionBox(collisionBoxes, descendant, kind, created)

                    if kind == 'Floor' then
                        floorCount += 1
                    elseif kind == 'Wall' then
                        wallCount += 1
                    end
                end
            end
        end
    end

    return {
        Folder = collisionBoxes,
        Created = created,
        Floors = floorCount,
        Walls = wallCount,
    }
end

function MazeCollisionOverlay.apply(staticWorldRoot)
    if staticWorldRoot == nil then
        return {
            Applied = false,
            Reason = 'MissingStaticWorldRoot',
        }
    end

    local spawnMarker = styleSpawnMarker(staticWorldRoot)
    local mapModel = getMapModel(staticWorldRoot)
    if mapModel == nil then
        return {
            Applied = false,
            Reason = 'MissingMazeMapCollisionRoot',
            SpawnMarker = spawnMarker,
        }
    end

    local collisionSummary = ensureCollisionBoxes(mapModel)
    return {
        Applied = true,
        MapModel = mapModel,
        SpawnMarker = spawnMarker,
        CollisionBoxes = collisionSummary.Folder,
        CreatedCollisionBoxes = collisionSummary.Created,
        FloorCollisionBoxes = collisionSummary.Floors,
        WallCollisionBoxes = collisionSummary.Walls,
    }
end

return MazeCollisionOverlay
