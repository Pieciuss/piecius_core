fx_version 'cerulean'
game 'gta5'

author 'Piecius'
description 'Piecius Core - Vehicle blocking, keys, ID card, dispatch'
version '1.0.0'
lua54 'yes'

dependencies {
    'oxmysql',
    'Piecius_hud',
}

shared_scripts {
    'config.lua',
}

client_scripts {
    'bridge/client.lua',
    'client/main.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'bridge/server.lua',
    'server/main.lua',
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/index.js',
    'html/style.css',
}