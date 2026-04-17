return function()
    local ReplicatedStorage = game:GetService('ReplicatedStorage')
    local gameplay = require(ReplicatedStorage:WaitForChild('Packages'):WaitForChild('Gameplay'))
    local templates = gameplay.ProcGen.MazeRoomTemplates

    local orderedTemplateIds = templates.getOrderedTemplateIds()
    assert(#orderedTemplateIds == 8, 'Room-first maze taxonomy should expose eight base templates')

    local landmark = templates.getDefinition('LandmarkFacility')
    assert(landmark ~= nil, 'Landmark facility template should exist')
    assert(
        landmark.SearchProfile.Mode == 'landmark',
        'Landmark facility should expose its search-profile semantics'
    )
    assert(landmark.LandmarkWeight >= 4, 'Landmark facility should carry strong landmark weight')

    local room = {
        Id = 'Room_999',
        OpenDirections = { 1, 3, 5 },
        Neighbors = {
            [1] = 'Room_001',
            [3] = 'Room_002',
        },
    }

    templates.applyTemplate(room, 'BulkheadGate')
    local endpointDefs = templates.buildEndpointDefs(room)

    assert(room.RoomTemplateId == 'BulkheadGate', 'Template application should stamp the room id')
    assert(room.RoomCategory == 'BulkheadGate', 'Template application should stamp the category')
    assert(#endpointDefs == 2, 'Endpoint definitions should only cover connected interior edges')
    assert(
        endpointDefs[1].EndpointType == 'bulkhead',
        'Internal bulkhead rooms should use bulkhead endpoints'
    )
    assert(
        endpointDefs[2].IsExternal == false,
        'Unconnected room edges should no longer become external endpoints'
    )
end
