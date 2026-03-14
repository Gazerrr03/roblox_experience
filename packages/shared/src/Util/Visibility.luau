local Visibility = {}

local function cloneArray(list)
    return table.clone(list or {})
end

function Visibility.filterRoster(rosterByUserId, recipientUserId)
    local filtered = {}

    for userId, entry in pairs(rosterByUserId) do
        filtered[userId] = {
            UserId = entry.UserId,
            Name = entry.Name,
            PublicRole = entry.PublicRole,
        }

        if userId == recipientUserId then
            filtered[userId].PrivateRole = entry.PrivateRole
            filtered[userId].PermissionTags = cloneArray(entry.PermissionTags)
        end
    end

    return filtered
end

return Visibility
