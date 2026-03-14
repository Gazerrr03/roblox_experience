local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Packages = ReplicatedStorage:WaitForChild('Packages')
local Shared = require(Packages:WaitForChild('Shared'))
local Gameplay = require(Packages:WaitForChild('Gameplay'))

local VisibilityUtil = Shared.Util.Visibility
local RoleAllocator = Gameplay.Roles.RoleAllocator

local RoleService = {}
RoleService.__index = RoleService

local function countAssignments(assignments)
    local count = 0
    for _ in pairs(assignments) do
        count += 1
    end

    return count
end

local function nextRoleDefinition(roleDefinitions, assignmentCount)
    local index = (assignmentCount % #roleDefinitions) + 1
    return roleDefinitions[index]
end

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

function RoleService:assignPlayer(player)
    local existing = self.Assignments[player.UserId]
    if existing then
        existing.Name = player.DisplayName
        return existing
    end

    local roleDefinition =
        nextRoleDefinition(self.RoleDefinitions, countAssignments(self.Assignments))
    local assignment = {
        UserId = player.UserId,
        Name = player.DisplayName,
        RoleId = roleDefinition.Id,
        PublicRole = roleDefinition.PublicRole,
        PrivateRole = roleDefinition.PrivateRole,
        PermissionTags = table.clone(roleDefinition.PermissionTags),
    }

    self.Assignments[player.UserId] = assignment
    return assignment
end

function RoleService:removePlayer(player)
    self.Assignments[player.UserId] = nil
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
