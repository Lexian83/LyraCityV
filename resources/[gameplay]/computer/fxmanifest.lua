fx_version 'cerulean'
game 'gta5'
lua54 'yes'

ui_page 'client/html/index.html'

files {
    'client/html/*',
    'client/html/components/**',
    'client/html/utility/*',
    'client/html/icons/*',
}

shared_scripts {
    '@ox_lib/init.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/server.lua',                -- PC-Core
    -- 'server/faction/s-lspd.lua'      -- ALT: jetzt deaktiviert
}

client_scripts {
    'client/client.lua',
    'client/faction/c-lspd.lua'         -- LSPD-Bridge auf den Core
}
