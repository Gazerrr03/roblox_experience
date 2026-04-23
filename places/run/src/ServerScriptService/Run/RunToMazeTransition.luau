local ReplicatedStorage = game:GetService('ReplicatedStorage')
local TeleportService = game:GetService('TeleportService')

local Packages = ReplicatedStorage:WaitForChild('Packages')
local Shared = require(Packages:WaitForChild('Shared'))

local DefaultSessionConfig = Shared.Config.SessionConfig
local DefaultContract = Shared.Session.CampMazeSessionContract
local DefaultAvailability = Shared.Session.MazeEntryAvailability
local DefaultDiagnostics = Shared.Util.TeleportDiagnostics

local RunToMazeTransition = {}
RunToMazeTransition.__index = RunToMazeTransition

RunToMazeTransition.FailureCode = table.freeze({
    ReserveServerFailed = 'ReserveServerFailed',
    TeleportAsyncFailed = 'TeleportAsyncFailed',
})

local function buildReservedServerTeleportOptions(accessCode, teleportData)
    local teleportOptions = Instance.new('TeleportOptions')
    teleportOptions.ReservedServerAccessCode = accessCode
    teleportOptions:SetTeleportData(teleportData)
    return teleportOptions
end

function RunToMazeTransition.new(options)
    local resolved = options or {}

    return setmetatable({
        TeleportService = resolved.TeleportService or TeleportService,
        SessionConfig = resolved.SessionConfig or DefaultSessionConfig,
        Contract = resolved.Contract or DefaultContract,
        Availability = resolved.Availability or DefaultAvailability,
        Diagnostics = resolved.Diagnostics or DefaultDiagnostics,
        ForceFreshServerForDiagnostics = resolved.ForceFreshServerForDiagnostics == true,
    }, RunToMazeTransition)
end

function RunToMazeTransition:enter(params)
    local currentSession = self.Contract.normalizeCampSession(params.CampSession)
    local mazeTeleportSnapshot = self.Diagnostics.captureSnapshot({
        TargetKey = 'Maze',
        TargetPlaceId = self.SessionConfig.PlaceIds.Maze,
    })

    local mazeAccessCode = currentSession.MazeAccessCode
    if self.ForceFreshServerForDiagnostics and mazeAccessCode ~= nil then
        mazeAccessCode = nil
    end

    if mazeAccessCode == nil then
        local reserved, reserveResult = pcall(function()
            return self.TeleportService:ReserveServer(self.SessionConfig.PlaceIds.Maze)
        end)

        if not reserved then
            return {
                Ok = false,
                FailureCode = RunToMazeTransition.FailureCode.ReserveServerFailed,
                Reason = self.Diagnostics.formatFailure(
                    'ReserveServer',
                    reserveResult,
                    mazeTeleportSnapshot
                ),
                ReasonCode = RunToMazeTransition.FailureCode.ReserveServerFailed,
                CurrentSession = currentSession,
            }
        end

        mazeAccessCode = reserveResult
    end

    local nextSession = self.Contract.markPlayerEntered(currentSession, params.EnteringPlayer)
    nextSession.MazeAccessCode = mazeAccessCode
    nextSession.GateOpen = params.GateOpen == true

    local teleportData = self.Contract.buildRunToMazeTeleportData({
        SessionConfig = params.SessionConfig,
        CampSession = nextSession,
        EnteringPlayer = params.EnteringPlayer,
        EntryReason = params.EntryReason or 'maze_gate',
        PlayerInventory = params.PlayerInventory,
    })

    local teleportOptions = buildReservedServerTeleportOptions(mazeAccessCode, teleportData)
    local success, message = pcall(function()
        self.TeleportService:TeleportAsync(
            self.SessionConfig.PlaceIds.Maze,
            { params.Player },
            teleportOptions
        )
    end)
    if not success then
        return {
            Ok = false,
            FailureCode = RunToMazeTransition.FailureCode.TeleportAsyncFailed,
            Reason = self.Diagnostics.formatFailure('TeleportAsync', message, mazeTeleportSnapshot),
            ReasonCode = RunToMazeTransition.FailureCode.TeleportAsyncFailed,
            CurrentSession = currentSession,
        }
    end

    return {
        Ok = true,
        NextSession = nextSession,
        Reason = 'Maze teleport target is ready.',
        ReasonCode = self.Availability.ReasonCode.TeleportReady,
    }
end

return RunToMazeTransition
