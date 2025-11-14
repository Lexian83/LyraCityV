fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'houseManager'
author 'Lyra & Jens'
version '1.1.0'
description 'LyraCityV - Housing Management (SSOT)'

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/houseManager.lua',   -- Gameplay + Sync + RentWatcher
    'server/exports.lua',        -- Admin/SSOT Exports & Callbacks
}

client_scripts {
    'client/houseManager_client.lua',
}

server_exports {
    -- simple getters (kompatibel zu Bestand)
    'getownerbyhouseid',
    'getlockstate',
    'getrent',
    'getprice',
    'getpincode',
    'getanzahlapartments',
    'getsecured',

    -- SSOT-Lese-Exports
    'GetAll',
    'GetById',

    -- Admin/SSOT (neu)
    'Admin_Houses_GetAll',
    'Admin_Houses_Add',
    'Admin_Houses_Update',
    'Admin_Houses_Delete',
    'Admin_Houses_ResetPincode',

    'Admin_HousesIPL_GetAll',
    'Admin_HousesIPL_Add',
    'Admin_HousesIPL_Update',
    'Admin_HousesIPL_Delete',
}

dependency 'oxmysql'
