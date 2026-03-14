local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Workspace = game:GetService('Workspace')

local OPPOSITE = { North = 'South', South = 'North', East = 'West', West = 'East' }
local DIR_OFFSET = {
    North = Vector3.new(0, 0, -20),
    South = Vector3.new(0, 0, 20),
    East = Vector3.new(20, 0, 0),
    West = Vector3.new(-20, 0, 0),
}
local DOOR_OFFSET = {
    North = Vector3.new(0, 3, -10),
    South = Vector3.new(0, 3, 10),
    East = Vector3.new(10, 3, 0),
    West = Vector3.new(-10, 3, 0),
}

local ROOM_SIZE = 20
local TARGET_ROOMS = 8
local WALL_HEIGHT = 6
local rng = Random.new()

local templates = {
    ReplicatedStorage:WaitForChild('RoomA'),
    ReplicatedStorage:WaitForChild('RoomB'),
    ReplicatedStorage:WaitForChild('RoomC'),
}

local function key(gx, gz)
    return string.format('%d,%d', gx, gz)
end

local function parseDoors(raw)
    local result = {}
    for token in string.gmatch(raw or '', '[^,%s]+') do
        result[token] = true
    end
    return result
end

local function rotateDoor(doorName, rotation)
    if rotation % 360 == 0 then
        return doorName
    end
    if rotation % 360 == 180 then
        return OPPOSITE[doorName]
    end
    return doorName
end

local function rotateDoorSet(doors, rotation)
    local result = {}
    for doorName in pairs(doors) do
        result[rotateDoor(doorName, rotation)] = true
    end
    return result
end

local function gridToWorld(gx, gz)
    return Vector3.new(gx * ROOM_SIZE, 0, gz * ROOM_SIZE)
end

local baseTemplateDoors = {}
for _, template in ipairs(templates) do
    baseTemplateDoors[template] = parseDoors(template:GetAttribute('Doors'))
end

local variants = {}
for _, template in ipairs(templates) do
    for _, rotation in ipairs({ 0, 180 }) do
        table.insert(variants, {
            template = template,
            rotation = rotation,
            doors = rotateDoorSet(baseTemplateDoors[template], rotation),
        })
    end
end

for _, child in ipairs(Workspace:GetChildren()) do
    if child:GetAttribute('MazeGenerated') then
        child:Destroy()
    end
end

local function createSeal(gx, gz, dir)
    local seal = Instance.new('Part')
    seal.Name = 'MazeSeal'
    seal.Anchored = true
    seal.BrickColor = BrickColor.new('Medium stone grey')
    seal.Material = Enum.Material.SmoothPlastic
    if dir == 'North' or dir == 'South' then
        seal.Size = Vector3.new(4, WALL_HEIGHT, 1)
    else
        seal.Size = Vector3.new(1, WALL_HEIGHT, 4)
    end
    seal.Position = gridToWorld(gx, gz) + DOOR_OFFSET[dir]
    seal:SetAttribute('MazeGenerated', true)
    seal.Parent = Workspace
end

local function placeRoom(template, gx, gz, roomIndex, rotation)
    local roomClone = template:Clone()
    roomClone.Name = string.format('MazeRoom_%02d_%d_%d', roomIndex, gx, gz)
    roomClone.Parent = Workspace

    if not roomClone:FindFirstChild('Floor') then
        roomClone:Destroy()
        return nil
    end

    local base = gridToWorld(gx, gz)
    local rotateCF = CFrame.Angles(0, math.rad(rotation), 0)
    for _, desc in ipairs(roomClone:GetDescendants()) do
        if desc:IsA('BasePart') then
            desc.CFrame = CFrame.new(base) * rotateCF * desc.CFrame
            desc.Anchored = true
        end
    end
    local button = Instance.new('Part')
    button.Name = 'ButtonPart'
    button.Shape = Enum.PartType.Cylinder
    button.Size = Vector3.new(0.5, 2, 2)
    button.CFrame = CFrame.new(base + Vector3.new(0, 0.75, 0)) * CFrame.Angles(0, 0, math.pi / 2)
    button.BrickColor = BrickColor.new('Bright yellow')
    button.Material = Enum.Material.Neon
    button.Anchored = true
    button.Parent = roomClone

    local prompt = Instance.new('ProximityPrompt')
    prompt.ActionText = '按下'
    prompt.KeyboardKeyCode = Enum.KeyCode.E
    prompt.MaxActivationDistance = 5
    prompt.RequiresLineOfSight = false
    prompt.Parent = button

    roomClone:SetAttribute('MazeGenerated', true)
    roomClone:SetAttribute('GridX', gx)
    roomClone:SetAttribute('GridZ', gz)
    roomClone:SetAttribute('RotationY', rotation)
    return roomClone
end

local grid = {}
local queue = {}
local count = 0
local occupiedKeys = {}

local startVariant
for _, variant in ipairs(variants) do
    if variant.template.Name == 'RoomA' and variant.rotation == 0 then
        startVariant = variant
        break
    end
end

if not startVariant then
    warn('迷宫生成失败：缺少 RoomA 起始模板')
    return
end

local startRoom = placeRoom(startVariant.template, 0, 0, 1, startVariant.rotation)
if not startRoom then
    warn('迷宫生成失败：RoomA 缺少 Floor')
    return
end

grid[key(0, 0)] = true
count = 1
table.insert(occupiedKeys, key(0, 0))

for dir in pairs(startVariant.doors) do
    if dir ~= 'South' then
        table.insert(queue, { gx = 0, gz = 0, dir = dir })
    end
end

while count < TARGET_ROOMS and #queue > 0 do
    local queueIndex = rng:NextInteger(1, #queue)
    local slot = table.remove(queue, queueIndex)
    local gx, gz, dir = slot.gx, slot.gz, slot.dir
    local offset = DIR_OFFSET[dir]
    local ngx = gx + offset.X / ROOM_SIZE
    local ngz = gz + offset.Z / ROOM_SIZE
    local nkey = key(ngx, ngz)

    if grid[nkey] then
        createSeal(gx, gz, dir)
    else
        local requiredDoor = OPPOSITE[dir]
        local candidates = {}
        local preferred = {}

        for _, variant in ipairs(variants) do
            if variant.doors[requiredDoor] then
                table.insert(candidates, variant)
                local branchCount = 0
                for newDir in pairs(variant.doors) do
                    if newDir ~= requiredDoor then
                        branchCount += 1
                    end
                end
                if branchCount > 0 then
                    table.insert(preferred, variant)
                end
            end
        end

        if #candidates == 0 then
            createSeal(gx, gz, dir)
        else
            local remaining = TARGET_ROOMS - count
            local pool = candidates
            if remaining > 1 and #preferred > 0 then
                pool = preferred
            end

            local chosen = pool[rng:NextInteger(1, #pool)]
            local roomClone = placeRoom(chosen.template, ngx, ngz, count + 1, chosen.rotation)
            if roomClone then
                grid[nkey] = true
                count += 1
                table.insert(occupiedKeys, nkey)
                for newDir in pairs(chosen.doors) do
                    if newDir ~= requiredDoor then
                        table.insert(queue, { gx = ngx, gz = ngz, dir = newDir })
                    end
                end
            else
                createSeal(gx, gz, dir)
            end
        end
    end
end

for _, slot in ipairs(queue) do
    createSeal(slot.gx, slot.gz, slot.dir)
end

if count < TARGET_ROOMS then
    warn('迷宫生成提前结束，房间数: ' .. count)
end

table.sort(occupiedKeys)
print('迷宫布局签名: ' .. table.concat(occupiedKeys, '|'))
print('迷宫生成完成，房间数: ' .. count)
