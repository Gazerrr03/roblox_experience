local ReplicatedStorage = game:GetService('ReplicatedStorage')
local TeleportService = game:GetService('TeleportService')

local Packages = ReplicatedStorage:WaitForChild('Packages')
local Shared = require(Packages:WaitForChild('Shared'))

local SessionConfig = Shared.Config.SessionConfig
local CampMazeSessionContract = Shared.Session.CampMazeSessionContract
local TeleportDiagnostics = Shared.Util.TeleportDiagnostics

local MazeRunPortal = {}

function MazeRunPortal.returnPlayers(params)
    local currentSession = CampMazeSessionContract.normalizeCampSession(params.CampSession)
    local nextCampSession = currentSession
    for _, summary in ipairs(params.Summaries) do
        nextCampSession =
            CampMazeSessionContract.applyReturn(nextCampSession, summary, params.MazeCompleted)
    end

    local teleportData = CampMazeSessionContract.buildMazeToRunTeleportData({
        SessionConfig = params.SessionConfig,
        CampSession = nextCampSession,
        Summaries = params.Summaries,
        MazeCompleted = params.MazeCompleted,
        PlayerInventories = params.PlayerInventories,
    })

    local runTeleportSnapshot = TeleportDiagnostics.captureSnapshot({
        TargetKey = 'Run',
        TargetPlaceId = SessionConfig.PlaceIds.Run,
    })

    local success, message = pcall(function()
        TeleportService:TeleportToPrivateServer(
            SessionConfig.PlaceIds.Run,
            nextCampSession.CampAccessCode,
            params.Players,
            nil,
            teleportData
        )
    end)
    if not success then
        return {
            Ok = false,
            Reason = TeleportDiagnostics.formatFailure(
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

return MazeRunPortal
