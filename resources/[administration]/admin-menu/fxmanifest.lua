fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'lyracityv-adminmenu'
author 'Lyra & Jens'
version '1.0.1-hardened'
description 'Lyra City V | Admin Menu (F12) – hardened & reviewed'

shared_scripts {
    '@ox_lib/init.lua',
	  'shared/permissions.lua'
}

client_scripts {
    'client/client.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/labels.lua',
    'server/server.lua'
}

dependency 'playerManager'
