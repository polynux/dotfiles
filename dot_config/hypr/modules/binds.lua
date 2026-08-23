-- Keybinds (translated from binds.conf)

local smw = require("modules.smw")
local mainMod = "SUPER"

-- === Window Management ===
hl.bind(mainMod .. " + Q", hl.dsp.window.kill())
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }))
hl.bind(mainMod .. " + SHIFT + F", hl.dsp.window.fullscreen({ action = "toggle" }))
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
-- focuswindow,first has no documented Lua "first" selector; use a helper
-- that focuses the first window returned by hl.get_windows().
local function focus_window_by_index(idx)
    return function()
        local wins = hl.get_windows()
        if wins and wins[idx] then
            hl.dispatch(hl.dsp.focus({ window = "address:" .. wins[idx].address }))
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

-- === Numbered Workspaces (absolute IDs 1-9, matching legacy behavior) ===
-- The smw plugin splits workspace IDs across monitors (1-5 on DP-1, 6-10 on
-- DP-2) but focuses them by absolute ID, not per-monitor index.
for i = 1, 9 do
    local n = tostring(i)
    hl.bind(mainMod .. " + " .. n,         hl.dsp.focus({ workspace = n }))
    hl.bind(mainMod .. " + SHIFT + " .. n, hl.dsp.window.move({ workspace = n, follow = false }))
end

-- === Move/resize windows with mainMod + LMB/RMB and dragging ===
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- === Click-drag resize on keys (legacy: bindd = SUPER, code:20, ..., resizeactive, -100 0) ===
hl.bind(mainMod .. " + code:20", hl.dsp.window.resize({ x = -100, y = 0, relative = true }), { mouse = true, drag = true })
hl.bind(mainMod .. " + code:21", hl.dsp.window.resize({ x =  100, y = 0, relative = true }), { mouse = true, drag = true })

-- === Manual Sizing (repeat while held; legacy used 10% of window size) ===
local function resize_percent(dx_pct, dy_pct)
    return function()
        local win = hl.get_active_window()
        if not win or not win.size then return end
        local s = win.size
        local w, h = s.x, s.y
        if not w or not h then return end
        hl.dispatch(hl.dsp.window.resize({
            x = math.floor(w * dx_pct),
            y = math.floor(h * dy_pct),
            relative = true,
        }))
    end
end
hl.bind(mainMod .. " + minus",        resize_percent(-0.10, 0),     { repeating = true })
hl.bind(mainMod .. " + equal",         resize_percent( 0.10, 0),     { repeating = true })
hl.bind(mainMod .. " + SHIFT + minus", resize_percent(0, -0.10),     { repeating = true })
hl.bind(mainMod .. " + SHIFT + equal", resize_percent(0,  0.10),     { repeating = true })