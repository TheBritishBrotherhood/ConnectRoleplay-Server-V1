resource_manifest_version '44febabe-d386-4d18-afbe-5e627f4af937'


ui_page 'html/index.html'
files {
	'html/index.html',
	'html/script.js',
	'html/style.css'
} 

server_scripts {
	'config.lua',
	'server/main.lua'
}

client_scripts {
	'config.lua',
	'client/ui.lua',
	'client/main.lua'
}

