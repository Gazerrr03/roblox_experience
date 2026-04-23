local Lighting = game:GetService('Lighting')
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Packages = ReplicatedStorage:WaitForChild('Packages')
local MazeLightingProfile = require(
    Packages:WaitForChild('Shared'):WaitForChild('Runtime'):WaitForChild('MazeLightingProfile')
)

local MazeContentLightingService = {}
MazeContentLightingService.__index = MazeContentLightingService

function MazeContentLightingService.new()
    return setmetatable({}, MazeContentLightingService)
end

function MazeContentLightingService:start()
    local created = MazeLightingProfile.apply(Lighting)
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

    if created.TechnologyApplied then
        print('[MazeLightingDiag] applied Future lighting profile')
    else
        warn(
            string.format(
                '[MazeLightingDiag] applied fallback readable profile: %s',
                tostring(created.TechnologyError or 'Technology unavailable')
            )
        )
    end

    return created
end

return MazeContentLightingService
