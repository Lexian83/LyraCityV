fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'factionManager'
author 'Lyra & Jens'
description 'Zentrales Faction-Management für LyraCityV'
version '1.0.0'

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/faction_manager.lua',
}

server_exports {
    -- Fetch
    'GetFactionById',
    'GetFactionByName',
    'GetPlayerFaction',
    'GetPlayerFactions',
    'GetFactionMembers',
    'GetAllFactions',
    'GetFactionRanks',
    'GetFactionLogs',
    'GetFactionPermissionSchema',
    'HasFactionPermission',
    'HasAnyFactionPermission',
    'IsFactionLeader',
    'IsOnDuty',
    'GetDutyFactions',

    -- Mutationen
    'CreateFaction',
    'DeleteFaction',
    'CreateRank',
    'UpdateRankPermissions',
    'UpdateRank',
    'DeleteRank',
    'AddMember',
    'RemoveMember',
    'SetMemberRank',
    'UpdateFaction',

    -- Duty steuern
    'SetDuty',

    -- Logging
    'LogFactionAction'
}


