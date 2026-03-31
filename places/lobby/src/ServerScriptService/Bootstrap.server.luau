local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Packages = ReplicatedStorage:WaitForChild('Packages')
local Shared = require(Packages:WaitForChild('Shared'))
local LobbyService = require(script.Parent.Lobby.LobbyService)

Shared.Network.Remotes.ensure()
LobbyService.new():start()
