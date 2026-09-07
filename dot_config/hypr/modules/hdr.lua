-- HDR handling for the primary monitor (SUPER + D)
--
-- Full-time `cm = "hdr"` was tested and abandoned: on NVIDIA + OLED,
-- SDR content rendered in the HDR pipeline shows lifted (grey) blacks
-- in GPU-accelerated apps (terminals), unaffected by sdr_min_luminance,
-- min_luminance, or EOTF settings. Upstream: hyprwm/Hyprland discussions
-- #10264, issue #15195.
--
-- Instead the monitor stays srgb; render:cm_auto_hdr (on by default)
-- switches fullscreen HDR content to HDR automatically.

local MONITOR = "DP-1"

local function notify_hdr(on)
    hl.notification.create({
        text    = MONITOR .. ": HDR " .. (on and "on" or "off"),
        timeout = 1500,
        color   = on and "rgb(2ce8a2)" or "rgb(8b8b9a)",
    })
end

-- Manual toggle kept for cases where auto HDR doesn't engage.
-- Re-applies the monitor with live values; only cm changes.
hl.bind("SUPER + D", function()
    local m = hl.get_monitor(MONITOR)
    if not m then return end
    local on = m.cm ~= "hdr"
    hl.monitor({
        output   = MONITOR,
        mode     = string.format("%dx%d@%d", m.width, m.height, math.floor(m.refresh_rate + 0.5)),
        position = m.x .. "x" .. m.y,
        scale    = m.scale,
        bitdepth = 10,
        cm       = on and "hdr" or "srgb",
    })
    notify_hdr(on)
end)