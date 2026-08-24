-- Hyprland Configuration (Lua)
-- https://wiki.hypr.land/Configuring/

-- ==================
-- MONITOR CONFIG
-- ==================
hl.monitor({
    output   = "DP-1",
    mode     = "2560x1440@360",
    position = "0x0",
    scale    = 1,
    bitdepth = 10,
})
hl.monitor({
    output   = "DP-2",
    mode     = "1920x1080@120",
    position = "2560x0",
    scale    = 1,
})
hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = "auto",
})

-- ==================
-- ENVIRONMENT
-- ==================
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")

-- ==================
-- STARTUP APPS
-- ==================
hl.on("hyprland.start", function()
    hl.exec_cmd("dbus-update-activation-environment --systemd --all")
    hl.exec_cmd("systemctl --user start hyprland-session.target")
    -- hl.exec_cmd("qs -c noctalia-shell &")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("hyprpaper &")
    hl.exec_cmd("variety &")
    hl.exec_cmd("kdeconnectd &")
    -- hl.exec_cmd("blueman-applet &")
    hl.exec_cmd("trayscale --hide-window &")
    hl.exec_cmd("vesktop &")
    hl.exec_cmd("steam -silent &")
    hl.exec_cmd("tidal-hifi &")
    hl.exec_cmd("syncthingtray-qt6 &")
    hl.exec_cmd("systemctl --user start hyprpolkitagent")
    hl.exec_cmd("flameshot &")
    -- hl.exec_cmd("handy --start-hidden &")
    hl.exec_cmd("noctalia")
    hl.exec_cmd("protonvpn-app")
end)

-- ==================
-- VARIABLES
-- ==================
local altMod       = "ALT"

-- ==================
-- INPUT CONFIG
-- ==================
hl.config({
    input = {
        kb_layout          = "us",
        numlock_by_default = true,
        kb_options         = "compose:ralt",
    },
})

-- ==================
-- GENERAL LAYOUT
-- ==================
hl.config({
    general = {
        gaps_in   = 5,
        gaps_out  = 5,
        border_size = 2,
        resize_on_border = false,
        allow_tearing = false,
        layout = "master",
    },
})

-- ==================
-- DECORATION
-- ==================
hl.config({
    decoration = {
        rounding = 12,
        active_opacity = 1.0,
        inactive_opacity = 1.0,
        shadow = {
            enabled = true,
            range = 30,
            render_power = 5,
            offset = { 0, 5 },
            color = "rgba(00000070)",
        },
    },
})

-- ==================
-- ANIMATIONS
-- ==================
hl.config({ animations = { enabled = true } })
hl.animation({ leaf = "windowsIn",  enabled = true, speed = 3, bezier = "default" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 3, bezier = "default" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 5, bezier = "default" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 4, bezier = "default" })
hl.animation({ leaf = "fade",       enabled = true, speed = 3, bezier = "default" })
hl.animation({ leaf = "border",     enabled = true, speed = 3, bezier = "default" })

-- ==================
-- LAYOUTS
-- ==================
hl.config({
    dwindle = { preserve_split = true },
    master  = { new_status = "master", mfact = 0.70 },
})

-- ==================
-- MISC
-- ==================
hl.config({
    misc = {
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        mouse_move_enables_dpms = true,
        key_press_enables_dpms = true,
    },
})

-- ==================
-- WINDOW RULES
-- ==================
hl.window_rule({ match = { class = "^org\\.wezfurlong\\.wezterm$" }, tile = true })

hl.window_rule({ match = { class = "^org\\.gnome\\." }, rounding = 12 })

hl.window_rule({ match = { class = "^gnome-control-center$" }, tile = true })
hl.window_rule({ match = { class = "^pavucontrol$" }, tile = true })
hl.window_rule({ match = { class = "^nm-connection-editor$" }, tile = true })

hl.window_rule({ match = { class = "^gnome-calculator$" }, float = true })
hl.window_rule({ match = { class = "^galculator$" }, float = true })
hl.window_rule({ match = { class = "^blueman-manager$" }, float = true })
hl.window_rule({ match = { class = "^xdg-desktop-portal$" }, float = true })

hl.window_rule({ match = { class = "^steam$", title = "^notificationtoasts" }, no_initial_focus = true })
hl.window_rule({ match = { class = "^steam$", title = "^notificationtoasts" }, pin = true })

hl.window_rule({ match = { title = "^Picture-in-Picture$" }, float = true })
hl.window_rule({ match = { class = "^zoom$" }, float = true })

hl.window_rule({ match = { class = "^it\\.mijorus\\.smile$", title = "^Smile$" }, float = true })
hl.window_rule({ match = { title = "^CopyQ$" }, float = true })

hl.window_rule({ match = { class = "^vesktop$" }, workspace = 6 })
hl.window_rule({ match = { class = "^tidal-hifi$" }, workspace = 7 })

hl.window_rule({ match = { class = "^flameshot$" }, float = true })
hl.window_rule({ match = { class = "^flameshot$" }, no_anim = true })
hl.window_rule({ match = { class = "^flameshot$" }, pin = true })
hl.window_rule({ match = { class = "^flameshot$" }, suppress_event = "maximize" })

hl.window_rule({ match = { class = ".*" }, idle_inhibit = "fullscreen" })

-- ==================
-- LAYER RULES
-- ==================
hl.layer_rule({
  name = "noctalia",
  match = { namespace = "^noctalia-(bar-.+|notification|dock|panel|attached-panel|osd|window-switcher)$" },
  no_anim = true,
  ignore_alpha = 0.5,
  blur = true,
  blur_popups = true,
})
hl.layer_rule({ match = { namespace = "^dms:.*" }, no_anim = true })

-- ==================
-- SOURCED MODULES
-- ==================
require("modules.smw")
require("modules.binds")
require("modules.noctalia")

-- For Noctalia Color templates
require("noctalia").apply_theme()
