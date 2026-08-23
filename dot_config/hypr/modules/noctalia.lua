-- Noctalia shell IPC binds (translated from noctalia.conf)

local ipc = "qs -c noctalia-shell ipc call"

-- Core binds
hl.bind("SUPER + SPACE",   hl.dsp.exec_cmd(ipc .. " launcher toggle"))
hl.bind("SUPER + S",        hl.dsp.exec_cmd(ipc .. " controlCenter toggle"))
hl.bind("SUPER + comma",    hl.dsp.exec_cmd(ipc .. " settings toggle"))
hl.bind("SUPER + Period",   hl.dsp.exec_cmd(ipc .. " settings toggle"))
hl.bind("SUPER + x",        hl.dsp.exec_cmd(ipc .. " sessionMenu toggle"))
hl.bind("SUPER + Semicolon", hl.dsp.exec_cmd(ipc .. " launcher emoji"))
hl.bind("SUPER + r",        hl.dsp.exec_cmd(ipc .. " launcher command"))
hl.bind("SUPER + v",        hl.dsp.exec_cmd(ipc .. " launcher clipboard"))

-- Media keys (locked + repeat while held)
hl.bind("XF86AudioRaiseVolume",    hl.dsp.exec_cmd(ipc .. " volume increase"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume",    hl.dsp.exec_cmd(ipc .. " volume decrease"), { locked = true, repeating = true })
hl.bind("XF86AudioMute",            hl.dsp.exec_cmd(ipc .. " volume muteOutput"), { locked = true })
hl.bind("XF86MonBrightnessUp",      hl.dsp.exec_cmd(ipc .. " brightness increase"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown",    hl.dsp.exec_cmd(ipc .. " brightness decrease"), { locked = true, repeating = true })

-- Sound (playback)
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd(ipc .. " media playPause"))
hl.bind("XF86AudioNext", hl.dsp.exec_cmd(ipc .. " media next"))
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd(ipc .. " media previous"))