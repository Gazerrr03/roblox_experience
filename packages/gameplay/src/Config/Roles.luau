return {
    {
        Id = 'lead',
        PublicRole = 'Crew',
        PrivateRole = 'Lead',
        PermissionTags = { 'StartRun', 'DeployCrew' },
    },
    {
        Id = 'runner',
        PublicRole = 'Crew',
        PrivateRole = 'Runner',
        PermissionTags = { 'DepositLoot' },
    },
    {
        Id = 'scout',
        PublicRole = 'Crew',
        PrivateRole = 'Scout',
        PermissionTags = { 'SpotThreats' },
    },
    {
        Id = 'quartermaster',
        PublicRole = 'Crew',
        PrivateRole = 'Quartermaster',
        PermissionTags = { 'TrackInventory' },
    },
}
