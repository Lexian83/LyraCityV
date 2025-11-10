fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'playerManager'
author 'Lyra & Jens'
version '1.1.0'
description 'LyraCityV - Player Session & Character Management'

server_scripts {
    '@SQL/server/_bootstrap.lua',
    '@SQL/server/characters.lua',
    'server/playerManager.lua',
}

server_exports {
    'GetSession',
    'GetAccountId',
    'GetActiveCharacterId',
    'GetPlayerData',
    'BindAccount',
}

dependency 'SQL'
