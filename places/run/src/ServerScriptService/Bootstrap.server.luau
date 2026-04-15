local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Packages = ReplicatedStorage:WaitForChild('Packages')
local Shared = require(Packages:WaitForChild('Shared'))
local RunStaticWorldContract = require(script.Parent.Run.RunStaticWorldContract)
local RunSessionService = require(script.Parent.Run.RunSessionService)

Shared.Network.Remotes.ensure()
warn(string.format('[run-bootstrap] build=%s', RunStaticWorldContract.BuildFingerprint))
RunSessionService.new():start()
