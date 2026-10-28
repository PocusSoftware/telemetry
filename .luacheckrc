std = 'lua54'
max_line_length = false

files['client/hook.lua'] = {
    globals = { '_G.AddEventHandler', '_G.RegisterNetEvent', '_G.RegisterCommand', '_G.CreateThread', '_G.SetTimeout', 'Citizen.CreateThread' },
}

read_globals = {
    'Citizen', 'json', 'source',
    'AddEventHandler', 'RegisterNetEvent', 'RegisterCommand', 'CreateThread', 'SetTimeout',
    'GetCurrentResourceName', 'GetGameTimer', 'GetInvokingResource', 'GetResourceState',
    'GetPlayerName', 'GetConvar', 'LoadResourceFile', 'PerformHttpRequest',
    'TriggerEvent', 'TriggerServerEvent', 'RegisterConsoleListener',
}
exclude_files = { 'fxmanifest.lua' }
