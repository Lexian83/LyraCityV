fx_version 'cerulean'
game 'gta5'
lua54 'yes'

ui_page 'ui/index.html'

files {
    'ui/index.html',
    'ui/styles.css',
    'ui/app.js',
    'ui/assets/*.png',
    'ui/assets/*.svg',
    'ui/assets/*.webp'
}

client_scripts {
    'client.lua'
}

shared_scripts {
    '@ox_lib/init.lua'
}

server_scripts {
    '@SQL/server/_bootstrap.lua',
    '@SQL/server/characters.lua',
    'server.lua',
}

dependency 'playerManager'

