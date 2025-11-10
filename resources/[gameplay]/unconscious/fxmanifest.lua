fx_version 'cerulean'
game 'gta5'

name 'LyraCityV_unconscious_respawn'
author 'Lyra & Jens'
version '1.0.0'
description 'unconscious system: 15-minute timer, auto-respawn at Pillbox, NUI countdown.'

ui_page 'html/index.html'

files {
  'html/index.html',
  'html/style.css',
  'html/app.js'
}

client_scripts {
  'c-unconscious.lua'
}

server_scripts {
  's-unconscious.lua'
}
