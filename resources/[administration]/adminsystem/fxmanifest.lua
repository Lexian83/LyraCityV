fx_version 'cerulean'
game 'gta5'
lua54 'yes'

ui_page 'client/html/index.html'

files {
    'client/html/*',
    'client/html/components/*',
    'client/html/utility/*',
    'client/html/icons/*',
}

shared_scripts {
    '@ox_lib/init.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/server.lua'
}

client_scripts {
    'client/client.lua',
}
