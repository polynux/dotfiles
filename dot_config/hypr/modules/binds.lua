-- Keybinds (translated from binds.conf)

local smw = require("modules.smw")
local mainMod = "SUPER"

-- === Window Management ===
hl.bind(mainMod .. " + Q", hl.dsp.window.kill())
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ action = "set" }))
hl.bind(mainMod .. " + SHIFT + F", hl.dsp.window.fullscreen({ action = "unset" }))
hl.bind(mainMod .. " + SHIFT + T", hl.dsp.window.float())
hl.bind(mainMod .. " + W", hl.dsp.group.toggle())
hl.bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd("dms ipc call window-rules toggle"))

-- === Focus Navigation ===
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "l" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "d" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "u" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "r" }))
hl.bind(mainMod .. " + H", hl.dsp.focus({ direction = "l" }))
hl.bind(mainMod .. " + J", hl.dsp.focus({ direction = "d" }))
hl.bind(mainMod .. " + K", hl.dsp.focus({ direction = "u" }))
hl.bind(mainMod .. " + L", hl.dsp.focus({ direction = "r" }))

-- === Window Movement ===
hl.bind(mainMod .. " + SHIFT + left",  hl.dsp.window.move({ direction = "l" }))
hl.bind(mainMod .. " + SHIFT + down",  hl.dsp.window.move({ direction = "d" }))
hl.bind(mainMod .. " + SHIFT + up",    hl.dsp.window.move({ direction = "u" }))
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.move({ direction = "r" }))
hl.bind(mainMod .. " + SHIFT + H", hl.dsp.window.move({ direction = "l" }))
hl.bind(mainMod .. " + SHIFT + J", hl.dsp.window.move({ direction = "d" }))
hl.bind(mainMod .. " + SHIFT + K", hl.dsp.window.move({ direction = "u" }))
hl.bind(mainMod .. " + SHIFT + L", hl.dsp.window.move({ direction = "r" }))

-- === Column Navigation ===
-- focuswindow,first has no documented Lua "first" selector; use a helper.
local function focus_window_by_index(idx)
    return function()
        local wins = hl.get_windows()
        if wins and wins[idx] then
            hl.dispatch(hl.dsp.focus({ window = "address:0x" .. string.format("%x", wins[idx].address) }))
        end
    end
end
hl.bind(mainMod .. " + Home", focus_window_by_index(1))
hl.bind(mainMod .. " + End",  hl.dsp.focus({ last = true }))

-- === Monitor Navigation ===
hl.bind(mainMod .. " + CTRL + left",  hl.dsp.focus({ monitor = "l" }))
hl.bind(mainMod .. " + CTRL + right", hl.dsp.focus({ monitor = "r" }))
hl.bind(mainMod .. " + CTRL + H", hl.dsp.focus({ monitor = "l" }))
hl.bind(mainMod .. " + CTRL + J", hl.dsp.focus({ monitor = "d" }))
hl.bind(mainMod .. " + CTRL + K", hl.dsp.focus({ monitor = "u" }))
hl.bind(mainMod .. " + CTRL + L", hl.dsp.focus({ monitor = "r" }))

-- === Move to Monitor ===
hl.bind(mainMod .. " + SHIFT + CTRL + left",  hl.dsp.window.move({ monitor = "l" }))
hl.bind(mainMod .. " + SHIFT + CTRL + down",  hl.dsp.window.move({ monitor = "d" }))
hl.bind(mainMod .. " + SHIFT + CTRL + up",    hl.dsp.window.move({ monitor = "u" }))
hl.bind(mainMod .. " + SHIFT + CTRL + right", hl.dsp.window.move({ monitor = "r" }))
hl.bind(mainMod .. " + SHIFT + CTRL + H", hl.dsp.window.move({ monitor = "l" }))
hl.bind(mainMod .. " + SHIFT + CTRL + J", hl.dsp.window.move({ monitor = "d" }))
hl.bind(mainMod .. " + SHIFT + CTRL + K", hl.dsp.window.move({ monitor = "u" }))
hl.bind(mainMod .. " + SHIFT + CTRL + L", hl.dsp.window.move({ monitor = "r" }))

-- === Workspace Navigation (relative) ===
hl.bind(mainMod .. " + Page_Down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + Page_Up",   hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mainMod .. " + U", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + I", hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mainMod .. " + CTRL + down", hl.dsp.window.move({ workspace = "e+1" }))
hl.bind(mainMod .. " + CTRL + up",   hl.dsp.window.move({ workspace = "e-1" }))
hl.bind(mainMod .. " + CTRL + U", hl.dsp.window.move({ workspace = "e+1" }))
hl.bind(mainMod .. " + CTRL + I", hl.dsp.window.move({ workspace = "e-1" }))

-- === Numbered Workspaces (via split-monitor-workspaces) ===
for i = 1, smw.get_amount_of_workspaces() do
    local n = tostring(i)
    hl.bind(mainMod .. " + " .. n,         smw.workspace(n))
    hl.bind(mainMod .. " + SHIFT + " .. n, smw.move_to_workspace_silent(n))
end

-- === Move/resize windows with mainMod + LMB/RMB and dragging ===
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true, drag = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true, drag = true })

-- === Click-drag resize on keys (legacy: bindd = SUPER, code:20, ..., resizeactive, -100 0) ===
hl.bind(mainMod .. " + code:20", hl.dsp.window.resize({ x = -100, y = 0, relative = true }), { mouse = true, click = true })
hl.bind(mainMod .. " + code:21", hl.dsp.window.resize({ x =  100, y = 0, relative = true }), { mouse = true, click = true })

-- === Manual Sizing (repeat while held) ===
hl.bind(mainMod .. " + minus",        hl.dsp.window.resize({ x = -10, y = 0,  relative = true }), { repeating = true })
hl.bind(mainMod .. " + equal",         hl.dsp.window.resize({ x =  10, y = 0,  relative = true }), { repeating = true })
hl.bind(mainMod .. " + SHIFT + minus", hl.dsp.window.resize({ x = 0, y = -10, relative = true }), { repeating = true })
hl.bind(mainMod .. " + SHIFT + equal", hl.dsp.window.resize({ x = 0, y =  10, relative = true }), { repeating = true })