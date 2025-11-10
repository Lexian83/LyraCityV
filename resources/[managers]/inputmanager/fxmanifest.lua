fx_version 'cerulean'
game 'gta5'
lua54 'yes'
name 'Manager'
author 'Lyra & Jens'
version '1.0.0'
description 'Player Spawn Script'


client_scripts {
  'client/ui.lua',
  'client/keys.lua'
}

-- Optional Exports, damit andere Ressourcen den Status abfragen können
export 'UI_IsOpen'
export 'UI_Current'
export 'UI_AnyOpen'
export 'LCV_OpenUI'
export 'LCV_CloseUI'