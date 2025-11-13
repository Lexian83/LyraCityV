fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'interactionmanager'
author 'LyraCityV'
description 'Central interaction routing (E key) and detectors'
version '0.1.0'

shared_script '@ox_lib/init.lua'

client_scripts {
  'client/interact.lua'
}

server_scripts {
  '@oxmysql/lib/MySQL.lua',
  'server/server.lua',
  'server/exports.lua'
}

server_exports {
  'GetAll',
  'Add',
  'Update',
  'Delete'
}

dependencies {
  'ox_lib'
}

