-- HDR toggle for the primary monitor (SUPER + D)

local MONITOR        = "DP-1"
local SDR_BRIGHTNESS = 1.15

local function notify_hdr(on)
    hl.notification.create({
        text    = MONITOR .. ": HDR " .. (on and "on" or "off"),
        timeout = 1500,
        color   = on and "rgb(2ce8a2)" or "rgb(8b8b9a)",
    })
end

-- Re-apply the monitor with live values; only cm/sdrbrightness change
local function apply_monitor(cm)
    local m = hl.get_monitor(MONITOR)
    if not m then return end
    local spec = {
        output   = MONITOR,
        mode     = string.format("%dx%d@%d", m.width, m.height, math.floor(m.refresh_rate + 0.5)),
        position = m.x .. "x" .. m.y,
        scale    = m.scale,
        bitdepth = 10,
        cm       = cm,
    }
    spec.sdrbrightness = on and SDR_BRIGHTNESS or 1.0
    hl.monitor(spec)
end

hl.bind("SUPER + D", function()
    local m = hl.get_monitor(MONITOR)
    if not m then return end
    local on = m.cm ~= "hdr"
    apply_monitor(on and "hdr" or "srgb")
    notify_hdr(on)
end)