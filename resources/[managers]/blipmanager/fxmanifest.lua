fx_version 'cerulean'
game 'gta5'

name 'lcv-blip'
description 'Synced DB-based blip manager (LyraCityV)'
author 'Jens & Lyra'

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/server.lua'
}

client_scripts {
    'client/client.lua'
}

client_exports {
    'GetBlips' -- optional für andere Ressourcen
}
