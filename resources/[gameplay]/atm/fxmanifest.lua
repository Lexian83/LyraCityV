fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'atm'
author 'LyraCityV'
description 'Simple ATM base with ox_lib UI'
version '0.1.0'

ui_page 'client/html/index.html'

files {
  'client/html/index.html',
  'client/html/styles.css',
  'client/html/app.js',
  'client/html/components/*.js'
}


shared_script '@ox_lib/init.lua'


client_scripts {
  'client/atm_nui.lua'
}

server_scripts {
  '@oxmysql/lib/MySQL.lua',
  'server/atm_statement.lua',
  'server/atm.lua'
}



dependencies {
  'ox_lib',
  'oxmysql',
  'playerManager'
}