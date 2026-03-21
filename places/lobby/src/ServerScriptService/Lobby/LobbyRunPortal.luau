local HttpService = game:GetService('HttpService')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local TeleportService = game:GetService('TeleportService')

local Packages = ReplicatedStorage:WaitForChild('Packages')
local Shared = require(Packages:WaitForChild('Shared'))

local SessionConfig = Shared.Config.SessionConfig
local CampMazeSessionContract = Shared.Session.CampMazeSessionContract
local TeleportDiagnostics = Shared.Util.TeleportDiagnostics

local LobbyRunPortal = {}

function LobbyRunPortal.launch(params)
    local runTeleportSnapshot = TeleportDiagnostics.captureSnapshot({
        TargetKey = 'Run',
        TargetPlaceId = SessionConfig.PlaceIds.Run,
    })

    local reserved, reserveResult = pcall(function()
        return TeleportService:ReserveServer(SessionConfig.PlaceIds.Run)
    end)
    if not reserved then
        return {
            Ok = false,
            Reason = TeleportDiagnostics.formatFailure(
                'ReserveServer',
                reserveResult,
                runTeleportSnapshot
            ),
        }
    end

    local campAccessCode = reserveResult
    local sessionId = HttpService:GenerateGUID(false)
    local teleportData = CampMazeSessionContract.buildLobbyToRunTeleportData({
        SessionId = sessionId,
        CampAccessCode = campAccessCode,
        SessionConfig = params.SessionConfig,
    })

    local success, message = pcall(function()
        TeleportService:TeleportToPrivateServer(
            SessionConfig.PlaceIds.Run,
            campAccessCode,
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
        Status = 'Teleporting crew to run instance...',
        SessionId = sessionId,
        CampAccessCode = campAccessCode,
    }
end

return LobbyRunPortal
