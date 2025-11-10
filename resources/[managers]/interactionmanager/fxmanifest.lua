fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'lcv-interactionmanager'
author 'LyraCityV'
description 'Central interaction routing (E key) and detectors'
version '0.1.0'

client_scripts {
  'client/interact.lua'
}

server_scripts {
  '@oxmysql/lib/MySQL.lua',
  'server/server.lua'
}

dependencies {
  'ox_lib'
}
shared_script '@ox_lib/init.lua'