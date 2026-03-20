local ReplicatedStorage = game:GetService('ReplicatedStorage')
local TeleportService = game:GetService('TeleportService')

local Packages = ReplicatedStorage:WaitForChild('Packages')
local Shared = require(Packages:WaitForChild('Shared'))

local SessionConfig = Shared.Config.SessionConfig
local CampMazeSessionContract = Shared.Session.CampMazeSessionContract
local MazeEntryAvailability = Shared.Session.MazeEntryAvailability
local TeleportDiagnostics = Shared.Util.TeleportDiagnostics

local RunMazePortal = {}

RunMazePortal.FailureCode = table.freeze({
    ReserveServerFailed = 'ReserveServerFailed',
    TeleportToPrivateServerFailed = 'TeleportToPrivateServerFailed',
})

function RunMazePortal.enter(params)
    local currentSession = CampMazeSessionContract.normalizeCampSession(params.CampSession)
    local mazeTeleportSnapshot = TeleportDiagnostics.captureSnapshot({
        TargetKey = 'Maze',
        TargetPlaceId = SessionConfig.PlaceIds.Maze,
    })

    local mazeAccessCode = currentSession.MazeAccessCode
    if mazeAccessCode == nil then
        local reserved, reserveResult = pcall(function()
            return TeleportService:ReserveServer(SessionConfig.PlaceIds.Maze)
        end)

        if not reserved then
            return {
                Ok = false,
                FailureCode = RunMazePortal.FailureCode.ReserveServerFailed,
                Reason = TeleportDiagnostics.formatFailure(
                    'ReserveServer',
                    reserveResult,
                    mazeTeleportSnapshot
                ),
                ReasonCode = RunMazePortal.FailureCode.ReserveServerFailed,
                CurrentSession = currentSession,
            }
        end

        mazeAccessCode = reserveResult
    end

    local nextSession =
        CampMazeSessionContract.markPlayerEntered(currentSession, params.EnteringPlayer)
    nextSession.MazeAccessCode = mazeAccessCode
    nextSession.GateOpen = params.GateOpen == true

    local teleportData = CampMazeSessionContract.buildRunToMazeTeleportData({
        SessionConfig = params.SessionConfig,
        CampSession = nextSession,
        EnteringPlayer = params.EnteringPlayer,
        EntryReason = params.EntryReason or 'maze_gate',
    })

    local success, message = pcall(function()
        TeleportService:TeleportToPrivateServer(
            SessionConfig.PlaceIds.Maze,
            mazeAccessCode,
            { params.Player },
            nil,
            teleportData
        )
    end)
    if not success then
        return {
            Ok = false,
            FailureCode = RunMazePortal.FailureCode.TeleportToPrivateServerFailed,
            Reason = TeleportDiagnostics.formatFailure(
                'TeleportToPrivateServer',
                message,
                mazeTeleportSnapshot
            ),
            ReasonCode = RunMazePortal.FailureCode.TeleportToPrivateServerFailed,
            CurrentSession = currentSession,
        }
    end

    return {
        Ok = true,
        NextSession = nextSession,
        Reason = 'Maze teleport target is ready.',
        ReasonCode = MazeEntryAvailability.ReasonCode.TeleportReady,
    }
end

return RunMazePortal
