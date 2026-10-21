-- Réglages Hyprland propres à la session « Hyprland (Maison) ».
-- Chargé par ~/.config/hypr/hyprland.lua quand SHELL_MAISON est défini (~/.config/uwsm/env-maison),
-- après toute la config stable : ce fichier ne fait que la compléter ou la remplacer.

local bin = os.getenv("HOME") .. "/Projects/shell-maison/bin/"

hl.on("hyprland.start", function ()
    -- Noctalia tourne encore (couleurs, notifications, verrouillage, Polkit…), mais sans sa barre :
    -- réessaie jusqu'à ce qu'il réponde (10 s max)
    hl.exec_cmd("sh -c 'for i in $(seq 50); do noctalia msg bar-hide >/dev/null 2>&1 && break; sleep 0.2; done'")
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
