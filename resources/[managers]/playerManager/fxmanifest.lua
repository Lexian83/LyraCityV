fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'playerManager'
author 'Lyra & Jens'
version '1.1.0'
description 'LyraCityV - Player Session & Character Management'

client_scripts {
  'client/spawn.lua',        -- ✅ integrierter Spawn-Client
}


server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/playerManager.lua',
}

-- Vorhandene + neue Admin-Exports
server_exports {
    -- Sessions / Data
    'GetSession',
    'GetAccountId',
    'GetActiveCharacterId',
    'GetPlayerData',
    'BindAccount',
    'SaveCharacter',
    'CreateCharacter',
    'DeleteCharacter',
    'RenameCharacter',

    -- Admin-CRUD für Characters
    'ListCharacters',
    'UpdateCharacterFlags',
    'DeleteCharacterById'
}


dependency 'SQL'
