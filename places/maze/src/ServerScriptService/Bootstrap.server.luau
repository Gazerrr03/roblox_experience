local ReplicatedStorage = game:GetService('ReplicatedStorage')

local BOOTSTRAP_PHASE_ATTRIBUTE = 'MazeBootstrapPhase'
local BOOTSTRAP_ERROR_ATTRIBUTE = 'MazeBootstrapError'
local BOOTSTRAP_FAILED_ATTRIBUTE = 'MazeBootstrapFailed'

local function setBootstrapStatus(phase, err)
    ReplicatedStorage:SetAttribute(BOOTSTRAP_PHASE_ATTRIBUTE, phase)
    ReplicatedStorage:SetAttribute(BOOTSTRAP_FAILED_ATTRIBUTE, err ~= nil)
    ReplicatedStorage:SetAttribute(BOOTSTRAP_ERROR_ATTRIBUTE, err)
end

setBootstrapStatus('BootstrapScriptLoaded', nil)

task.defer(function()
    local mazeSessionService
    local lightingResult

    local ok, err = pcall(function()
        setBootstrapStatus('RequirePackages', nil)
        local Packages = ReplicatedStorage:WaitForChild('Packages')

        setBootstrapStatus('RequireShared', nil)
        local Shared = require(Packages:WaitForChild('Shared'))

        -- Create maze remotes before the heavier maze service require chain so
        -- clients can still attach and read diagnostics if bootstrap fails later.
        setBootstrapStatus('EnsureRemotes', nil)
        Shared.Network.Remotes.ensure()

        setBootstrapStatus('RequireLightingService', nil)
        local MazeLightingService = require(script.Parent.Maze.MazeLightingService)

        setBootstrapStatus('RequireSessionService', nil)
        local MazeSessionService = require(script.Parent.Maze.MazeSessionService)

        setBootstrapStatus('ConstructSessionService', nil)
        mazeSessionService = MazeSessionService.new({
            ReportBootstrapStatus = setBootstrapStatus,
        })

        setBootstrapStatus('StartLightingService', nil)
        lightingResult = MazeLightingService.new():start()

        if lightingResult and lightingResult.SurfacePalette then
            mazeSessionService:setSurfacePalette(lightingResult.SurfacePalette)
        end

        setBootstrapStatus('StartSessionService', nil)
        mazeSessionService:start()
    end)

    if not ok then
        local phase = mazeSessionService and mazeSessionService.BootPhase or 'BootstrapFailed'
        setBootstrapStatus(phase, tostring(err))
        warn(
            string.format(
                '[MazeBoot] bootstrap failed at phase=%s error=%s',
                tostring(phase),
                tostring(err)
            )
        )
    end
end)
