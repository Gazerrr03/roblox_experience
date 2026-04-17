local ReplicatedStorage = game:GetService('ReplicatedStorage')
local TeleportService = game:GetService('TeleportService')

local Packages = ReplicatedStorage:WaitForChild('Packages')
local Shared = require(Packages:WaitForChild('Shared'))

local DefaultSessionConfig = Shared.Config.SessionConfig
local DefaultContract = Shared.Session.CampMazeSessionContract
local DefaultDiagnostics = Shared.Util.TeleportDiagnostics

local MazeToRunTransition = {}
MazeToRunTransition.__index = MazeToRunTransition

function MazeToRunTransition.new(options)
    local resolved = options or {}

    return setmetatable({
        TeleportService = resolved.TeleportService or TeleportService,
        SessionConfig = resolved.SessionConfig or DefaultSessionConfig,
        Contract = resolved.Contract or DefaultContract,
        Diagnostics = resolved.Diagnostics or DefaultDiagnostics,
    }, MazeToRunTransition)
end

function MazeToRunTransition:returnPlayers(params)
    local currentSession = self.Contract.normalizeCampSession(params.CampSession)
    local nextCampSession = currentSession
    for _, summary in ipairs(params.Summaries) do
        nextCampSession = self.Contract.applyReturn(nextCampSession, summary, params.MazeCompleted)
    end

    local teleportData = self.Contract.buildMazeToRunTeleportData({
        SessionConfig = params.SessionConfig,
        CampSession = nextCampSession,
        Summaries = params.Summaries,
        MazeCompleted = params.MazeCompleted,
        PlayerInventories = params.PlayerInventories,
    })

    local runTeleportSnapshot = self.Diagnostics.captureSnapshot({
        TargetKey = 'Run',
        TargetPlaceId = self.SessionConfig.PlaceIds.Run,
    })

    local success, message = pcall(function()
        self.TeleportService:TeleportToPrivateServer(
            self.SessionConfig.PlaceIds.Run,
            nextCampSession.CampAccessCode,
            params.Players,
            nil,
            teleportData
        )
    end)
    if not success then
        return {
            Ok = false,
            Reason = self.Diagnostics.formatFailure(
                'TeleportToPrivateServer',
                message,
                runTeleportSnapshot
            ),
        }
    end

    return {
        Ok = true,
        NextCampSession = nextCampSession,
    }
end

return MazeToRunTransition
