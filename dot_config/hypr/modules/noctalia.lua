-- Noctalia shell IPC binds (v5)

local ipc = "noctalia msg "

-- Core binds
hl.bind("SUPER + SPACE",     hl.dsp.exec_cmd(ipc .. "panel-toggle launcher"))
hl.bind("SUPER + S",         hl.dsp.exec_cmd(ipc .. "panel-toggle control-center"))
hl.bind("SUPER + comma",     hl.dsp.exec_cmd(ipc .. "settings-toggle"))
hl.bind("SUPER + Period",    hl.dsp.exec_cmd(ipc .. "settings-toggle"))
hl.bind("SUPER + x",         hl.dsp.exec_cmd(ipc .. "panel-toggle session"))
hl.bind("SUPER + Semicolon", hl.dsp.exec_cmd(ipc .. 'panel-toggle launcher "/emo "'))
hl.bind("SUPER + r",         hl.dsp.exec_cmd(ipc .. 'panel-toggle launcher "/command"'))
hl.bind("SUPER + v",         hl.dsp.exec_cmd(ipc .. "panel-toggle clipboard"))

-- Media keys (locked + repeat while held)
hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd(ipc .. "volume-up"),   { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd(ipc .. "volume-down"), { locked = true, repeating = true })
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd(ipc .. "volume-mute"), { locked = true })
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd(ipc .. "brightness-up"),   { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd(ipc .. "brightness-down"), { locked = true, repeating = true })

-- Media playback
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd(ipc .. "media toggle"))
hl.bind("XF86AudioNext", hl.dsp.exec_cmd(ipc .. "media next"))
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd(ipc .. "media previous"))
