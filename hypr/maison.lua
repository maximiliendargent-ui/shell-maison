-- Réglages Hyprland propres à la session « Hyprland (Maison) ».
-- Chargé par ~/.config/hypr/hyprland.lua quand SHELL_MAISON est défini (~/.config/uwsm/env-maison),
-- après toute la config stable : ce fichier ne fait que la compléter ou la remplacer.

local bin = os.getenv("HOME") .. "/Projects/shell-maison/bin/"

-- Noctalia tourne encore (couleurs, fond d'écran, verrouillage…), avec sa config de session Maison
-- (noctalia/noctalia/zz-maison.toml : sans barre, notifications ni agent Polkit)
hl.on("hyprland.start", function ()
    hl.exec_cmd("qs -c shell-maison")
end)

-- Raccourcis du centre de contrôle et de la session : l'île au lieu des panneaux de Noctalia
local function rebind(key, cmd, description)
    pcall(hl.unbind, key)
    hl.bind(key, hl.dsp.exec_cmd(cmd), { description = description })
end
rebind("SUPER + N",        bin .. "island-open",           "Système: Centre de contrôle")
rebind("SUPER + CTRL + A", bin .. "island-open son",       "Système: Panneau son")
rebind("SUPER + CTRL + B", bin .. "island-open bluetooth", "Système: Panneau Bluetooth")
rebind("SUPER + CTRL + W", bin .. "island-open wifi",      "Système: Panneau réseau")
rebind("SUPER + Escape",   bin .. "island-open session",   "Système: Menu système (veille, redémarrage…)")

-- Touches son : wpctl au lieu de noctalia msg (l'OSD de Noctalia ne s'affiche que pour ses propres commandes,
-- Osd.qml réagit à tous les changements)
local function rebindLocked(key, cmd, repeating)
    pcall(hl.unbind, key)
    hl.bind(key, hl.dsp.exec_cmd(cmd), { locked = true, repeating = repeating })
end
rebindLocked("XF86AudioRaiseVolume", "wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+", true)
rebindLocked("XF86AudioLowerVolume", "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-", true)
rebindLocked("XF86AudioMute",        "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle")
rebindLocked("XF86AudioMicMute",     "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle")
pcall(hl.unbind, "SUPER + SHIFT + M")
hl.bind("SUPER + SHIFT + M", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),
    { locked = true, description = "Médias: Couper / rétablir le son" })

-- Notifications : celles de shell-maison (Notifs.qml) au lieu de celles de Noctalia
local notifs = "qs -c shell-maison ipc call notifs "
rebind("SUPER + Comma",               notifs .. "clear",                   "Notifications: Fermer les notifications")
rebind("SUPER + CTRL + Comma",        notifs .. "dnd",                     "Notifications: Ne pas déranger")
rebind("SUPER + ALT + Comma",         notifs .. "latest",                  "Notifications: Ouvrir la dernière notification")
rebind("SUPER + SHIFT + ALT + Comma", bin .. "island-open notifications", "Notifications: Historique")
