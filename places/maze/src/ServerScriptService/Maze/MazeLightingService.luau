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
    local result = Shared.Runtime.MazeLightingProfile.apply(Lighting)
    if result.TechnologyApplied ~= true and result.TechnologyError ~= nil then
        warn(
            string.format(
                '[MazeLightingDiag] Technology write skipped: %s',
                tostring(result.TechnologyError)
            )
        )
    end
end

return MazeLightingService
