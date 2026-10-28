fx_version 'cerulean'
game 'common'
lua54 'yes'

name 'telemetry'
author 'enty@pocus.software'
version '0.1.0'
license 'LGPL-3.0-or-later'
description 'Script error telemetry for FiveM & RedM. Catches server and client Lua errors and forwards them to an event and an optional Discord webhook.'

files { 'client/hook.lua' }

server_scripts { 'server/main.lua' }
