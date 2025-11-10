fx_version 'cerulean'
game 'gta5'
lua54 'yes'
name 'Manager:Player'
author 'Lyra & Jens'
version '1.0.0'
description 'Holding Playerdata'


server_scripts {
  'server/player.lua',
}

server_exports {
  'GetPlayerData'
}

-- Optional Exports, damit andere Ressourcen den Status abfragen können
 -- export 'UI_IsOpen'