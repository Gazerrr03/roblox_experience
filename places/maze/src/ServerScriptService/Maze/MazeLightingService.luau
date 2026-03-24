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
    local created = Shared.Runtime.MazeLightingProfile.apply(Lighting)
    local skippedProperties = created.SkippedProperties or {}

    for propertyName, err in pairs(skippedProperties) do
        warn(
            string.format(
                '[MazeLighting] skipped %s update: %s',
                tostring(propertyName),
                tostring(err)
            )
        )
    end
end

return MazeLightingService
