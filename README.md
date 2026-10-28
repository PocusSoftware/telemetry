# telemetry

Script error telemetry for FiveM & RedM. It catches Lua errors on the server and on
clients, rate limits them, and hands them to your code through one event and
an optional Discord webhook.

RedM is Untested in a live server so far. Read the limits below before relying on it.

## Install

1. Put the folder in `resources/` and `ensure telemetry` **before** the
   resources you want to watch.
2. Server errors need nothing else. The server reads the console channel of
   every resource (`script:<resource>`).
3. For client errors, add the hook as the **first** client script of each
   resource you want to watch:

```lua
client_scripts {
    '@telemetry/client/hook.lua',
    'client.lua',
}
```

The hook needs Lua 5.4 in the watched resource (`lua54 'yes'`).

## Receive errors

A local server event fires for every error:

```lua
AddEventHandler('telemetry:error', function(entry)
    -- entry.side      'client' | 'server'
    -- entry.resource  string
    -- entry.trace     string
    -- entry.source    integer, client errors only
end)
```

The event is not networked, so clients cannot trigger it.

## Discord webhook

Set the URL in `server.cfg` with `set`, never `setr` (`setr` replicates the
value to every client):

```
set telemetry:webhook "https://discord.com/api/webhooks/..."
```

Messages are sent with mentions disabled. Discord rate limits webhooks and
failed sends are dropped silently.

## Config

See [server/config.lua](server/config.lua): cooldown, stack wait, trace length, console
logging for client errors, and an ignore list.

## Limits

- `entry.resource` on client errors is reported by the client. It is checked
  against real resource names, but a cheater can still blame another
  resource. `entry.source` is trustworthy.
- Reports are throttled per resource (and per player for clients), so a
  second error inside the cooldown is dropped.
- The hook wraps `AddEventHandler`, `RegisterNetEvent`, `RegisterCommand`,
  `CreateThread` and `SetTimeout`, and only for code registered after it
  loads. Errors in NUI callbacks, state bag handlers, exports or
  `Citizen.SetTimeout` are not caught client side.
- Wrapped handlers swallow the error after reporting it, instead of passing
  it to the runtime.
- The server stack is stitched from console lines with a short wait
  (`stackWait`). A very slow console can cut a trace.

## License

LGPL-3.0-or-later, see [LICENSE](LICENSE).
