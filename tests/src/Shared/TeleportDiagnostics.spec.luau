return function()
    local ReplicatedStorage = game:GetService('ReplicatedStorage')
    local shared = require(ReplicatedStorage:WaitForChild('Packages'):WaitForChild('Shared'))
    local diagnostics = shared.Util.TeleportDiagnostics

    local samePlaceReason = diagnostics.formatFailure('ReserveServer', 'HTTP 403 (Forbidden)', {
        CurrentPlaceId = 137478567439901,
        GameId = 9896038993,
        TargetKey = 'Run',
        TargetPlaceId = 137478567439901,
        TargetAttributeName = 'SessionPlaceIdRun',
        GameAttributeValue = nil,
        ReplicatedStorageAttributeValue = nil,
    })

    assert(
        string.find(samePlaceReason, 'ReserveServer on the current place is forbidden', 1, true),
        'Same-place 403 failures should point to experience-level teleport permissions'
    )
    assert(
        string.find(samePlaceReason, 'targetPlaceId=137478567439901', 1, true),
        'Failure reason should include the target place id'
    )

    local crossPlaceReason = diagnostics.formatFailure('ReserveServer', 'HTTP 403 (Forbidden)', {
        CurrentPlaceId = 137478567439901,
        GameId = 9896038993,
        TargetKey = 'Maze',
        TargetPlaceId = 114148445477110,
        TargetAttributeName = 'SessionPlaceIdMaze',
        GameAttributeValue = nil,
        ReplicatedStorageAttributeValue = nil,
    })

    assert(
        string.find(
            crossPlaceReason,
            'check that the target place belongs to this experience',
            1,
            true
        ),
        'Cross-place 403 failures should include the target-place ownership hint'
    )
    assert(
        string.find(crossPlaceReason, 'ReplicatedStorage.SessionPlaceIdMaze=nil', 1, true),
        'Failure reason should capture raw attribute values for the target place'
    )

    local genericReason = diagnostics.formatFailure('TeleportToPrivateServer', 'Queue full', nil)
    assert(
        genericReason == 'TeleportToPrivateServer failed: Queue full',
        'Formatting should stay compact when no diagnostic snapshot is provided'
    )
end
