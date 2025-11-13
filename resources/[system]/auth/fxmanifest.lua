fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'auth'
author 'Jens'
version '0.0.4'
description 'LyraCityV – Auth Gateway (Discord + Account-Bindung)'

server_scripts {
  'server/_bootstrap.lua',
  'server/auth.lua',
}

dependencies {
  'accountManager',
  'playerManager'
}
