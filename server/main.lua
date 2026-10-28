-- Copyright (C) 2026 enty@pocus.software. LGPL-3.0-or-later, see LICENSE.

local RESOURCE <const> = GetCurrentResourceName()
local CLIENT_EVENT <const> = 'telemetry:clientError'
local ERROR_EVENT <const> = 'telemetry:error'
local WEBHOOK_CONVAR <const> = 'telemetry:webhook'
local ERROR_MARK <const> = 'SCRIPT ERROR'
local CLIENT_TAG <const> = '[client error]'
local SCRIPT_CHANNEL <const> = '^script:([^:]+)$' -- script:<resource>:warning is skipped
local MAX_RESOURCE_LENGTH <const> = 64
local DISCORD_LIMIT <const> = 1900
local FENCE_OVERHEAD <const> = 10

---@class TelemetryConfig
---@field cooldown integer ms
---@field stackWait integer ms
---@field maxTraceLength integer
---@field logClientErrors boolean
---@field ignoreResources table<string, boolean>

---@class TelemetryError
---@field side 'client'|'server'
---@field resource string
---@field trace string
---@field source? integer player id, client errors only. `resource` is client reported, `source` is not.

---@type TelemetryConfig
local DEFAULTS <const> = {
    cooldown = 1000,
    stackWait = 50,
    maxTraceLength = 2000,
    logClientErrors = true,
    ignoreResources = {},
}

---@return TelemetryConfig
local function loadConfig()
    local raw <const> = LoadResourceFile(RESOURCE, 'server/config.lua')
    local chunk <const>, loadErr = load(raw or '', ('@%s/server/config.lua'):format(RESOURCE))
    if not chunk then
        Citizen.Trace(('^1[telemetry] config.lua failed to load, using defaults: %s^7\n'):format(loadErr))
        return DEFAULTS
    end

    local ok, loaded = pcall(chunk)
    if not ok or type(loaded) ~= 'table' then
        Citizen.Trace('^1[telemetry] config.lua must return a table, using defaults^7\n')
        return DEFAULTS
    end

    return setmetatable(loaded, { __index = DEFAULTS })
end

local config <const> = loadConfig()

local clientSeen = {} ---@type table<integer, table<string, integer>>
local serverSeen = {} ---@type table<string, integer>

---@param seen table<string, integer>
---@param key string
---@return boolean
local function isThrottled(seen, key)
    local now <const> = GetGameTimer()
    if now - (seen[key] or -config.cooldown) < config.cooldown then return true end
    seen[key] = now
    return false
end

---@param entry TelemetryError
local function sendWebhook(entry)
    local url <const> = GetConvar(WEBHOOK_CONVAR, '')
    if not url:find('^https://') then return end

    local who = 'server'
    if entry.source then
        who = ('%s (%d)'):format(GetPlayerName(entry.source) or 'unknown', entry.source)
    end

    local header <const> = ('**%s error** in `%s` | %s\n'):format(entry.side, entry.resource, who)
    local trace <const> = entry.trace:gsub('```', "'''")
    local room <const> = DISCORD_LIMIT - #header - FENCE_OVERHEAD

    PerformHttpRequest(url, function() end, 'POST', json.encode({
        content = ('%s```\n%s\n```'):format(header, trace:sub(1, room)),
        allowed_mentions = { parse = {} },
    }), { ['Content-Type'] = 'application/json' })
end

---@param entry TelemetryError
local function emit(entry)
    TriggerEvent(ERROR_EVENT, entry)
    sendWebhook(entry)
end

RegisterNetEvent(CLIENT_EVENT, function(payload)
    if GetInvokingResource() then return end
    local src <const> = source

    if type(payload) ~= 'table' then return end
    if type(payload.resource) ~= 'string' or type(payload.trace) ~= 'string' then return end

    local resource <const> = payload.resource:sub(1, MAX_RESOURCE_LENGTH)
    if GetResourceState(resource) == 'missing' or config.ignoreResources[resource] then return end

    local seen = clientSeen[src]
    if not seen then
        seen = {}
        clientSeen[src] = seen
    end
    if isThrottled(seen, resource) then return end

    local trace <const> = payload.trace:sub(1, config.maxTraceLength):gsub('%^%d', '')

    if config.logClientErrors then
        Citizen.Trace(('^1%s %s (%d) in %s^7\n%s\n'):format(CLIENT_TAG, GetPlayerName(src) or 'unknown', src, resource, trace))
    end
    emit({ side = 'client', source = src, resource = resource, trace = trace })
end)

AddEventHandler('playerDropped', function()
    clientSeen[source] = nil
end)

---@type { resource: string, text: string }?
local pending

local function flush()
    local entry <const> = pending
    if not entry then return end
    pending = nil

    if config.ignoreResources[entry.resource] or isThrottled(serverSeen, entry.resource) then return end
    emit({ side = 'server', resource = entry.resource, trace = entry.text:sub(1, config.maxTraceLength) })
end

RegisterConsoleListener(function(channel, message)
    local resource <const> = channel:match(SCRIPT_CHANNEL)
    if not resource then return end

    local text <const> = message:gsub('%^%d', '')
    if text:find(CLIENT_TAG, 1, true) then return end

    if text:find(ERROR_MARK, 1, true) then
        flush()
        pending = { resource = resource, text = text }
        SetTimeout(config.stackWait, flush)
    elseif pending and pending.resource == resource and (text:find('^%s*>') or text:find('^stack traceback')) then
        pending.text = pending.text .. text
    end
end)
