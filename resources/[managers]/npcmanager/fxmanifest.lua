fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'npcmanager'
description 'Synced NPC spawner + anim control (LyraCityV)'
author 'Jens & Lyra'

server_scripts {
  '@oxmysql/lib/MySQL.lua',   -- oxmysql zuerst laden
  'server/server.lua'
}

client_scripts {
  'client/client.lua'
}

client_exports {
  'GetNPCPositions'
}

server_exports {
  -- Admin/SSOT
  'Admin_NPCs_GetAll',
  'Admin_NPCs_Add',
  'Admin_NPCs_Update',
  'Admin_NPCs_Delete'
}

dependencies {
  'oxmysql'
}
