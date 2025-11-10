fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'logger'
author 'Lyra & Jens'
version '1.0.0'
description 'Lyra City V | Connection + Death Logger + Cleanup'

server_scripts {
  '@oxmysql/lib/MySQL.lua',
  'shared/config.lua',

  'server/cleanup.lua',

  'server/logger.lua',
  'server/connection_logger.lua',
  'server/death_logger.lua',
}

client_scripts {
'client/death_watch.lua'
}


-- Abhängigkeiten (sorgt dafür, dass die vorher gestartet werden)
dependency 'oxmysql'
dependency 'baseevents'
dependency 'playerManager'
