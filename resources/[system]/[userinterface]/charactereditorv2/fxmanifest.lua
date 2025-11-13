fx_version 'cerulean'
game 'gta5'
lua54 'yes'

ui_page 'client/html/index.html'

files {
    'client/html/*',
    'client/html/components/*',
    'client/html/utility/*',
    'client/html/faces/*',
    'client/html/icons/*',
}

shared_scripts {
    '@ox_lib/init.lua'
}

server_scripts {
    'server/startup.lua'
}

client_scripts {
    'client/editor.lua',
    'client/camera.lua'
}

dependencies {
    'playerManager',   -- ✅ wir speichern nur über den Manager
    'inputmanager',    -- UI open/close from your client/editor.lua
    'ox_lib'
}