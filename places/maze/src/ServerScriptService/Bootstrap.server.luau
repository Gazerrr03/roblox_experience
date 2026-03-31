local ReplicatedStorage = game:GetService('ReplicatedStorage')

local MazeBootstrapStatus = require(script.Parent.Maze.MazeBootstrapStatus)

MazeBootstrapStatus.set('BootstrapScriptLoaded', nil)

task.defer(function()
    local mazeSessionService

    local ok, err = pcall(function()
        MazeBootstrapStatus.set('RequirePackages', nil)
        local Packages = ReplicatedStorage:WaitForChild('Packages')

        MazeBootstrapStatus.set('RequireShared', nil)
        local Shared = require(Packages:WaitForChild('Shared'))

        -- Create maze remotes before the heavier maze service require chain so
        -- clients can still attach and read diagnostics if bootstrap fails later.
        MazeBootstrapStatus.set('EnsureRemotes', nil)
        Shared.Network.Remotes.ensure()

        MazeBootstrapStatus.set('RequireLightingService', nil)
        local MazeLightingService = require(script.Parent.Maze.MazeLightingService)

        MazeBootstrapStatus.set('RequireSessionService', nil)
        local MazeSessionService = require(script.Parent.Maze.MazeSessionService)

        MazeBootstrapStatus.set('ConstructSessionService', nil)
        mazeSessionService = MazeSessionService.new()

        MazeBootstrapStatus.set('StartLightingService', nil)
        MazeLightingService.new():start()

        MazeBootstrapStatus.set('StartSessionService', nil)
        mazeSessionService:start()
    end)

    if not ok then
        local phase = mazeSessionService and mazeSessionService.BootPhase or 'BootstrapFailed'
        MazeBootstrapStatus.set(phase, tostring(err))
        warn(
            string.format(
                '[MazeBoot] bootstrap failed at phase=%s error=%s',
                tostring(phase),
                tostring(err)
            )
        )
    end
end)
