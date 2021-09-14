fx_version 'cerulean'
game 'gta5'

name "esx_publictransport"
description "Public transport AI"
author "Scorpion01"
version "0.1"

shared_scripts {
	'shared/*.lua'
}

client_scripts {
	'client/*.lua',
	'config.lua'
}

server_scripts {
	'server/*.lua',
	'config.lua'
}
