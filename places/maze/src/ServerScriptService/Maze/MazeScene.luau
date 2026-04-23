local MazeDoor = require(script.Parent.MazeDoor)
local MazeInteractionRegistry = require(script.Parent.MazeInteractionRegistry)
local MazeLootNode = require(script.Parent.MazeLootNode)
local MazeRoom = require(script.Parent.MazeRoom)
local MazeSceneRegistry = require(script.Parent.MazeSceneRegistry)
local MazeSpawnPoint = require(script.Parent.MazeSpawnPoint)

local MazeScene = {}
MazeScene.__index = MazeScene

local function assertNonEmptyMap(map, label)
    if next(map) == nil then
        error(string.format('MazeStaticWorld is missing required authored %s.', label), 0)
    end
end

function MazeScene.new(rawWorld)
    if type(rawWorld) ~= 'table' then
        error('MazeScene requires a world table.', 0)
    end

    if rawWorld.Root == nil then
        error('MazeStaticWorld is missing a valid authored root.', 0)
    end

    if rawWorld.SpawnCFrame == nil then
        error('MazeStaticWorld is missing required part "SpawnMarker".', 0)
    end

    if rawWorld.ReturnHoldPad == nil or rawWorld.ReturnHoldPad.Prompt == nil then
        error('MazeStaticWorld is missing a valid ReturnHoldPad prompt.', 0)
    end

    if #(rawWorld.RoomIds or {}) == 0 then
        error('MazeStaticWorld is missing authored room models.', 0)
    end

    local roomsById = {}
    for _, roomId in ipairs(rawWorld.RoomIds) do
        roomsById[roomId] = MazeRoom.new(
            rawWorld.RoomById[roomId],
            rawWorld.RoomAffordances[roomId],
            rawWorld.RoomInstancesById and rawWorld.RoomInstancesById[roomId] or nil
        )
    end

    local lootNodes = {}
    for roomId, lootNode in pairs(rawWorld.LootNodes or {}) do
        lootNodes[roomId] = MazeLootNode.new(roomId, lootNode)
    end
    assertNonEmptyMap(lootNodes, 'loot nodes')

    local doorways = {}
    for doorwayId, doorway in pairs(rawWorld.Doorways or {}) do
        doorways[doorwayId] = MazeDoor.new(doorway)
    end
    assertNonEmptyMap(doorways, 'doorways')

    local returnHoldPad = rawWorld.ReturnHoldPad
    function returnHoldPad:bind(callback)
        return self.Prompt.Triggered:Connect(callback)
    end

    local registry = MazeSceneRegistry.new({
        RoomsById = roomsById,
        LootNodes = lootNodes,
        Doorways = doorways,
    })

    local self = setmetatable({
        Root = rawWorld.Root,
        Registry = registry,
        RoomIds = rawWorld.RoomIds,
        RoomById = roomsById,
        RoomAffordances = rawWorld.RoomAffordances,
        CampRoomId = rawWorld.CampRoomId,
        PatrolPoints = rawWorld.PatrolPoints or {},
        InitialMonsterPatrolIndex = rawWorld.InitialMonsterPatrolIndex,
        InitialMonsterSpawnRoomId = rawWorld.InitialMonsterSpawnRoomId,
        SpawnPoint = MazeSpawnPoint.new(MazeSpawnPoint.Kind.Spawn, rawWorld.SpawnCFrame),
        ReturnHoldPoint = MazeSpawnPoint.new(
            MazeSpawnPoint.Kind.ReturnHold,
            rawWorld.ReturnHoldCFrame
        ),
        ReturnHoldPad = returnHoldPad,
        LootNodes = lootNodes,
        Doorways = doorways,
        CanTraverseBetweenPositions = rawWorld.CanTraverseBetweenPositions,
        _findRoomByPosition = rawWorld.FindRoomByPosition,
    }, MazeScene)

    self.SpawnCFrame = self.SpawnPoint:getCFrame()
    self.ReturnHoldCFrame = self.ReturnHoldPoint:getCFrame()
    self.FindRoomByPosition = function(_, position)
        return self:findRoomByPosition(position)
    end
    self.ToggleDoor = function(_, doorwayId)
        return self:toggleDoor(doorwayId)
    end

    return self
end

function MazeScene:getPatrolPoints()
    return self.PatrolPoints, self.InitialMonsterPatrolIndex
end

function MazeScene:getLootNode(roomId)
    return self.Registry:getLootNode(roomId)
end

function MazeScene:getDoor(doorwayId)
    return self.Registry:getDoor(doorwayId)
end

function MazeScene:findRoomByPosition(position)
    local rawRoom = self._findRoomByPosition(position)
    if rawRoom == nil then
        return nil
    end

    return self.Registry:getRoom(rawRoom.Id)
end

function MazeScene:toggleDoor(doorwayId)
    local doorway = self.Registry:getDoor(doorwayId)
    if doorway == nil then
        return false
    end

    return doorway:toggle()
end

function MazeScene:bindInteractions(handlers)
    local interactionRegistry = MazeInteractionRegistry.new()
    interactionRegistry:bindScene(self, handlers)
    return interactionRegistry
end

return MazeScene
