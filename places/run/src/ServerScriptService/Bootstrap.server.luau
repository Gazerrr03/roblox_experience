local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Packages = ReplicatedStorage:WaitForChild('Packages')
local Shared = require(Packages:WaitForChild('Shared'))
local RunSessionService = require(script.Parent.Run.RunSessionService)

Shared.Network.Remotes.ensure()
RunSessionService.new():start()
