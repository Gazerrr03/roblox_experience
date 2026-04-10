local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Packages = ReplicatedStorage:WaitForChild('Packages')
local Shared = require(Packages:WaitForChild('Shared'))

local SessionConfig = Shared.Config.SessionConfig
local Remotes = Shared.Network.Remotes.ensureScope(Shared.Network.Remotes.Scope.Lobby)
local SessionSeedPolicy = Shared.Session.SessionSeedPolicy

local LobbyRunPortal = require(script.Parent.LobbyRunPortal)

local LobbyService = {}
LobbyService.__index = LobbyService

function LobbyService.new()
    return setmetatable({
        ReadyByUserId = {},
        Status = 'Waiting for crew.',
        Seed = SessionConfig.DefaultSeed,
    }, LobbyService)
end

function LobbyService:_buildSnapshot()
    local roster = {}
    local allReady = true

    for _, player in ipairs(Players:GetPlayers()) do
        local isReady = self.ReadyByUserId[player.UserId] == true
        if not isReady then
            allReady = false
        end

        table.insert(roster, {
            UserId = player.UserId,
            Name = player.DisplayName,
            Ready = isReady,
        })
    end

    if #roster < SessionConfig.MinPlayers then
        allReady = false
    end

    return {
        Status = self.Status,
        Seed = self.Seed,
        Players = roster,
        MinPlayers = SessionConfig.MinPlayers,
        MaxPlayers = SessionConfig.MaxPlayers,
        RunPlaceId = SessionConfig.PlaceIds.Run,
        CanStart = allReady,
    }
end

function LobbyService:_broadcast()
    Remotes.LobbyState:FireAllClients(self:_buildSnapshot())
end

function LobbyService:_setReady(player, isReady)
    self.ReadyByUserId[player.UserId] = isReady
    self.Status = isReady and string.format('%s is ready.', player.DisplayName)
        or string.format('%s is waiting.', player.DisplayName)
    self:_broadcast()
end

function LobbyService:_teleportToRun()
    local players = Players:GetPlayers()
    if #players < SessionConfig.MinPlayers then
        self.Status = 'Need at least one player to launch.'
        self:_broadcast()
        return
    end

    if SessionConfig.PlaceIds.Run == 0 then
        self.Status =
            'Set SessionConfig.PlaceIds.Run or SessionPlaceIdRun before starting teleports.'
        self:_broadcast()
        return
    end

    for _, player in ipairs(players) do
        if not self.ReadyByUserId[player.UserId] then
            self.Status = 'Everyone in the roster must ready up.'
            self:_broadcast()
            return
        end
    end

    self.Seed = SessionSeedPolicy.issueSessionSeed(Random.new(), SessionConfig.DefaultSeed)

    local result = LobbyRunPortal.launch({
        Players = players,
        SessionConfig = {
            Seed = self.Seed,
            Quota = SessionConfig.DefaultQuota,
            RunDurationSeconds = SessionConfig.DefaultRunDurationSeconds,
            InventoryCapacity = SessionConfig.InventoryCapacity,
        },
    })
    if not result.Ok then
        self.Status = result.Reason
        self:_broadcast()
        return
    end

    self.Status = result.Status
    self:_broadcast()
end

function LobbyService:start()
    for _, player in ipairs(Players:GetPlayers()) do
        self.ReadyByUserId[player.UserId] = false
    end

    Players.PlayerAdded:Connect(function(player)
        self.ReadyByUserId[player.UserId] = false
        self.Status = string.format('%s joined the lobby.', player.DisplayName)
        self:_broadcast()
    end)

    Players.PlayerRemoving:Connect(function(player)
        self.ReadyByUserId[player.UserId] = nil
        self.Status = string.format('%s left the lobby.', player.DisplayName)
        self:_broadcast()
    end)

    Remotes.LobbyAction.OnServerEvent:Connect(function(player, payload)
        if type(payload) ~= 'table' then
            return
        end

        if payload.Type == 'ToggleReady' then
            self:_setReady(player, payload.Ready == true)
        elseif payload.Type == 'StartRun' then
            self:_teleportToRun()
        end
    end)

    self:_broadcast()
end

return LobbyService
