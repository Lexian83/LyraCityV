fx_version 'cerulean'
game 'gta5'

name 'blipmanger'
description 'Synced DB-based blip manager (LyraCityV)'
author 'Jens & Lyra'

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/server.lua',
    'server/exports.lua'
}

client_scripts {
    'client/client.lua'
}

client_exports {
    'GetBlips' -- optional für andere Ressourcen
}

-- Server-seitige Exports (von server/exports.lua)
server_exports {
    'GetAll',
    'Add',
    'Update',
    'Delete'
}