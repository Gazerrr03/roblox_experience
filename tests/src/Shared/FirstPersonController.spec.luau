return function()
    local ReplicatedStorage = game:GetService('ReplicatedStorage')
    local shared = require(ReplicatedStorage:WaitForChild('Packages'):WaitForChild('Shared'))
    local controller = shared.Client.FirstPersonController

    assert(
        controller.StarterPlayerProperties.CameraMode == Enum.CameraMode.LockFirstPerson,
        'StarterPlayer camera mode should default to lock first person'
    )
    assert(
        controller.StarterPlayerProperties.EnableMouseLockOption == false,
        'StarterPlayer should disable mouse lock option'
    )

    local mockPlayer = {}
    controller.applyToPlayer(mockPlayer)

    assert(
        mockPlayer.CameraMode == Enum.CameraMode.LockFirstPerson,
        'Player camera mode should be forced to lock first person'
    )
    assert(
        mockPlayer.CameraMinZoomDistance == 0.5,
        'Player min zoom distance should be clamped to first-person range'
    )
    assert(
        mockPlayer.CameraMaxZoomDistance == 0.5,
        'Player max zoom distance should be clamped to first-person range'
    )
    assert(
        mockPlayer.DevEnableMouseLock == nil,
        'Player runtime properties should not write DevEnableMouseLock'
    )
end
