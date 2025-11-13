fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'accountManager'
author 'Lyra & Jens'
version '1.0.0'
description 'LyraCityV - Account Management Wrapper'

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/accountManager.lua',
}

server_exports {
    'EnsureAccountByDiscord',
    'GetAccountByDiscord',
    'UpdateLastLogin'
}

dependencies {
    'oxmysql'
}
