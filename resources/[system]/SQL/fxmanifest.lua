fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'Lyra City V_auth'
author 'Jens'
version '0.0.2'
description 'Lyra City V – Auth & Character (funktional gekapselt, ohne externe SQL-Dateien)'


server_scripts {
  '@log/server/logger.lua',
  'server/_bootstrap.lua',
  'server/accounts.lua',
  'server/characters.lua',
}

dependency 'logger'
