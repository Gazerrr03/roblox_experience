local MazeMonsterSpawnPolicy = {}

function MazeMonsterSpawnPolicy.buildInitialSpawnExcludedRoomIds(roomById, campRoomId)
    local excludedRoomIds = {}
    local campRoom = roomById and roomById[campRoomId]
    if campRoom == nil then
        return excludedRoomIds
    end

    excludedRoomIds[campRoomId] = true
    for _, neighborRoomId in pairs(campRoom.Neighbors or {}) do
        excludedRoomIds[neighborRoomId] = true
    end

    return excludedRoomIds
end

function MazeMonsterSpawnPolicy.selectInitialPatrolIndex(
    roomIds,
    roomAffordances,
    roomById,
    campRoomId
)
    local excludedRoomIds =
        MazeMonsterSpawnPolicy.buildInitialSpawnExcludedRoomIds(roomById, campRoomId)
    local patrolIndex = 0

    for _, roomId in ipairs(roomIds or {}) do
        local affordance = roomAffordances and roomAffordances[roomId]
        for _ in ipairs(affordance and affordance.PatrolAnchors or {}) do
            patrolIndex += 1
            if not excludedRoomIds[roomId] then
                return patrolIndex, roomId
            end
        end
    end

    return nil, nil
end

return MazeMonsterSpawnPolicy
