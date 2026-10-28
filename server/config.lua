-- Copyright (C) 2026 enty@pocus.software. LGPL-3.0-or-later, see LICENSE.

return {
    -- minimum ms between two reports for the same resource (and the same player, for client errors)
    cooldown = 1000,

    -- ms to wait for the runtime to print the stack after a server "SCRIPT ERROR" line
    stackWait = 50,

    -- stack traces are cut to this many characters
    maxTraceLength = 2000,

    -- print client errors to the server console
    logClientErrors = true,

    -- resources whose errors are never reported, e.g. { ['noisy_resource'] = true }
    ignoreResources = {},
}
