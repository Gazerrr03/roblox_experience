local Lighting = game:GetService('Lighting')
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Packages = ReplicatedStorage:WaitForChild('Packages')
local Shared = require(Packages:WaitForChild('Shared'))

local MazeLightingService = {}
MazeLightingService.__index = MazeLightingService

function MazeLightingService.new()
    return setmetatable({}, MazeLightingService)
end

function MazeLightingService:start()
    Shared.Runtime.MazeLightingProfile.apply(Lighting)
end

return MazeLightingService
