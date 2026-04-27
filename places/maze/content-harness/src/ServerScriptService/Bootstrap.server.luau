local ReplicatedStorage = game:GetService('ReplicatedStorage')

local PlaceModules = ReplicatedStorage:WaitForChild('PlaceModules'):WaitForChild('Maze')
local Packages = ReplicatedStorage:WaitForChild('Packages')

local MazeBootstrapStatus = require(PlaceModules:WaitForChild('MazeBootstrapStatus'))
local Remotes =
    require(Packages:WaitForChild('Shared'):WaitForChild('Network'):WaitForChild('Remotes'))
local MazeContentHarnessService = require(script.Parent:WaitForChild('MazeContentHarnessService'))
local MazeContentLightingService = require(script.Parent:WaitForChild('MazeContentLightingService'))

MazeBootstrapStatus.set('BootstrapScriptLoaded', nil)

task.defer(function()
    local mazeService

    local ok, err = pcall(function()
        MazeBootstrapStatus.set('RequirePackages', nil)
        MazeBootstrapStatus.set('EnsureRemotes', nil)
        Remotes.ensureScope(Remotes.Scope.Maze)

        MazeBootstrapStatus.set('RequireLightingService', nil)
        local lightingService = MazeContentLightingService.new()

        MazeBootstrapStatus.set('RequireSessionService', nil)
        mazeService = MazeContentHarnessService.new()

        MazeBootstrapStatus.set('StartLightingService', nil)
        local lightingResult = lightingService:start()
        if lightingResult and lightingResult.SurfacePalette then
            mazeService:setSurfacePalette(lightingResult.SurfacePalette)
        end

        MazeBootstrapStatus.set('StartSessionService', nil)
        mazeService:start()
    end)

    if not ok then
        local phase = mazeService and mazeService.BootPhase or 'BootstrapFailed'
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
