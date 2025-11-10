fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'auth'
author 'Jens'
version '0.0.3'
description 'LyraCityV – Auth Gateway (Discord + Account-Bindung)'

server_scripts {
    '@SQL/server/_bootstrap.lua',
    'server/_bootstrap.lua',
    'server/auth.lua',
}

dependency 'SQL'
dependency 'accountManager'
dependency 'playerManager'
