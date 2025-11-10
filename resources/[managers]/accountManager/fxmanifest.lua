fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'accountManager'
author 'Lyra & Jens'
version '1.0.0'
description 'LyraCityV - Account Management Wrapper'

server_scripts {
    '@SQL/server/_bootstrap.lua',
    '@SQL/server/accounts.lua',
    'server/accountManager.lua',
}

dependency 'SQL'
