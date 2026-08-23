-- split-monitor-workspaces: awesome/dwm-like per-monitor workspace splitting.
-- Replaces the legacy C++ hyprpm plugin with the Lua package from
-- https://github.com/zjeffer/split-monitor-workspaces (release/0.56.x).

package.path = package.path
    .. ";/home/polynux/.config/hypr/plugins/split-monitor-workspaces/lua/?.lua"

local smw = require("split-monitor-workspaces")

smw.setup({
    workspace_count              = 5,
    keep_focused                 = false,  -- legacy 0
    enable_notifications         = false,  -- legacy 0
    enable_persistent_workspaces = true,   -- legacy 1
    monitor_priority             = { "DP-1", "DP-2" },
})

-- Expose smw to other modules (binds.lua uses it for workspace dispatchers).
return smw