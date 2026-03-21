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
    TeleportAsyncFailed = 'TeleportAsyncFailed',
})

local function buildReservedServerTeleportOptions(accessCode, teleportData)
    local teleportOptions = Instance.new('TeleportOptions')
    teleportOptions.ReservedServerAccessCode = accessCode
    teleportOptions:SetTeleportData(teleportData)
    return teleportOptions
end

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
        PlayerInventory = params.PlayerInventory,
    })

    local teleportOptions = buildReservedServerTeleportOptions(mazeAccessCode, teleportData)
    local success, message = pcall(function()
        TeleportService:TeleportAsync(
            SessionConfig.PlaceIds.Maze,
            { params.Player },
            teleportOptions
        )
    end)
    if not success then
        return {
            Ok = false,
            FailureCode = RunMazePortal.FailureCode.TeleportAsyncFailed,
            Reason = TeleportDiagnostics.formatFailure(
                'TeleportAsync',
                message,
                mazeTeleportSnapshot
            ),
            ReasonCode = RunMazePortal.FailureCode.TeleportAsyncFailed,
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
