local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Packages = ReplicatedStorage:WaitForChild('Packages')
local Shared = require(Packages:WaitForChild('Shared'))
local Gameplay = require(Packages:WaitForChild('Gameplay'))

local VisibilityUtil = Shared.Util.Visibility
local RoleAllocator = Gameplay.Roles.RoleAllocator

local RoleService = {}
RoleService.__index = RoleService

function RoleService.new(roleDefinitions)
    return setmetatable({
        RoleDefinitions = roleDefinitions,
        Assignments = {},
    }, RoleService)
end

function RoleService:assign(players)
    self.Assignments = RoleAllocator.assign(table.clone(players), self.RoleDefinitions)
    return self.Assignments
end

function RoleService:getVisibleRoster(player)
    return VisibilityUtil.filterRoster(self.Assignments, player.UserId)
end

function RoleService:getPrivateState(player)
    local entry = self.Assignments[player.UserId]
    if not entry then
        return nil
    end

    return {
        RoleId = entry.RoleId,
        PrivateRole = entry.PrivateRole,
        PermissionTags = entry.PermissionTags,
    }
end

return RoleService

