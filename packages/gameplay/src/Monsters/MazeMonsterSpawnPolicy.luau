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

function MazeMonsterSpawnPolicy.buildEligibleRoomIds(roomIds, roomById, campRoomId)
    local excludedRoomIds =
        MazeMonsterSpawnPolicy.buildInitialSpawnExcludedRoomIds(roomById, campRoomId)
    local eligibleRoomIds = {}

    for _, roomId in ipairs(roomIds or {}) do
        if not excludedRoomIds[roomId] then
            table.insert(eligibleRoomIds, roomId)
        end
    end

    return eligibleRoomIds
end

function MazeMonsterSpawnPolicy.selectRandomEligiblePatrolIndex(
    roomIds,
    roomAffordances,
    roomById,
    campRoomId,
    randomSource
)
    local eligibleRoomIds =
        MazeMonsterSpawnPolicy.buildEligibleRoomIds(roomIds, roomById, campRoomId)
    if #eligibleRoomIds == 0 then
        return nil, nil
    end

    local eligibleRoomSet = {}
    for _, roomId in ipairs(eligibleRoomIds) do
        eligibleRoomSet[roomId] = true
    end

    local roomsWithPatrolAnchors = {}
    for _, roomId in ipairs(roomIds or {}) do
        local affordance = roomAffordances and roomAffordances[roomId]
        if
            eligibleRoomSet[roomId]
            and affordance
            and #((affordance and affordance.PatrolAnchors) or {}) > 0
        then
            table.insert(roomsWithPatrolAnchors, roomId)
        end
    end

    if #roomsWithPatrolAnchors == 0 then
        return nil, nil
    end

    local random = randomSource or Random.new()
    local selectedRoomId = roomsWithPatrolAnchors[random:NextInteger(1, #roomsWithPatrolAnchors)]
    local selectedPatrolIndex = 0

    for _, roomId in ipairs(roomIds or {}) do
        local affordance = roomAffordances and roomAffordances[roomId]
        for _ in ipairs(affordance and affordance.PatrolAnchors or {}) do
            selectedPatrolIndex += 1
            if roomId == selectedRoomId then
                return selectedPatrolIndex, selectedRoomId
            end
        end
    end

    return nil, selectedRoomId
end

return MazeMonsterSpawnPolicy
