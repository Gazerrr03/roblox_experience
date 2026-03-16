local Workspace = game:GetService('Workspace')
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Packages = ReplicatedStorage:WaitForChild('Packages')
local Gameplay = require(Packages:WaitForChild('Gameplay'))

local MazeBuilder = Gameplay.ProcGen.MazeBuilder

local LocalDebugMazeWorldBuilder = {}

local DEFAULT_ORIGIN_OFFSET = Vector3.new(0, 0, 420)

local ROOM_KIND_COLORS = {
    Camp = Color3.fromRGB(83, 126, 78),
    Loot = Color3.fromRGB(88, 92, 112),
    Extraction = Color3.fromRGB(145, 119, 73),
}

local function createPart(config, parent)
    local part = Instance.new('Part')
    part.Name = config.Name
    part.Anchored = true
    part.Size = config.Size
    part.CFrame = config.CFrame
    part.Color = config.Color
    part.Material = config.Material or Enum.Material.Slate
    part.Transparency = config.Transparency or 0
    part.CanCollide = config.CanCollide ~= false
    part.Parent = parent
    return part
end

local function createPromptPart(config, parent)
    local part = createPart({
        Name = config.Name,
        Size = config.Size or Vector3.new(4, 1, 4),
        CFrame = config.CFrame,
        Color = config.Color,
        Material = config.Material or Enum.Material.Neon,
        Transparency = config.Transparency or 0,
        CanCollide = config.CanCollide,
    }, parent)

    local prompt = Instance.new('ProximityPrompt')
    prompt.ActionText = config.ActionText
    prompt.ObjectText = config.ObjectText
    prompt.HoldDuration = 0
    prompt.MaxActivationDistance = config.MaxActivationDistance or 12
    prompt.RequiresLineOfSight = false
    prompt.Parent = part

    return part, prompt
end

function LocalDebugMazeWorldBuilder.build(seed, config, originOffset)
    local existing = Workspace:FindFirstChild('LocalDebugMazeWorld')
    if existing then
        existing:Destroy()
    end

    local origin = originOffset or DEFAULT_ORIGIN_OFFSET
    local layout = MazeBuilder.build(seed, config)
    local roomSize = config.RoomSize or Vector3.new(28, 16, 28)

    local worldFolder = Instance.new('Folder')
    worldFolder.Name = 'LocalDebugMazeWorld'
    worldFolder.Parent = Workspace

    local campRoom = layout.Rooms[layout.CampRoomId]

    local function worldPosition(roomPosition)
        return roomPosition + origin
    end

    for roomId, room in pairs(layout.Rooms) do
        local center = worldPosition(room.Position)
        local roomFolder = Instance.new('Folder')
        roomFolder.Name = roomId
        roomFolder.Parent = worldFolder

        createPart({
            Name = 'Floor',
            Size = Vector3.new(roomSize.X, 1, roomSize.Z),
            CFrame = CFrame.new(center + Vector3.new(0, -0.5, 0)),
            Color = ROOM_KIND_COLORS[room.Kind] or Color3.fromRGB(112, 112, 112),
            Material = Enum.Material.Slate,
        }, roomFolder)

        createPart({
            Name = 'Boundary',
            Size = Vector3.new(roomSize.X, 8, roomSize.Z),
            CFrame = CFrame.new(center + Vector3.new(0, 4, 0)),
            Color = Color3.fromRGB(58, 62, 70),
            Material = Enum.Material.Slate,
            Transparency = 0.85,
            CanCollide = false,
        }, roomFolder)
    end

    local _, returnPrompt = createPromptPart({
        Name = 'ReturnToCampMarker',
        CFrame = CFrame.new(worldPosition(campRoom.Position) + Vector3.new(0, 0.5, -10)),
        Color = Color3.fromRGB(77, 147, 196),
        ActionText = 'Return',
        ObjectText = 'Return To Camp (Local Debug)',
        MaxActivationDistance = 14,
        CanCollide = false,
    }, worldFolder)

    return {
        Root = worldFolder,
        SpawnCFrame = CFrame.new(worldPosition(campRoom.Position) + Vector3.new(0, 4, 0)),
        ReturnPrompt = returnPrompt,
        FindRoomByPosition = function(position)
            local nearestRoom = nil
            local nearestDistance = math.huge

            for _, room in pairs(layout.Rooms) do
                local distance = (worldPosition(room.Position) - position).Magnitude
                if distance < nearestDistance then
                    nearestDistance = distance
                    nearestRoom = room
                end
            end

            return nearestRoom
        end,
    }
end

return LocalDebugMazeWorldBuilder
