fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'LyraCityV_auth'
author 'Jens'
version '0.0.2'
description 'LyraCityV – Auth & Character (funktional gekapselt, ohne externe SQL-Dateien)'


server_scripts {
  '@SQL/server/_bootstrap.lua',
  '@SQL/server/accounts.lua',
  '@SQL/server/characters.lua',
  'server/_bootstrap.lua',
  'server/auth.lua',
}

dependency 'logger'