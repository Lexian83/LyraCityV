fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'LyraCityV_worldsync'
author 'Lyra & Jens'
version '0.2.0'
description 'LyraCityV – split realtime & weather resources (client/server), hard-locked server-time clock + synced weather'

server_scripts {
  's-realtime.lua',
  's-weather.lua'
}

client_scripts {
  'c-realtime.lua',
  'c-weather.lua'
}
