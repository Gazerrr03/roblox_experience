local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Packages = ReplicatedStorage:WaitForChild('Packages')
local PlaceModules = ReplicatedStorage:WaitForChild('PlaceModules'):WaitForChild('Maze')

local MazeWorldScanner = require(
    Packages:WaitForChild('Shared'):WaitForChild('Runtime'):WaitForChild('MazeWorldScanner')
)
local MazeScene = require(PlaceModules:WaitForChild('MazeScene'))
local MazeStaticWorldAssembler = require(PlaceModules:WaitForChild('MazeStaticWorldAssembler'))

local MazeContentWorldBuilder = {}

local function placePartAt(part, targetPosition)
    if not (part and part:IsA('BasePart')) then
        return
    end

    part.CFrame = CFrame.new(targetPosition) * part.CFrame.Rotation
end

local function placeModelAt(model, targetPosition)
    if not (model and model:IsA('Model')) then
        return
    end

    model:PivotTo(CFrame.new(targetPosition) * model:GetPivot().Rotation)
end

local function findDescendant(root, name)
    if root == nil then
        return nil
    end

    return root:FindFirstChild(name, true)
end

local function styleAcceptancePart(part, style)
    if not (part and part:IsA('BasePart')) then
        return
    end

    local config = style or {}
    part.Transparency = config.Transparency or 0.15
    part.Material = config.Material or Enum.Material.Neon
    part.Color = config.Color or Color3.fromRGB(111, 255, 233)

    if typeof(config.Size) == 'Vector3' then
        part.Size = config.Size
    end

    if config.Shape ~= nil then
        part.Shape = config.Shape
    end
end

local function placeSpawnFolderAt(folder, targetPosition)
    if not (folder and folder:IsA('Folder')) then
        return
    end

    for _, child in ipairs(folder:GetChildren()) do
        if child:IsA('BasePart') then
            placePartAt(child, targetPosition)
        end
    end
end

local function applyAcceptanceLayout(staticWorldRoot)
    local spawnMarker = staticWorldRoot:FindFirstChild('SpawnMarker')
    if not (spawnMarker and spawnMarker:IsA('BasePart')) then
        return
    end

    local spawnPosition = spawnMarker.Position

    local lootRoom = staticWorldRoot:FindFirstChild('Room_Loot')
    local campRoom = staticWorldRoot:FindFirstChild('Room_Camp')
    placeModelAt(campRoom, spawnPosition + Vector3.new(-22, 0, -10))
    placeModelAt(lootRoom, spawnPosition + Vector3.new(28, 0, -6))

    -- Keep the authored shell mostly intact, but pull the acceptance interaction points
    -- into a short walk around spawn so content verification is fast and obvious.
    placePartAt(
        staticWorldRoot:FindFirstChild('ReturnHoldPad'),
        spawnPosition + Vector3.new(-8, 0, 8)
    )
    placePartAt(
        findDescendant(staticWorldRoot, 'LootPrompt'),
        spawnPosition + Vector3.new(10, 0, 2)
    )
    placePartAt(
        findDescendant(staticWorldRoot, 'LootSocket_1'),
        spawnPosition + Vector3.new(12, 0, 2)
    )
    placePartAt(
        findDescendant(staticWorldRoot, 'Doorway_East'),
        spawnPosition + Vector3.new(20, 0, 2)
    )
    local monsterSpawns = lootRoom and lootRoom:FindFirstChild('MonsterSpawns')
    placeSpawnFolderAt(monsterSpawns, spawnPosition + Vector3.new(72, 0, -24))

    styleAcceptancePart(staticWorldRoot:FindFirstChild('ReturnHoldPad'), {
        Color = Color3.fromRGB(79, 181, 255),
        Material = Enum.Material.ForceField,
        Size = Vector3.new(5, 0.5, 5),
        Transparency = 0.2,
    })
    styleAcceptancePart(findDescendant(staticWorldRoot, 'LootPrompt'), {
        Color = Color3.fromRGB(255, 205, 84),
        Material = Enum.Material.Neon,
        Size = Vector3.new(2.5, 2.5, 2.5),
        Shape = Enum.PartType.Ball,
        Transparency = 0.05,
    })
    styleAcceptancePart(findDescendant(staticWorldRoot, 'LootSocket_1'), {
        Color = Color3.fromRGB(255, 245, 181),
        Material = Enum.Material.Neon,
        Size = Vector3.new(1.5, 1.5, 1.5),
        Shape = Enum.PartType.Ball,
        Transparency = 0.15,
    })
    styleAcceptancePart(findDescendant(staticWorldRoot, 'Doorway_East'), {
        Color = Color3.fromRGB(255, 129, 76),
        Material = Enum.Material.ForceField,
        Transparency = 0.3,
    })
end

function MazeContentWorldBuilder.build()
    local staticWorldRoot = MazeStaticWorldAssembler.assemble()

    if not (staticWorldRoot:IsA('Folder') or staticWorldRoot:IsA('Model')) then
        error('MazeStaticWorld must be a Folder or Model.', 0)
    end

    -- Keep authored interactions clustered around spawn in the content harness so
    -- loot, doors, and return are easy to validate in one short pass.
    applyAcceptanceLayout(staticWorldRoot)

    return MazeScene.new(MazeWorldScanner.BuildStaticWorld(staticWorldRoot))
end

return MazeContentWorldBuilder
