fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'houseManager'
author 'Lyra & Jens'
version '1.0.0'
description 'LyraCityV - Housing Management'

server_scripts {
    '@oxmysql/lib/MySQL.lua',    -- oxmysql Binding
    'server/houseManager.lua',
}

client_scripts {
    'client/houseManager_client.lua',
}

server_exports {
    'getownerbyhouseid',
    'getlockstate',
    'getrent',
    'getprice',
}

dependency 'oxmysql'
