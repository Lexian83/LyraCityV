fx_version 'cerulean'
game 'gta5'

name 'lcv-npc'
description 'Synced NPC spawner + anim control (LyraCityV)'
author 'Jens & Lyra'

server_scripts {
  'server/server.lua',
  '@oxmysql/lib/MySQL.lua'
}

client_scripts {
  'client/client.lua'
}
client_exports {
  'GetNPCPositions'
}

